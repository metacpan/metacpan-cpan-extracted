# LICENSE: You're free to distribute this under the same terms as Perl itself.

use strict;
use Carp ();

############################################################################
package Net::OpenID::Consumer;
$Net::OpenID::Consumer::VERSION = '1.18';
use fields (
    'cache',           # Cache object to store HTTP responses,
                       #   associations, and nonces
    'ua',              # LWP::UserAgent instance to use
    'args',            # how to get at your args
    'message',         # args interpreted as an IndirectMessage, if possible
    'consumer_secret', # scalar/subref
    'required_root',   # the default required_root value, or undef
    'last_errcode',    # last error code we got
    'last_errtext',    # last error code we got
    'debug',           # debug flag or codeblock
    'minimum_version', # The minimum protocol version to support
    'assoc_options',   # options for establishing ID provider associations
    'nonce_options',   # options for dealing with nonces
);

use Net::OpenID::ClaimedIdentity;
use Net::OpenID::VerifiedIdentity;
use Net::OpenID::Association;
use Net::OpenID::Yadis;
use Net::OpenID::IndirectMessage;
use Net::OpenID::URIFetch;
use Net::OpenID::Common; # To get the OpenID::util package

use MIME::Base64 ();
use Digest::SHA qw(hmac_sha1_hex);
use Time::Local;
use HTTP::Request;
use LWP::UserAgent;
use Storable;
use JSON qw(encode_json);
use URI::Escape qw(uri_escape_utf8);
use HTML::Parser;

sub new {
    my Net::OpenID::Consumer $self = shift;
    $self = fields::new( $self ) unless ref $self;
    my %opts = @_;

    $self->{ua}            = delete $opts{ua};
    $self->args            ( delete $opts{args}            );
    $self->cache           ( delete $opts{cache}           );
    $self->consumer_secret ( delete $opts{consumer_secret} );
    $self->required_root   ( delete $opts{required_root}   );
    $self->minimum_version ( delete $opts{minimum_version} );
    $self->assoc_options   ( delete $opts{assoc_options}   );
    $self->nonce_options   ( delete $opts{nonce_options}   );

    $self->{debug} = delete $opts{debug};

    Carp::croak("Unknown options: " . join(", ", keys %opts)) if %opts;
    return $self;
}

# NOTE: This method is here only to support the openid-test library.
# Don't call it from anywhere else, or you'll break when it gets
# removed. Instead, call minimum_version(2).
# FIXME: Can we just make openid-test do that and get rid of this?
sub disable_version_1 {
    $_[0]->minimum_version(2);
}

sub cache           { &_getset; }
sub consumer_secret { &_getset; }
sub required_root   { &_getset; }
sub assoc_options   { &_hashgetset }
sub nonce_options   { &_hashgetset }

sub _getset {
    my Net::OpenID::Consumer $self = shift;
    my $param = (caller(1))[3];
    $param =~ s/.+:://;

    if (@_) {
        my $val = shift;
        Carp::croak("Too many parameters") if @_;
        $self->{$param} = $val;
    }
    return $self->{$param};
}

sub _hashgetset {
    my Net::OpenID::Consumer $self = shift;
    my $param = (caller(1))[3];
    $param =~ s/.+:://;
    my $check_param = "_canonicalize_$param";

    my $v;
    if (scalar(@_) == 1) {
        $v = shift;
        unless ($v) {
            $v = {};
        }
        elsif (ref $v eq 'ARRAY') {
            $v = {@$v};
        }
        elsif (ref $v) {
            # assume it's a hash and hope for the best
            $v = {%$v};
        }
        else {
            Carp::croak("single argument must be HASH or ARRAY reference");
        }
        $self->{$param} = $self->$check_param($v);
    }
    elsif (@_) {
        Carp::croak("odd number of parameters?")
            if scalar(@_)%2;
        $self->{$param} = $self->$check_param({@_});
    }
    return $self->{$param};
}

sub minimum_version {
    my Net::OpenID::Consumer $self = shift;

    if (@_) {
        my $minv = shift;
        Carp::croak("Too many parameters") if @_;
        $minv = 1 unless $minv && $minv > 1;
        $self->{minimum_version} = $minv;
    }
    return $self->{minimum_version};
}

sub _canonicalize_assoc_options { return $_[1]; }

sub _debug {
    my Net::OpenID::Consumer $self = shift;
    return unless $self->{debug};

    if (ref $self->{debug} eq "CODE") {
        $self->{debug}->($_[0]);
    } else {
        print STDERR "[DEBUG Net::OpenID::Consumer] $_[0]\n";
    }
}

# given something that can have GET arguments, returns a subref to get them:
#   Apache
#   Apache::Request
#   CGI
#   HASH of get args
#   CODE returning get arg, given key

#   ...

sub args {
    my Net::OpenID::Consumer $self = shift;

    if (my $what = shift) {
        unless (ref $what) {
            return $self->{args} ? $self->{args}->($what) : Carp::croak("No args defined");
        }
        Carp::croak("Too many parameters") if @_;

        # since we do not require field setters to be called in any particular order,
        # we cannot pass minimum_version here as it might change later.
        my $message = Net::OpenID::IndirectMessage->new($what);
        $self->{message} = $message;
        if ($message) {
            $self->{args} = $message->getter;

            # handle OpenID 2.0 'error' mode
            # (may as well do this here; we may not get another chance
            # since handle_server_response is not a required part of the API)
            if ($message->protocol_version >= 2 && $message->mode eq 'error') {
                $self->_fail('provider_error',$message->get('error'));
            }
        }
        else {
            $self->{args} = sub { undef };
        }
    }
    $self->{args};
}

sub message {
    my Net::OpenID::Consumer $self = shift;
    my $message = $self->{message};
    return undef
      unless $message &&
        ($self->{minimum_version} <= $message->protocol_version);

    if (@_) {
        return $message->get($_[0]);
    }
    else {
        return $message;
    }
}

sub _message_mode_is {
    return (($_[0]->message('mode')||' ') eq $_[1]);
}

sub _message_version {
    my $message = $_[0]->message;
    return $message ? $message->protocol_version : 0;
}

sub ua {
    my Net::OpenID::Consumer $self = shift;
    $self->{ua} = shift if @_;
    Carp::croak("Too many parameters") if @_;

    # make default one on first access
    unless ($self->{ua}) {
        my $ua = $self->{ua} = LWP::UserAgent->new;
        $ua->timeout(10);
    }

    $self->{ua};
}

our %Error_text =
   (
    'bad_mode'                    => "The openid.mode argument is not correct",
    'bogus_delegation'            => "Asserted identity does not match claimed_id or local_id.",
    'bogus_return_to'             => "Return URL does not match required_root.",
    'bogus_url'                   => "URL scheme must be http: or https:",
    'empty_url'                   => "No URL entered.",
    'expired_association'         => "Association between ID provider and relying party has expired.",
    'naive_verify_failed_network' => sub {
	@_ ? "Unexpected verification response from ID provider:  $_[0]"
	   : "Could not contact ID provider to verify response." },
    'naive_verify_failed_return'  => "Direct contact invalidated ID provider response.",
    'no_identity'                 => "Identity is missing from ID provider response.",
    'no_identity_server'          => "Could not determine ID provider from URL.",
    'no_return_to'                => "Return URL is missing from ID provider response.",
    'no_sig'                      => "Signature is missing from ID provider response.",
    'protocol_version_incorrect'  => "ID provider does not support minimum protocol version",
    'provider_error'              => "ID provider-specific error",
    'server_not_allowed'          => "None of the discovered endpoints matches op_endpoint.",
    'signature_mismatch'          => "Prior association invalidated ID provider response.",
    'time_bad_sig'                => "Return_to signature is not valid.",
    'time_expired'                => "Return_to signature is stale.",
    'time_in_future'              => "Return_to signature is from the future.",
    'unexpected_url_redirect'     => "Discovery for the given ID ended up at the wrong place",
    'unsigned_field'              => sub { "Field(s) must be signed: " . join(", ", @_) },
    'nonce_missing'               => "Response_nonce is missing from ID provider response.",
    'nonce_reused'                => 'Re-used response_nonce; possible replay attempt.',
    'nonce_stale'                 => 'Stale response_nonce; could have been used before.',
    'nonce_format'                => 'Bad timestamp format in response_nonce.',
    'nonce_future'                => 'Provider clock is too far forward.',

# no longer used as of 1.11
#   'no_head_tag'   => "Could not determine ID provider; URL document has no <head>.",
#   'url_fetch_err' => "Error fetching the provided URL.",

   );

sub _fail {
    my Net::OpenID::Consumer $self = shift;
    my ($code, $text, @params) = @_;

    # 'bad_mode' is only an error if we survive to the end of
    # .mode dispatch without having figured out what to do;
    # it should not overwrite other errors.
    unless ($self->{last_errcode} && $code eq 'bad_mode') {
        $text ||= $Error_text{$code};
        $text = $text->(@params) if ref($text) && ref($text) eq 'CODE';
        $self->{last_errcode} = $code;
        $self->{last_errtext} = $text;
        $self->_debug("fail($code) $text");
    }
    wantarray ? () : undef;
}

sub json_err {
    my Net::OpenID::Consumer $self = shift;
    return encode_json({
        err_code => $self->{last_errcode},
        err_text => $self->{last_errtext},
    });
}

sub err {
    my Net::OpenID::Consumer $self = shift;
    $self->{last_errcode} . ": " . $self->{last_errtext};
}

sub errcode {
    my Net::OpenID::Consumer $self = shift;
    $self->{last_errcode};
}

sub errtext {
    my Net::OpenID::Consumer $self = shift;
    $self->{last_errtext};
}

# make sure you change the $prefix every time you change the $hook format
# so that when user installs a new version and the old cache server is
# still running the old cache entries won't confuse things.
sub _get_url_contents {
    my Net::OpenID::Consumer $self = shift;
    my ($url, $final_url_ref, $hook, $prefix) = @_;
    $final_url_ref ||= do { my $dummy; \$dummy; };

    my $res = Net::OpenID::URIFetch->fetch($url, $self, $hook, $prefix);

    $$final_url_ref = $res->final_uri;

    return $res ? $res->content : undef;
}


# List of head elements that matter for HTTP discovery.
# Each entry defines a key+value that will appear in the
# _find_semantic_info hash if the specified element exists
#  [
#    FSI_KEY    -- key name
#    TAG_NAME   -- must be 'link' or 'meta'
#
#    ELT_VALUES -- string (default = FSI_KEY)
#            what join(';',values of ELT_KEYS) has to match
#            in order for a given html element to provide
#            the value for FSI_KEY
#
#    ELT_KEYS   -- list-ref of html attribute names
#            default = ['rel']  for <link...>
#            default = ['name'] for <meta...>
#
#    FSI_VALUE  -- name of html attribute where value lives
#            default = 'href'    for <link...>
#            default = 'content' for <meta...>
#  ]
#
our @HTTP_discovery_link_meta_tags =
  map {
      my ($fsi_key, $tag, $elt_value, $elt_keys, $fsi_value) = @{$_};
      [$fsi_key, $tag,
       $elt_value || $fsi_key,
       $elt_keys  || [$tag eq 'link' ? 'rel'  : 'name'],
       $fsi_value || ($tag eq 'link' ? 'href' : 'content'),
      ]
  }
   # OpenID providers / delegated identities
   # <link rel="openid.server"
   #       href="http://www.livejournal.com/misc/openid.bml" />
   # <link rel="openid.delegate"
   #       href="whatever" />
   #
   [qw(openid.server    link)], # 'openid.server' => ['rel'], 'href'
   [qw(openid.delegate  link)],

   # OpenID2 providers / local identifiers
   # <link rel="openid2.provider"
   #       href="http://www.livejournal.com/misc/openid.bml" />
   # <link rel="openid2.local_id" href="whatever" />
   #
   [qw(openid2.provider  link)],
   [qw(openid2.local_id  link)],

   # FOAF maker info
   # <meta name="foaf:maker"
   #  content="foaf:mbox_sha1sum '4caa1d6f6203d21705a00a7aca86203e82a9cf7a'"/>
   #
   [qw(foaf.maker  meta  foaf:maker)], # == .name

   # FOAF documents
   # <link rel="meta" type="application/rdf+xml" title="FOAF"
   #       href="http://brad.livejournal.com/data/foaf" />
   #
   [qw(foaf link), 'meta;foaf;application/rdf+xml' => [qw(rel title type)]],

   # RSS
   # <link rel="alternate" type="application/rss+xml" title="RSS"
   #       href="http://www.livejournal.com/~brad/data/rss" />
   #
   [qw(rss link), 'alternate;application/rss+xml' => [qw(rel type)]],

   # Atom
   # <link rel="alternate" type="application/atom+xml" title="Atom"
   #       href="http://www.livejournal.com/~brad/data/rss" />
   #
   [qw(atom link), 'alternate;application/atom+xml' => [qw(rel type)]],
  ;

sub _document_to_semantic_info {
    my $doc = shift;
    my $info = {};

    my $elts = OpenID::util::html_extract_linkmetas($doc);
    for (@HTTP_discovery_link_meta_tags) {
        my ($key, $tag, $elt_value, $elt_keys, $vattrib) = @$_;
        for my $lm (@{$elts->{$tag}}) {
            $info->{$key} = $lm->{$vattrib}
              if $elt_value eq join ';', map {lc($lm->{$_}||'')} @$elt_keys;
        }
    }
    return $info;
}

sub _find_semantic_info {
    my Net::OpenID::Consumer $self = shift;
    my $url = shift;
    my $final_url_ref = shift;

    my $doc = $self->_get_url_contents($url, $final_url_ref);
    my $info = _document_to_semantic_info($doc);
    $self->_debug("semantic info ($url) = " . join(", ", map { $_.' => '.$info->{$_} } keys %$info)) if $self->{debug};

    return $info;
}

sub _find_openid_server {
    my Net::OpenID::Consumer $self = shift;
    my $url = shift;
    my $final_url_ref = shift;

    my $sem_info = $self->_find_semantic_info($url, $final_url_ref) or
        return;

    return $self->_fail("no_identity_server") unless $sem_info->{"openid.server"};
    $sem_info->{"openid.server"};
}

sub is_server_response {
    my Net::OpenID::Consumer $self = shift;
    return $self->message ? 1 : 0;
}

my $_warned_about_setup_required = 0;
sub handle_server_response {
    my Net::OpenID::Consumer $self = shift;
    my %callbacks_in = @_;
    my %callbacks = ();

    foreach my $cb (qw(not_openid cancelled verified error)) {
        $callbacks{$cb} = delete($callbacks_in{$cb}) || sub { Carp::croak("No ".$cb." callback") };
    }

    # backwards compatibility:
    #   'setup_needed' is expected as of 1.04
    #   'setup_required' is deprecated but allowed in its place,
    my $found_setup_callback = 0;
    foreach my $cb (qw(setup_needed setup_required)) {
        $callbacks{$cb} = delete($callbacks_in{$cb}) and $found_setup_callback++;
    }
    Carp::croak($found_setup_callback > 1
                ? "Cannot have both setup_needed and setup_required"
                : "No setup_needed callback")
        unless $found_setup_callback == 1;

    if (warnings::enabled('deprecated') &&
        $callbacks{setup_required} &&
        !$_warned_about_setup_required++
       ) {
        warnings::warn
            ("deprecated",
             "'setup_required' callback is deprecated, use 'setup_needed'");
    }

    Carp::croak("Unknown callbacks:  ".join(',', keys %callbacks_in))
        if %callbacks_in;

    unless ($self->is_server_response) {
        return $callbacks{not_openid}->();
    }

    if ($self->setup_needed) {
        return $callbacks{setup_needed}->()
          unless ($callbacks{setup_required});

        my $setup_url = $self->user_setup_url;
        return $callbacks{setup_required}->($setup_url)
          if $setup_url;
        # otherwise FALL THROUGH to preserve prior behavior,
        # Even though this is broken, old clients could have
        # put a workaround into the 'error' callback to handle
        # the setup_needed+(setup_url=undef) case
    }

    if ($self->user_cancel) {
        return $callbacks{cancelled}->();
    }
    elsif (my $vident = $self->verified_identity) {
        return $callbacks{verified}->($vident);
    }
    else {
        return $callbacks{error}->($self->errcode, $self->errtext);
    }

}

sub _canonicalize_id_url {
    my Net::OpenID::Consumer $self = shift;
    my $url = shift;

    # trim whitespace
    $url =~ s/^\s+//;
    $url =~ s/\s+$//;
    return $self->_fail("empty_url") unless $url;

    # add scheme
    $url = "http://$url" if $url && $url !~ m!^\w+://!;
    return $self->_fail("bogus_url") unless $url =~ m!^https?://!i;

    # make sure there is a slash after the hostname
    $url .= "/" unless $url =~ m!^https?://.+/!i;
    return $url;
}

# always returns a listref; might be empty, though
sub _discover_acceptable_endpoints {
    my Net::OpenID::Consumer $self = shift;
    my $url = shift;  #already canonicalized ID url
    my %opts = @_;

    # if return_early is set, we'll return as soon as we have enough
    # information to determine the "primary" endpoint, and return
    # that as the first (and possibly only) item in our response.
    my $primary_only = delete $opts{primary_only} ? 1 : 0;

    # if force_version is set, we only return endpoints that have
    # that have {version} == $force_version
    my $force_version = delete $opts{force_version};

    Carp::croak("Unknown option(s) ".join(', ', keys(%opts))) if %opts;

    my @discovered_endpoints = ();
    my $result = sub {
        # We always prefer 2.0 endpoints to 1.1 ones, regardless of
        # the priority chosen by the identifier.
        return [
            (grep { $_->{version} == 2 } @discovered_endpoints),
            (grep { $_->{version} == 1 } @discovered_endpoints),
        ];
    };

    # TODO: Support XRI too?

    # First we Yadis service discovery
    my $yadis = Net::OpenID::Yadis->new(consumer => $self);
    if ($yadis->discover($url)) {
        # FIXME: Currently we don't ever do _find_semantic_info in the Yadis
        # code path, so an extra redundant HTTP request is done later
        # when the semantic info is accessed.

        my $final_url = $yadis->identity_url;
        my @services = $yadis->services(
            OpenID::util::version_2_xrds_service_url(),
            OpenID::util::version_2_xrds_directed_service_url(),
            OpenID::util::version_1_xrds_service_url(),
        );
        my $version2 = OpenID::util::version_2_xrds_service_url();
        my $version1 = OpenID::util::version_1_xrds_service_url();
        my $version2_directed = OpenID::util::version_2_xrds_directed_service_url();

        foreach my $service (@services) {
            my $service_uris = $service->URI;

            # Service->URI seems to return all sorts of bizarre things, so let's
            # normalize it to always be an arrayref.
            if (ref($service_uris) eq 'ARRAY') {
                my @sorted_id_servers = sort {
                    my $pa = $a->{priority};
                    my $pb = $b->{priority};
                    defined($pb) <=> defined($pa)
                      || (defined($pa) ? ($pa <=> $pb) : 0)
                } @$service_uris;
                $service_uris = \@sorted_id_servers;
            }
            if (ref($service_uris) eq 'HASH') {
                $service_uris = [ $service_uris->{content} ];
            }
            unless (ref($service_uris)) {
                $service_uris = [ $service_uris ];
            }

            my $delegate = undef;
            my @versions = ();

            if (grep(/^${version2}$/, $service->Type)) {
                # We have an OpenID 2.0 end-user identifier
                $delegate = $service->extra_field("LocalID");
                push @versions, 2;
            }
            if (grep(/^${version1}$/, $service->Type)) {
                # We have an OpenID 1.1 end-user identifier
                $delegate = $service->extra_field("Delegate", "http://openid.net/xmlns/1.0");
                push @versions, 1;
            }

            if (@versions) {
                foreach my $version (@versions) {
                    next if defined($force_version) && $force_version != $version;
                    foreach my $uri (@$service_uris) {
                        push @discovered_endpoints, {
                            uri => $uri,
                            version => $version,
                            final_url => $final_url,
                            delegate => $delegate,
                            sem_info => undef,
                            mechanism => "Yadis",
                        };
                    }
                }
            }

            if (((!defined($force_version)) || $force_version == 2)
                && grep(/^${version2_directed}$/, $service->Type)) {

                # We have an OpenID 2.0 OP identifier (i.e. we're doing directed identity)
                my $version = 2;
                # In this case, the user's claimed identifier is a magic value
                # and the actual identifier will be determined by the provider.
                my $final_url = OpenID::util::version_2_identifier_select_url();
                my $delegate = OpenID::util::version_2_identifier_select_url();

                foreach my $uri (@$service_uris) {
                    push @discovered_endpoints, {
                        uri => $uri,
                        version => $version,
                        final_url => $final_url,
                        delegate => $delegate,
                        sem_info => undef,
                        mechanism => "Yadis",
                    };
                }
            }

            if ($primary_only && scalar(@discovered_endpoints)) {
                # We've got at least one endpoint now, so return early
                return $result->();
            }
        }
    }

    # Now HTML-based discovery, both 2.0- and 1.1-style.
    {
        my $final_url = undef;
        my $sem_info = $self->_find_semantic_info($url, \$final_url);

        if ($sem_info) {
            if ($sem_info->{"openid2.provider"}) {
                unless (defined($force_version) && $force_version != 2) {
                    push @discovered_endpoints, {
                        uri => $sem_info->{"openid2.provider"},
                        version => 2,
                        final_url => $final_url,
                        delegate => $sem_info->{"openid2.local_id"},
                        sem_info => $sem_info,
                        mechanism => "HTML",
                    };
                }
            }
            if ($sem_info->{"openid.server"}) {
                unless (defined($force_version) && $force_version != 1) {
                    push @discovered_endpoints, {
                        uri => $sem_info->{"openid.server"},
                        version => 1,
                        final_url => $final_url,
                        delegate => $sem_info->{"openid.delegate"},
                        sem_info => $sem_info,
                        mechanism => "HTML",
                    };
                }
            }
        }
    }

    return $result->();

}

# returns Net::OpenID::ClaimedIdentity
sub claimed_identity {
    my Net::OpenID::Consumer $self = shift;
    my $url = shift;
    Carp::croak("Too many parameters") if @_;

    return unless $url = $self->_canonicalize_id_url($url);

    my $endpoints = $self->_discover_acceptable_endpoints($url, primary_only => 1);

    if (@$endpoints) {
        foreach my $endpoint (@$endpoints) {

            next unless $endpoint->{version} >= $self->minimum_version;

            $self->_debug("Discovered version $endpoint->{version} endpoint at $endpoint->{uri} via $endpoint->{mechanism}");
            $self->_debug("Delegate is $endpoint->{delegate}") if $endpoint->{delegate};

            return Net::OpenID::ClaimedIdentity->new(
                identity         => $endpoint->{final_url},
                server           => $endpoint->{uri},
                consumer         => $self,
                delegate         => $endpoint->{delegate},
                protocol_version => $endpoint->{version},
                semantic_info    => $endpoint->{sem_info},
            );

        }

        # If we've fallen out here, then none of the available services are of the required version.
        return $self->_fail("protocol_version_incorrect");

    }
    else {
        return $self->_fail("no_identity_server");
    }

}

sub user_cancel {
    my Net::OpenID::Consumer $self = shift;
    return $self->_message_mode_is("cancel");
}

sub setup_needed {
    my Net::OpenID::Consumer $self = shift;
    if ($self->_message_version == 1) {
        return $self->_message_mode_is("id_res") && $self->message("user_setup_url");
    }
    else {
        return $self->_message_mode_is('setup_needed');
    }
}

sub user_setup_url {
    my Net::OpenID::Consumer $self = shift;
    my %opts = @_;
    my $post_grant = delete $opts{'post_grant'};
    Carp::croak("Unknown options: " . join(", ", keys %opts)) if %opts;

    if ($self->_message_version == 1) {
        return $self->_fail("bad_mode") unless $self->_message_mode_is("id_res");
    }
    else {
        return undef unless $self->_message_mode_is('setup_needed');
    }
    my $setup_url = $self->message("user_setup_url");

    OpenID::util::push_url_arg(\$setup_url, "openid.post_grant", $post_grant)
        if $setup_url && $post_grant;

    return $setup_url;
}

sub verified_identity {
    my Net::OpenID::Consumer $self = shift;
    my %opts = @_;

    my $rr = delete $opts{'required_root'} || $self->{required_root};
    Carp::croak("Unknown options: " . join(", ", keys %opts)) if %opts;

    return $self->_fail("bad_mode") unless $self->_message_mode_is("id_res");

    # the asserted identity (the delegated one, if there is one, since the protocol
    # knows nothing of the original URL)
    my $a_ident  = $self->message("identity")     or return $self->_fail("no_identity");

    my $sig64    = $self->message("sig")          or return $self->_fail("no_sig");

    # fix sig if the OpenID provider failed to properly escape pluses (+) in the sig
    $sig64 =~ s/ /+/g;

    my $returnto = $self->message("return_to")    or return $self->_fail("no_return_to");
    my $signed   = $self->message("signed");

    my $possible_endpoints;
    my $server;
    my $claimed_identity;

    my $real_ident =
      ($self->_message_version == 1
       ? $self->args("oic.identity")
       : $self->message("claimed_id")
      ) || $a_ident;
    my $real_canon = $self->_canonicalize_id_url($real_ident);

    return $self->_fail("no_identity_server")
      unless ($real_canon
              && @{
                  $possible_endpoints =
                    $self->_discover_acceptable_endpoints
                      ($real_canon, force_version => $self->_message_version)
                  });
    # FIXME: It kinda sucks that the above will always do both Yadis and HTML discovery, even though
    # in most cases only one will be in use.

    if ($self->_message_version == 1) {
        # In version 1, we have to assume that the primary server
        # found during discovery is the one sending us this message.
        splice(@$possible_endpoints,1);
        $server = $possible_endpoints->[0]->{uri};
        $self->_debug("Server is $server");
    }
    else {
        # In version 2, the OpenID provider tells us its URL.
        $server = $self->message("op_endpoint");
        $self->_debug("Server is $server");
        # but make sure that URL matches one of the discovered ones.
        @$possible_endpoints =
          grep {$_->{uri} eq $server} @$possible_endpoints
            or return $self->_fail("server_not_allowed");
    }

    # check that returnto is for the right host
    return $self->_fail("bogus_return_to") if $rr && $returnto !~ /^\Q$rr\E/;

    my $now = time();

    # check that we have not seen response_nonce before
    my $response_nonce = $self->message("response_nonce");
    unless ($response_nonce) {
        # 1.0/1.1 does not require nonces
        return $self->_fail("nonce_missing")
          if $self->_message_version >= 2;
    }
    else {
        return unless $self->_nonce_check_succeeds($now, $server, $response_nonce);
    }

    # check age/signature of return_to
    {
        my ($sig_time, $sig) = split(/\-/, $self->args("oic.time") || "");
        # complain if more than an hour since we sent them off
        return $self->_fail("time_expired")   if $sig_time < $now - 3600;
        # also complain if the signature is from the future by more than 30 seconds,
        # which compensates for potential clock drift between nodes in a web farm.
        return $self->_fail("time_in_future") if $sig_time - 30 > $now;
        # and check that the time isn't faked
        my $c_secret = $self->_get_consumer_secret($sig_time);
        my $good_sig = substr(hmac_sha1_hex($sig_time, $c_secret), 0, 20);
        return $self->_fail("time_bad_sig") unless OpenID::util::timing_indep_eq($sig, $good_sig);
    }

    my $last_error = undef;
    my $error = sub {
        $self->_debug("$server not acceptable: ".$_[0]);
        $last_error = $_[0];
    };

    foreach my $endpoint (@$possible_endpoints) {
        # Known:
        #  $endpoint->{version} == $self->_message_version
        #  $endpoint->{uri} == $server

        my $final_url = $endpoint->{final_url};
        my $delegate = $endpoint->{delegate};

        # OpenID 2.0 wants us to exclude the fragment part of the URL when doing equality checks
        my $a_ident_nofragment = $a_ident;
        my $real_ident_nofragment = $real_ident;
        my $final_url_nofragment = $final_url;
        if ($self->_message_version >= 2) {
            $a_ident_nofragment =~ s/\#.*$//x;
            $real_ident_nofragment =~ s/\#.*$//x;
            $final_url_nofragment =~ s/\#.*$//x;
        }
        unless ($final_url_nofragment eq $real_ident_nofragment) {
            $error->("unexpected_url_redirect");
            next;
        }

        # if openid.delegate was used, check that it was done correctly
        if ($a_ident_nofragment ne $real_ident_nofragment) {
            unless ($delegate eq $a_ident_nofragment) {
                $error->("bogus_delegation");
                next;
            }
        }

        # If we've got this far then we've found the right endpoint.

        $claimed_identity =  Net::OpenID::ClaimedIdentity->new(
            identity         => $endpoint->{final_url},
            server           => $endpoint->{uri},
            consumer         => $self,
            delegate         => $endpoint->{delegate},
            protocol_version => $endpoint->{version},
            semantic_info    => $endpoint->{sem_info},
        );
        last;

    }

    unless ($claimed_identity) {
        # We failed to find a good endpoint in the above loop, so
        # lets bail out.
        return $self->_fail($last_error);
    }

    my $assoc_handle = $self->message("assoc_handle");

    $self->_debug("verified_identity: assoc_handle" .
		  ($assoc_handle ? ": $assoc_handle" : " missing"));
    my $assoc = Net::OpenID::Association::handle_assoc($self, $server, $assoc_handle);

    my @signed_fields = grep {m/^[\w\.]+$/} split(/,/, $signed);
    my %signed_value = map {$_,$self->args("openid.$_")} @signed_fields;

    # Auth 2.0 requires certain keys to be signed.
    if ($self->_message_version >= 2) {
        my %unsigned;
        # these fields must be signed unconditionally
        foreach my $f (qw/op_endpoint return_to response_nonce assoc_handle/) {
            $unsigned{$f}++ unless exists $signed_value{$f};
        }
        # these fields must be signed if present
        foreach my $f (qw/claimed_id identity/) {
            $unsigned{$f}++
              if $self->args("openid.$f") && !exists $signed_value{$f};
        }
        if (%unsigned) {
            return $self->_fail("unsigned_field", undef, keys %unsigned);
        }
    }

    if ($assoc) {
        $self->_debug("verified_identity: verifying with found association");

        return $self->_fail("expired_association")
            if $assoc->expired;

        # verify the token
        my $token = join '',map {"$_:$signed_value{$_}\n"} @signed_fields;

        utf8::encode($token);
        my $good_sig = $assoc->generate_signature($token);
        return $self->_fail("signature_mismatch") unless OpenID::util::timing_indep_eq($sig64, $good_sig);

    } else {
        $self->_debug("verified_identity: verifying using HTTP (dumb mode)");
        # didn't find an association.  have to do dumb consumer mode
        # and check it with a POST
        my %post;
        my @mkeys;
        if ($self->_message_version >= 2
            && (@mkeys = $self->message->all_parameters)) {
            # OpenID 2.0: copy *EVERYTHING*, not just signed parameters.
            # (XXX:  Do we need to copy non "openid." parameters as well?
            #  For now, assume if provider is sending them, there is a reason)
            %post = map {$_ eq 'openid.mode' ? () : ($_, $self->args($_)) } @mkeys;
        }
        else {
            # OpenID 1.1 *OR* legacy client did not provide a proper
            # enumerator; in the latter case under 2.0 we have no
            # choice but to send a partial (1.1-style)
            # check_authentication request and hope for the best.

            %post = (
                     "openid.assoc_handle" => $assoc_handle,
                     "openid.signed"       => $signed,
                     "openid.sig"          => $sig64,
                    );

            if ($self->_message_version >= 2) {
                $post{'openid.ns'} = OpenID::util::VERSION_2_NAMESPACE();
            }

            # and copy in all signed parameters that we don't already have into %post
            $post{"openid.$_"} = $signed_value{$_}
              foreach grep {!exists $post{"openid.$_"}} @signed_fields;

            # if the provider told us our handle as bogus, let's ask in our
            # check_authentication mode whether that's true
            if (my $ih = $self->message("invalidate_handle")) {
                $post{"openid.invalidate_handle"} = $ih;
            }
        }
        $post{"openid.mode"} = "check_authentication";

        my $req = HTTP::Request->new(POST => $server);
        $req->header("Content-Type" => "application/x-www-form-urlencoded");
        $req->content(join("&", map { "$_=" . uri_escape_utf8($post{$_}) } keys %post));

        my $ua  = $self->ua;
        my $res = $ua->request($req);
        return $self->_fail("naive_verify_failed_network", ($res ? ($res->status_line) : ()))
          unless $res && $res->is_success;

        my $content = $res->content;
        my %args = OpenID::util::parse_keyvalue($content);

        # delete the handle from our cache
        if (my $ih = $args{'invalidate_handle'}) {
            Net::OpenID::Association::invalidate_handle($self, $server, $ih);
        }

        return $self->_fail("naive_verify_failed_return") unless
            $args{'is_valid'} eq "true" ||  # protocol 1.1
            $args{'lifetime'} > 0;          # DEPRECATED protocol 1.0
    }

    $self->_debug("verified identity! = $real_ident");

    # verified!
    return Net::OpenID::VerifiedIdentity->new(
        claimed_identity => $claimed_identity,
        consumer  => $self,
        signed_fields => \%signed_value,
    );
}

sub supports_consumer_secret { 1; }

sub _get_consumer_secret {
    my Net::OpenID::Consumer $self = shift;
    my $time = shift;

    my $ss;
    if (ref $self->{consumer_secret} eq "CODE") {
        $ss = $self->{consumer_secret};
    } elsif ($self->{consumer_secret}) {
        $ss = sub { return $self->{consumer_secret}; };
    } else {
        Carp::croak("You haven't defined a consumer_secret value or subref.\n");
    }

    my $sec = $ss->($time);
    Carp::croak("Consumer secret too long") if length($sec) > 255;
    return $sec;
}

our $nonce_default_delay = 1200;
our $nonce_default_skew = 300;

sub _canonicalize_nonce_options {
    my Net::OpenID::Consumer $self = shift;
    my $o = shift;
    my ($no_check,$ignore_time,$lifetime,$window,$start,$skew,$timecop) =
      delete @{$o}{qw(no_check ignore_time lifetime window start skew timecop)};
    Carp::croak("Unrecognized nonce_options: ".join(',',keys %$o))
        if keys %$o;

    return +{ no_check => 1 }
      if ($no_check);

    return +{ window => 0,
              lifetime => ($lifetime && $lifetime > 0 ? $lifetime : 0),
            }
      if ($ignore_time);

    $window =
      defined($lifetime) ? $lifetime :
        $nonce_default_delay + 2*(defined($skew) && $skew > $nonce_default_skew
                                  ? $skew : $nonce_default_skew)
      unless (defined($window));

    $lifetime = $window
      unless (defined($lifetime));

    $lifetime = 0 if $lifetime < 0;
    $window = 0 if $window < 0;

    $skew = $window < 2*$nonce_default_skew ? $window/2 : $nonce_default_skew
      unless (defined($skew));

    Carp::croak("Unrecognized nonce_options: ".join(',',keys %$o))
        if keys %$o;

    return
      +{
        window => $window,
        lifetime => $lifetime,
        skew => $skew,
        defined($start)  ? (start => $start) : (),
       };
}

# The contract:
#     IF the provider adheres to protocol and is properly configured
#     which, for our purposes here means
#       (1) it sends properly formatted nonces
#           that reflect provider clock time and
#       (2) provider clock is not skewed from our own by more than
#           <skew> (the maximum acceptable)
#     AND
#       we have a cache that can reliably hold onto entries
#       for at least <lifetime> seconds
#     THEN we must not accept a duplicate nonce.
#
# Preconditions imply that no message with this nonce will be received
# prior to <nonce_time>-<skew> (i.e., provider clock is running
# maximally fast and there is no transmission delay).  If our cache
# start time is prior to this and the lifetime of cache entries is
# long enough, then we can know for certain that it's not a duplicate,
# otherwise we do not and therefore must reject it.
#
# If we detect an instance where preconditions do not hold, there is
# not much we can do: rejecting nonces in this case will not make the
# protocol more secure.  As long as the provider's clock is skewed too
# far forward, an attacker will be able to take advantage of it.  Best
# we can do is issue warnings, which is the point of 'timecop', but if
# there's no place to send the warnings, then it's a waste of time.
#
sub _nonce_check_succeeds {
    my Net::OpenID::Consumer $self = shift;
    my ($now, $uri, $nonce) = @_;

    my $o = $self->nonce_options;
    my $cache = $self->cache;
    return 1
      if $o->{no_check} || !$cache;

    my $cache_key = "nonce:$uri:$nonce";

    return $self->_fail('nonce_reused') if ($cache->get($cache_key));
    $cache->set($cache_key, 1,
                ($o->{lifetime} ? ($now + $o->{lifetime}) : ()));

    return 1
      unless $o->{window} || $o->{start};

    # parse RFC3336 timestamp restricted as per 10.1
    my ($year,$mon,$day,$hour,$min,$sec) =
      $nonce =~ m/^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z/
      or return $self->_fail('nonce_format');

    # $nonce_time is a lower bound on when the nonce could have been
    # received according to our clock
    my $nonce_time = eval { timegm($sec,$min,$hour,$day,$mon-1,$year) - $o->{skew} };
    return $self->_fail('nonce_format') if $@;

    # nonces from the future indicate misconfigured providers
    # that we can do nothing about except give warnings
    return !$o->{timecop} || $self->_fail('nonce_future')
        if ($now < $nonce_time);

    # the check that matters
    return $self->_fail('nonce_stale')
      if   ($o->{window} && $nonce_time < $now - $o->{window})
        || ($o->{start} && $nonce_time < $o->{start});

    # win
    return 1;
}



1;
__END__

=head1 NAME

Net::OpenID::Consumer - Library for consumers of OpenID identities

=head1 VERSION

version 1.18

=head1 SYNOPSIS

  use Net::OpenID::Consumer;

  my $csr = Net::OpenID::Consumer->new(
    ua    => LWPx::ParanoidAgent->new,
    cache => Cache::File->new( cache_root => '/tmp/mycache' ),
    args  => $cgi,
    consumer_secret => ...,
    required_root => "http://site.example.com/",
    assoc_options => [
      max_encrypt => 1,
      session_no_encrypt_https => 1,
    ],
  );

  # Say a user enters "bradfitz.com" as his/her identity.  The first
  # step is to perform discovery, i.e., fetch that page, parse it,
  # find out the actual identity provider and other useful information,
  # which gets encapsulated in a Net::OpenID::ClaimedIdentity object:

  my $claimed_identity = $csr->claimed_identity("bradfitz.com");
  unless ($claimed_identity) {
    die "not actually an openid?  " . $csr->err;
  }

  # We can then launch the actual authentication of this identity.
  # The first step is to redirect the user to the appropriate URL at
  # the identity provider.  This URL is constructed as follows:
  #
  my $check_url = $claimed_identity->check_url(
    return_to  => "http://example.com/openid-check.app?yourarg=val",
    trust_root => "http://example.com/",

    # to do a "checkid_setup mode" request, in which the user can
    # interact with the provider, e.g., so that the user can sign in
    # there if s/he has not done so already, you will need this,
    delayed_return => 1

    # otherwise, this will be a "check_immediate mode" request, the
    # provider will have to immediately return some kind of answer
    # without interaction
  );

  # Once you redirect the user to $check_url, the provider should
  # eventually redirect back, at which point you need some kind of
  # handler at openid-check.app to deal with that response.

  # You can either use the callback-based API (recommended)...
  #
  $csr->handle_server_response(
      not_openid => sub {
          die "Not an OpenID message";
      },
      setup_needed => sub {
          if ($csr->message->protocol_version >= 2) {
              # (OpenID 2) retry request in checkid_setup mode (above)
          }
          else {
              # (OpenID 1) redirect user to $csr->user_setup_url
          }
      },
      cancelled => sub {
          # User hit cancel; restore application state prior to check_url
      },
      verified => sub {
          my ($vident) = @_;
          my $verified_url = $vident->url;
          print "You are $verified_url !";
      },
      error => sub {
          my ($errcode,$errtext) = @_;
          die("Error validating identity: $errcode: $errcode");
      },
  );

  # ... or handle the various cases yourself
  #
  unless ($csr->is_server_response) {
      die "Not an OpenID message";
  } elsif ($csr->setup_needed) {
       # (OpenID 2) retry request in checkid_setup mode
       # (OpenID 1) redirect/link/popup user to $csr->user_setup_url
  } elsif ($csr->user_cancel) {
       # User hit cancel; restore application state prior to check_url
  } elsif (my $vident = $csr->verified_identity) {
       my $verified_url = $vident->url;
       print "You are $verified_url !";
  } else {
       die "Error validating identity: " . $csr->err;
  }


=head1 DESCRIPTION

This is the Perl API for (the consumer half of) OpenID, a distributed
identity system based on proving you own a URL, which is then your
identity.  More information is available at:

  http://openid.net/

=head1 CONSTRUCTOR

=over 4

=item B<new>

 my $csr = Net::OpenID::Consumer->new( %options );

The following option names are recognized:
C<ua>,
C<cache>,
C<args>,
C<consumer_secret>,
C<minimum_version>,
C<required_root>,
C<assoc_options>, and
C<nonce_options>
in the constructor.
In each case the option value is treated exactly as the argument
to the corresponding method described below under L<Configuration|/Configuration>.

=back

=head1 METHODS

=head2 State

=over 4

=item $csr->B<message>($key)

Returns the value for the given key/field from the OpenID protocol
message contained in the request URL parameters (i.e., the value for
the URL parameter C<openid.$key>).
This can only be used to obtain core OpenID fields not extension fields.

Calling this method without a C<$key> argument returns a
L<Net::OpenID::IndirectMessage|Net::OpenID::IndirectMessage>
object representing the protocol message, at which point the
various object methods are available, including

 $csr->message->protocol_version
 $csr->message->has_ext
 $csr->message->get_ext

Returns undef in either case if no URL parameters have been supplied
(i.e., because B<args>() has not been initialized) or if the request
is not an actual OpenID message.

=item $csr->B<err>

Returns the last error, in form "errcode: errtext",
as set by the various handlers below.

=item $csr->B<errcode>

Returns the last error code.
See L<Error Codes|/ERROR CODES> below.

=item $csr->B<errtext>

Returns the last error text.

=item $csr->B<json_err>

Returns the last error code/text in JSON format.

=back

=head2 Configuration

=over 4

=item $csr->B<ua>($user_agent)

=item $csr->B<ua>

Getter/setter for the L<LWP::UserAgent|LWP::UserAgent> (or subclass)
instance which will be used when direct HTTP requests to a provider are needed.
It's highly recommended that you use
L<LWPx::ParanoidAgent|LWPx::ParanoidAgent>, or at least read its
documentation so you're aware of why you should care.

=item $csr->B<cache>($cache)

=item $csr->B<cache>

Getter/setter for the cache instance which is used for storing fetched
HTML or XRDS pages, keys for associations with identity providers, and
received response_nonce values from positive provider assertions.

The $cache object can be anything that has a -E<gt>get($key) and
-E<gt>set($key,$value[,$expire]) methods.  See L<URI::Fetch> for more
information.  This cache object is passed to L<URI::Fetch|URI::Fetch> directly.

Setting a cache instance is not absolutely required,
But without it, provider associations will not be possible and
the same pages may be fetched multiple times during discovery.
B<It will also not be possible to check for repetition of the
response_nonce, which may then leave you open to replay attacks.>

=item $csr->B<consumer_secret>($scalar)

=item $csr->B<consumer_secret>($code)

 $code = $csr->B<consumer_secret>; ($secret) = $code->($time);

The consumer secret is used to generate self-signed nonces for the
return_to URL, to prevent spoofing.

In the simplest (and least secure) form, you configure a static secret
value with a scalar.  If you use this method and change the scalar
value, any outstanding requests from the last 30 seconds or so will fail.

You may also supply a subref that takes one argument, I<$time>,
a unix timestamp and returns a secret.

Your secret may not exceed 255 characters.

For the best protection against replays and login cross-site request
forgery, consumer_secret should additionally depend on something known
to be specific to the client browser instance and not visible to an
attacker.  If C<SSH_SESSION_ID> is available, you should use that.
Otherwise you'll need to set a (Secure) cookie on the (HTTPS) page
where the signin form appears in order to establish a pre-login
session, then make sure to change this cookie upon successful login.

=item $csr->B<minimum_version>(2)

=item $csr->B<minimum_version>

Get or set the minimum OpenID protocol version supported. Currently
the only useful value you can set here is 2, which will cause
1.1 identifiers to fail discovery with the error C<protocol_version_incorrect>
and responses from version 1 providers to not be recognized.

In most cases you'll want to allow both 1.1 and 2.0 identifiers,
which is the default. If you want, you can set this property to 1
to make this behavior explicit.

=item $csr->B<args>($ref)

=item $csr->B<args>($param)

=item $csr->B<args>

Can be used in 1 of 3 ways:

=over

=item 1.

Set the object from which URL parameter names and values are to be retrieved:

 $csr->args( $reference )

where C<$reference> is either
an unblessed C<HASH> ref,
a C<CODE> ref, or
some kind of "request object" E<mdash> the latter being either a
L<CGI|..::CGI>,
L<Apache|..::Apache>,
L<Apache::Request|Apache::Request>,
L<Apache2::Request|Apache2::Request>, or
L<Plack::Request|Plack::Request> object.

If you pass in a C<CODE> ref, it must,

=over

=item *

given a single parameter name argument, return the corresponding parameter value, I<and>,

=item *

given no arguments at all, return the full list of parameter names from the request.

=back

If you pass in an L<Apache|..::Apache> (mod_perl 1.x interface) object
and this is a POST request, you must I<not> have already called
C<< $r->content >> as this routine will be making said call
itself in order to extract the request parameters.

=item 2.

Get a parameter value:

 my $foo = $csr->args("foo");

When given an unblessed scalar, it retrieves the value.  It croaks if
you haven't defined a way to get at the parameters.

Most callers should instead use the C<message> method above, which
abstracts away the need to understand OpenID's message serialization.

=item 3.

Get the parameter getter:

 my $code = $csr->args;

this being a subref that takes a parameter name and
returns the corresponding value.

Most callers should instead use the C<message> method above with no
arguments, which returns an object from which extension attributes
can be obtained by their documented namespace URI.

=back

=item $csr->B<required_root>($url_prefix)

=item $csr->B<required_root>

Gets or sets the string prefix that, if nonempty, all return_to URLs
must start with.  Messages with return_to URLS that don't match will
be considered invalid (spoofed from another site).

=item $csr->B<assoc_options>(...)

=item $csr->B<assoc_options>

Get or sets the hash of parameters that determine how associations
with identity providers will be made.  Available options include:

=over 4

=item C<assoc_type>

Association type, (default 'HMAC-SHA1')

=item C<session_type>

Association session type, (default 'DH-SHA1')

=item C<max_encrypt>

(boolean)
Use best encryption available for protocol version
for both session type and association type.
This overrides C<session_type> and C<assoc_type>

=item C<session_no_encrypt_https>

(boolean)
Use an unencrypted session type if the ID provider URL scheme is C<https:>.
This overrides C<max_encrypt> if both are set.

=item C<allow_eavesdropping>

(boolean)
Because it is generally a bad idea, we abort associations where an
unencrypted session over a non-SSL connection is called for.
However the OpenID 1.1 specification technically allows this,
so if that is what you really want, set this flag true.
Ignored under protocol version 2.

=back

=item $csr->B<nonce_options>(...)

=item $csr->B<nonce_options>

Gets or sets the hash of options for how response_nonce should be checked.

In OpenID 2.0, response_nonce is sent by the identity provider as part
of a positive identity assertion in order to help prevent replay
attacks.  In the check_authentication phase, the provider is also
required to not authenticate the same response_nonce twice.

The relying party is strongly encouraged but not required to reject
multiple occurrences of a nonce (which can matter if associations are
in use and there is no check_authentication phase).  Relying party may
also choose to reject a nonce on the basis of the timestamp being out
of an acceptable range.

Available options include:

=over

=item C<nocheck>

(boolean)
Skip response_nonce checking entirely.
This overrides all other nonce_options.

C<nocheck> is implied and is the only possibility if $csr->B<cache> is unset.

=item C<lifetime>

(integer)
Cache entries for nonces will expire after this many seconds.

Defaults to the value of C<window>, below.

If C<lifetime> is zero or negative, expiration times will not be set
at all; entries will expire as per the default behavior for your cache
(or you will need to purge them via some separate process).

If your cache implementation ignores the third argument on
$entry->B<set>() calls (see L<Cache::Entry>), then this option
has no effect beyond serving as a default for C<window>.

=item C<ignoretime>

(boolean)
Do not do any checking of timestamps, i.e., only test whether nonce is in
the cache.  This overrides all other nonce options except for C<lifetime>
and C<nocheck>

=item C<skew>

(integer)
Number of seconds that a provider clock can be ahead of ours before we
deem it to be misconfigured.

Default skew is 300 (5 minutes) or C<window/2>, if C<window> is
specified and C<window/2> is smaller.

(C<skew> is treated as 0 if set negative, but don't do that).

Misconfiguration of the provider clock means its timestamps are not
reliable, which then means there is no way to know whether or not the
nonce could have been sent before the start of the cache window, which
nullifies any obligation to detect all multiply sent nonces.
Conversely, if proper configuration can be assumed, then the timestamp
value minus C<skew> will be the earliest possible time that we could
have received a previous instance of this response_nonce, and if the
cache is reliable about holding entries from that time forward, then
(and only then) can one be certain that an uncached nonce instance is
indeed the first.

=item  C<start>

(integer)
Reject nonces where I<timestamp> minus C<skew> is earlier than C<start>
(absolute seconds; default is zero a.k.a. midnight 1/1/1970 UTC)

If you know the start time of your HTTP server (or your cache server,
if that is separate E<mdash> or the maximum of the start times if you
have multiple cache servers), you should use this option to declare that.

=item  C<window>

(integer)
Reject nonces where I<timestamp> minus C<skew> is more than C<window>
seconds ago.  Zero or negative values of C<window> are treated as
infinite (i.e., allow everything).

If C<lifetime> is specified, C<window> defaults to that.
If C<lifetime> is not specified, C<window> defaults to 1800 (30 minutes),
adjusted upwards if C<skew> is specified and larger than the default skew.

On general principles, C<window> should be a maximal expected
propagation delay plus twice the C<skew>.

Values between 0 and C<skew> (causing all nonces to be rejected) and
values greater than C<lifetime> (cache may fail to keep all nonces
that are still within the window) are I<not> recommended.

=item C<timecop>

(boolean)
Reject nonces from The Future (i.e., timestamped more than
C<skew> seconds from now).

Note that rejecting future nonces is not required.  Nor does it
protect from anything since an attacker can retry the message once it
has expired from the cache but is still within the time interval where
we would not yet I<expect> that it could expire E<mdash> this being
the essential problem with future nonces.  It may, however, be useful
to have warnings about misconfigured provider clocks E<mdash> and hence
about this insecurity E<mdash> at the cost of impairing interoperability
(since this rejects messages that are otherwise allowed by the
protocol), hence this option.

=back

In most cases it will be enough to either set C<nocheck> to dispense
with response_nonce checking entirely because some other (better)
method of preventing replay attacks (see B<consumer_secret>) has been
implemented, or use C<lifetime> to declare/set the lifetime of cache
entries for nonces whether because the default lifetime is
unsatisfactory or because the cache implementation is incapable of
setting individual expiration times.  All other options should default
reasonably in these cases.

In order for the nonce check to be as reliable/secure as possible
(i.e., that it block all instances of duplicate nonces from properly
configured providers as defined by C<skew>, which is the best we can
do), C<start> must be no earlier than the cache start time and the
cache must be guaranteed to hold nonce entries for at least C<window>
seconds (though, to be sure, if you can tolerate being vulnerable for
the first C<window> seconds of a server run, then you do not need to
set C<start>).

=back

=head2 Performing Discovery

=over

=item $csr->B<claimed_identity>($url)

Given a user-entered $url
(which could be missing http://, or have extra whitespace, etc),
converts it to canonical form,
performs partial discovery to confirm that at least one provider endpoint exists,
and returns a L<Net::OpenID::ClaimedIdentity|Net::OpenID::ClaimedIdentity>
object, or, on failure of any of the above,
returns undef and sets last error ($csr->B<err>).

Note that the identity returned is I<not> verified yet.
It's only who the user claims they are, but they could be lying.

If this method returns undef, an error code will be set.
See L<Error Codes|/ERROR CODES> below.

=back

=head2 Handling Provider Responses

The following routines are for handling a redirected provider response
and assume that, among other things, $csr->B<args> has been properly
populated with the URL parameters.

=over

=item $csr->B<handle_server_response>( %callbacks );

When a request comes in that contains a response from an OpenID provider,
figure out what it means and dispatch to an appropriate callback to handle
the request. This is the callback-based alternative to explicitly calling
the methods below in the correct sequence, and is recommended unless you
need to do something strange.

Anything you return from the selected callback function will be returned
by this method verbatim. This is useful if the caller needs to return
something different in each case.

The available callbacks are:

=over

=item C<not_openid>

the request isn't an OpenID response after all.

=item C<setup_needed>

a checkid_immediate mode request was rejected, indicating that the provider requires user interaction.

=item C<cancelled>

the user cancelled the authentication request from the provider's UI.

=item C<verified ($verified_identity)>

the user's identity has been successfully verified.
A L<Net::OpenID::VerifiedIdentity|Net::OpenID::VerifiedIdentity> object is passed in.

=item C<error ($errcode, $errmsg)>

an error has occurred. An error code and message are provided.
See L<Error Codes|/ERROR CODES> below for the meanings of the codes.

=back

For the sake of legacy code we also allow

=over

=item C<setup_required ($setup_url)>

B<[DEPRECATED]> a checkid_immediate mode request was rejected
I<and> $setup_url was provided.

Clients using this callback should be updated to use B<setup_needed>
at the earliest opportunity.  Here $setup_url is the same as returned by
$csr->B<user_setup_url>.

=back

=item $csr->B<is_server_response>

Returns true if a set of URL parameters has been supplied (via $csr->B<args>)
and constitutes an actual OpenID protocol message.

=item $csr->B<setup_needed>

Returns true if a checkid_immediate request failed because the provider
requires user interaction.  The correct action to take at this point
depends on the OpenID protocol version

(Version 1) Redirect to or otherwise make available a link to
C<$csr>->C<user_setup_url>.

(Version 2) Retry the request in checkid_setup mode; the provider will
then issue redirects as needed.

=over

B<N.B.>: While some providers have been known to supply the C<user_setup_url>
parameter in Version 2 C<setup_needed> responses, you I<cannot> rely on this,
and, moreover, since the OpenID 2.0 specification has nothing to say about
the meaning of such a parameter, you cannot rely on it meaning anything
in particular even if it is supplied.

=back

=item $csr->B<user_setup_url>( [ %opts ] )

(Version 1 only) Returns the URL the user must return to in order to
login, setup trust, or do whatever the identity provider needs them to
do in order to make the identity assertion which they previously
initiated by entering their claimed identity URL.

=over

B<N.B.>: Checking whether C<user_setup_url> is set in order to determine
whether a checkid_immediate request failed is DEPRECATED and will fail
under OpenID 2.0.  Use C<setup_needed()> instead.

=back

The base URL that this function returns can be modified by using the
following options in %opts:

=over

=item C<post_grant>

What you're asking the identity provider to do with the user after they
setup trust.  Can be either C<return> or C<close> to return the user
back to the return_to URL, or close the browser window with
JavaScript.  If you don't specify, the behavior is undefined (probably
the user gets a dead-end page with a link back to the return_to URL).
In any case, the identity provider can do whatever it wants, so don't
depend on this.

=back

=item $csr->B<user_cancel>

Returns true if the user declined to share their identity, false
otherwise.  (This function is literally one line: returns true if
"openid.mode" eq "cancel")

It's then your job to restore your app to where it was prior to
redirecting them off to the user_setup_url, using the other query
parameters that you'd sent along in your return_to URL.

=item $csr->B<verified_identity>( [ %opts ] )

Returns a Net::OpenID::VerifiedIdentity object,
or returns undef and sets last error ($csr->B<err>).
Verification includes double-checking the reported identity URL
declares the identity provider, verifying the signature, etc.

The options in %opts may contain:

=over

=item C<required_root>

Sets the required_root just for this request.  Values returns to its
previous value afterwards.

=back

If this method returns undef, an error code will be set.
See L<Error Codes|/ERROR CODES> below.

=back

=head1 ERROR CODES

This is the complete list of error codes that can be set.  Errors marked with (C) are set by B<claimed_identity>.  Other errors occur during handling of provider responses and can be set by B<args> (A), B<verified_identity> (V), and B<user_setup_url> (S), all of which can show up in the C<error> callback for B<handle_server_response>.

=over

=over

=item C<provider_error>

(A) The protocol message is a (2.0) error mode (i.e., C<openid.mode = 'error'>) message, typically used for provider-specific error responses.  Use $csr->B<message> to get at the C<contact> and C<reference> fields.

=item C<empty_url>

(C) Tried to do discovery on an empty or all-whitespace string.

=item C<bogus_url>

(C) Tried to do discovery on a non-http:/https: URL.

=item C<protocol_version_incorrect>

(C) None of the ID providers found support even the minimum protocol version ($csr->B<minimum_version>)

=item C<no_identity_server>

(CV) Tried to do discovery on a URL that does not seem to have any providers at all.

=item C<bad_mode>

(SV) The C<openid.mode> was expected to be C<id_res> (positive assertion or, in version 1, checkid_immediate failed).

=item C<no_identity>

(V) The C<openid.identity> parameter is missing.

=item C<no_sig>

(V) The  C<openid.sig> parameter is missing.

=item C<no_return_to>

(V) The C<openid.return_to> parameter is missing

=item C<bogus_return_to>

(V) The C<return_to> URL does not match $csr->B<required_root>

=item C<nonce_missing>

(V) The C<openid.response_nonce> parameter is missing.

=item C<nonce_reused>

(V) A previous assertion from this provider used this response_nonce already.  Someone may be attempting a replay attack.

=item C<nonce_format>

(V) Either the response_nonce timestamp was not in the correct format (e.g., tried to have fractional seconds or not UTC) or one of the components was out of range (e.g., month = 13).

=item C<nonce_future>

(V) C<timecop> was set and we got a response_nonce that was more than C<skew> seconds into the future.

=item C<nonce_stale>

(V) We got a response_nonce that was either prior to the start time or more than window seconds ago.

=item C<time_expired>

(V) The return_to signature time (C<oic.time>) is from too long ago.

=item C<time_in_future>

(V) The return_to signature time (C<oic.time>) is too far into the future.

=item C<time_bad_sig>

(V) The HMAC of the return_to signature (C<oic.time>) is not what it should be.

=item C<server_not_allowed>

(V) None of the provider endpoints found for the given ID match the server specified by the C<openid.op_endpoint> parameter (OpenID 2 only).

=item C<unexpected_url_redirect>

(V) Discovery for the given ID ended up at the wrong place

=item C<bogus_delegation>

(V) Asserted identity (C<openid.identity>) does not match claimed_id or local_id/delegate.

=item C<unsigned_field>

(V) In OpenID 2.0, C<openid.op_endpoint>, C<openid.return_to>, C<openid.response_nonce>, and C<openid.assoc_handle> must always be signed, while C<openid.claimed_id> and C<openid.identity> must be signed if present.

=item C<expired_association>

(V) C<openid.assoc_handle> is for an association that has expired.

=item C<signature_mismatch>

(V) An attempt to confirm the positive assertion using the association given by C<openid.assoc_handle> failed; the signature is not what it should be.

=item C<naive_verify_failed_network>

(V) An attempt to confirm the positive assertion via direct contact (check_authentication) with the provider failed with no response or a bad status code (!= 200).

=item C<naive_verify_failed_return>

(V) An attempt to confirm a positive assertion via direct contact (check_authentication) received an explicitly negative response (C<openid.is_valid = FALSE>).

=back

=back

=head1 PROTOCOL VARIANCES

XRI-based identities are not supported.

Meanwhile, here are answers to the security profile questions from L<section 15.6 of the OpenID 2.0 specification|http://openid.net/specs/openid-authentication-2_0.html#anchor47> that are relevant to the Consumer/Relying-Party:

=over

=item 1.

I<Are wildcards allowed in realms?>
B<Yes.>

=item 2.

N/A.

=item 3.

I<Types of claimed identifiers accepted.>
B<HTTP or HTTPS>

=item 4.

I<Are self-issued certificates allowed for authentication?>
B<Depends entirely on the user agent (C<ua>) supplied.  L<LWP::UserAgent|LWP::UserAgent>, as of version 6.0, can be configured to only accept connections to sites with certificates deriving from a set of trusted roots.>

=item 5.

I<Must the XRDS file be signed?>  B<No.>

=item 6.

I<Must the XRDS file be retrieved over secure channel?>  B<No.>

=item 7.

I<What types of session types can be used when creating associations?>  B<Any of C<no-encryption>,C<DH-SHA1>,C<DH-SHA256>>

=item 8.

N/A.

=item 9.

N/A.

=item 10.

I<Must the association request take place over a secure channel?>  B<If the session type is C<no-encryption>, then Yes for version 2.0 providers and likewise for version 1.1 providers if C<allow_eavesdropping> is not set, otherwise No.>

=back

=head1 COPYRIGHT

This module is Copyright (c) 2005 Brad Fitzpatrick.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
If you need more liberal licensing terms, please contact the
maintainer.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 MAILING LIST

The Net::OpenID family of modules has a mailing list powered
by Google Groups. For more information, see
L<http://groups.google.com/group/openid-perl>.

=head1 SEE ALSO

OpenID website: L<http://openid.net/>

L<Net::OpenID::ClaimedIdentity> -- part of this module

L<Net::OpenID::VerifiedIdentity> -- part of this module

L<Net::OpenID::Server> -- another module, for implementing an OpenID identity provider/server

=head1 AUTHORS

Brad Fitzpatrick <brad@danga.com>

Tatsuhiko Miyagawa <miyagawa@sixapart.com>

Martin Atkins <mart@degeneration.co.uk>

Robert Norris <rob@eatenbyagrue.org>

Roger Crew <crew@cs.stanford.edu>
