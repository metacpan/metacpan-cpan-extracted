package SWISH::Prog::Aggregator::Spider;
use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator );
use Carp;
use Scalar::Util qw( blessed );
use URI;
use HTTP::Cookies;
use HTTP::Date;
use SWISH::Prog::Utils;
use SWISH::Prog::Queue;
use SWISH::Prog::Cache;
use SWISH::Prog::Aggregator::Spider::UA;
use Search::Tools::UTF8;
use XML::Feed;
use WWW::Sitemap::XML;
use File::Rules;

#
# TODO tests for cookies, non-text urls needing filters
#
#

__PACKAGE__->mk_accessors(
    qw(
        agent
        authn_callback
        credential_timeout
        credentials
        delay
        email
        file_rules
        follow_redirects
        keep_alive
        link_tags
        max_depth
        max_files
        max_size
        max_time
        md5_cache
        modified_since
        queue
        remove_leading_dots
        same_hosts
        timeout
        ua
        uri_cache
        use_md5
        )
);

#use LWP::Debug qw(+);

our $VERSION = '0.75';

# TODO make these configurable
my %parser_types = %SWISH::Prog::Utils::ParserTypes;
my $default_ext  = $SWISH::Prog::Utils::ExtRE;
my $utils        = 'SWISH::Prog::Utils';

=pod

=head1 NAME

SWISH::Prog::Aggregator::Spider - web aggregator

=head1 SYNOPSIS

 use SWISH::Prog::Aggregator::Spider;
 my $spider = SWISH::Prog::Aggregator::Spider->new(
     indexer => SWISH::Prog::Indexer->new
 );
 
 $spider->indexer->start;
 $spider->crawl( 'http://swish-e.org/' );
 $spider->indexer->finish;

=head1 DESCRIPTION

SWISH::Prog::Aggregator::Spider is a web crawler similar to
the spider.pl script in the Swish-e 2.4 distribution. Internally,
SWISH::Prog::Aggregator::Spider uses LWP::RobotUA to do the hard work.
See L<SWISH::Prog::Aggregator::Spider::UA>.

=head1 METHODS

See L<SWISH::Prog::Aggregator>.

=head2 new( I<params> )

All I<params> have their own get/set methods too. They include:

=over

=item agent I<string>

Get/set the user-agent string reported by the user agent.

=item email I<string>

Get/set the email string reported by the user agent.

=item use_md5 I<1|0>

Flag as to whether each URI's content should be fingerprinted
and compared. Useful if the same content is available under multiple
URIs and you only want to index it once.

=item uri_cache I<cache_object>

Get/set the SWISH::Prog::Cache-derived object used to track which URIs have
been fetched already.

=item md5_cache I<cache_object>

If use_md5() is true, this SWISH::Prog::Cache-derived object tracks
the URI fingerprints.

=item file_rules I<File_Rules_or_ARRAY>

Apply L<File::Rules> object in uri_ok(). I<File_Rules_or_ARRAY> should
be a L<File::Rules> object or an array of strings suitable to passing
to File::Rules->new().

=item queue I<queue_object>

Get/set the SWISH::Prog::Queue-derived object for tracking which URIs still
need to be fetched.

=item ua I<lwp_useragent>

Get/set the SWISH::Prog::Aggregagor::Spider::UA object.

=item max_depth I<n>

How many levels of links to follow. B<NOTE:> This value describes the number
of links from the first argument passed to I<crawl>.

Default is unlimited depth.

=item max_time I<n>

This optional key will set the max minutes to spider.   Spidering
for this host will stop after C<max_time> seconds, and move on to the
next server, if any.  The default is to not limit by time.

=item max_files I<n>

This optional key sets the max number of files to spider before aborting.
The default is to not limit by number of files.  This is the number of requests
made to the remote server, not the total number of files to index (see C<max_indexed>).
This count is displayted at the end of indexing as C<Unique URLs>.

This feature can (and perhaps should) be use when spidering a web site where dynamic
content may generate unique URLs to prevent run-away spidering.

=item max_size I<n>

This optional key sets the max size of a file read from the web server.
This B<defaults> to 5,000,000 bytes.  If the size is exceeded the resource is
truncated per LWP::UserAgent.

Set max_size to zero for unlimited size.

=item modified_since I<date>

This optional parameter will skip any URIs that do not report having
been modified since I<date>. The C<Last-Modified> HTTP header is used to
determine modification time.

=item keep_alive I<1|0>

This optional parameter will enable keep alive requests.  This can dramatically speed
up spidering and reduce the load on server being spidered.  The default is to not use
keep alives, although enabling it will probably be the right thing to do.

To get the most out of keep alives, you may want to set up your web server to
allow a lot of requests per single connection (i.e MaxKeepAliveRequests on Apache).
Apache's default is 100, which should be good.

When a connection is not closed the spider does not wait the "delay"
time when making the next request.  In other words, there is no delay in
requesting documents while the connection is open.

Note: you must have at least libwww-perl-5.53_90 installed to use this feature.

=item delay I<n>

Get/set the number of seconds to wait between making requests. Default is
5 seconds (a very friendly delay).

=item timeout I<n>

Get/set the number of seconds to wait before considering the remote
server unresponsive. The default is 10.

=item authn_callback I<code_ref>

CODE reference to fetch username/password credentials when necessary. See also
C<credentials>.

=item credential_timeout I<n>

Number of seconds to wait before skipping manual prompt for username/password.

=item credentials I<user:pass>

String with C<username>:C<password> pair to be used when prompted by 
the server.

=item follow_redirects I<1|0>

By default, 3xx responses from the server will be followed when
they are on the same hostname. Set to false (0) to not follow
redirects.

=item link_tags

TODO

=item remove_leading_dots I<1|0>

Microsoft server hack.

=item same_hosts I<array_ref>

ARRAY ref of hostnames to be treated as identical to the original
host being spidered. By default the spider will not follow
links to different hosts.

=back

=head2 init

Initializes a new spider object. Called by new().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # defaults
    $self->{agent} ||= 'swish-prog-spider http://swish-e.org/';
    $self->{email} ||= 'swish@user.failed.to.set.email.invalid';
    $self->{use_cookies}      = 1 unless defined $self->{use_cookies};
    $self->{follow_redirects} = 1 unless defined $self->{follow_redirects};
    $self->{max_files}        = 0 unless defined $self->{max_files};
    $self->{max_size}  = 5_000_000 unless defined $self->{max_size};
    $self->{max_depth} = undef     unless defined( $self->{max_depth} );
    $self->{delay}     = 5         unless defined $self->{delay};
    croak "delay must be expressed in seconds" if $self->{delay} =~ m/\D/;

    if ( $self->{modified_since} ) {
        my $epoch
            = $self->{modified_since} =~ m/\D/
            ? str2time( $self->{modified_since} )
            : $self->{modified_since};

        if ( !defined $epoch ) {
            croak
                "Invalid datetime in modified_since: $self->{modified_since}";
        }
        $self->{modified_since} = $epoch;
    }

    $self->{credential_timeout} = 30
        unless exists $self->{credential_timeout};
    croak "credential_timeout must be a number"
        if defined $self->{credential_timeout}
        and $self->{credential_timeout} =~ m/\D/;

    $self->{queue}     ||= SWISH::Prog::Queue->new;
    $self->{uri_cache} ||= SWISH::Prog::Cache->new;
    $self->{_auth_cache} = SWISH::Prog::Cache->new;    # ALWAYS inmemory cache
    $self->{ua} ||= SWISH::Prog::Aggregator::Spider::UA->new( $self->{agent},
        $self->{email}, );

    # whitelist which HTML tags we consider "links"
    # should be subset of what HTML::LinkExtor considers links
    $self->{link_tags} = [ 'a', 'frame', 'iframe' ]
        unless ref $self->{link_tags} eq 'ARRAY';
    $self->{ua}
        ->set_link_tags( { map { lc($_) => 1 } @{ $self->{link_tags} } } );

    $self->{timeout} = 10 unless defined $self->{timeout};
    croak "timeout must be a number" if $self->{timeout} =~ m/\D/;

    # we handle our own delay
    $self->{ua}->delay(0);

    $self->{ua}->timeout( $self->{timeout} );

    # TODO we test this using HEAD request. Set here too?
    #$self->{ua}->max_size( $self->{max_size} ) if $self->{max_size};

    if ( $self->{use_cookies} ) {
        $self->{ua}->cookie_jar( HTTP::Cookies->new() );
    }
    if ( $self->{keep_alive} ) {
        if ( $self->{ua}->can('conn_cache') ) {
            my $keep_alive
                = $self->{keep_alive} =~ m/^\d+$/
                ? $self->{keep_alive}
                : 1;
            $self->{ua}->conn_cache( { total_capacity => $keep_alive } );
        }
        else {
            warn
                "can't use keep-alive: conn_cache() method not available on ua "
                . ref( $self->{ua} );
        }
    }

    $self->{_current_depth} = 1;

    $self->{same_hosts} ||= [];
    $self->{same_host_lookup} = { map { $_ => 1 } @{ $self->{same_hosts} } };

    if ( $self->{use_md5} ) {
        eval "require Digest::MD5" or croak $@;
        $self->{md5_cache} ||= SWISH::Prog::Cache->new;
    }

    # if SWISH::Prog::Config defined, use that for some items
    if ( $self->{indexer} and $self->config ) {
        if ( $self->config->FileRules && !$self->{file_rules} ) {
            $self->{file_rules}
                = File::Rules->new( $self->config->FileRules );
        }
    }

    # make it an object if it is just an array
    if ( $self->{file_rules} and !blessed( $self->{file_rules} ) ) {
        $self->{file_rules} = File::Rules->new( $self->{file_rules} );
    }

    # from spider.pl. not sure if we need it or not.
    # Lame Microsoft
    $URI::ABS_REMOTE_LEADING_DOTS = $self->{remove_leading_dots} ? 1 : 0;

    return $self;
}

=head2 uri_ok( I<uri> )

Returns true if I<uri> is acceptable for including in an index.
The 'ok-ness' of the I<uri> is based on its base, robot rules,
and the spider configuration.

=cut

sub uri_ok {
    my $self = shift;
    my $uri  = shift or croak "URI required";
    my $str  = $uri->canonical->as_string;
    $str =~ s/#.*//;    # target anchors create noise

    if ( $self->verbose > 1 || $self->debug ) {
        $self->write_log_line();
        $self->write_log(
            uri => $uri,
            msg => "checking if ok",
        );
    }

    if ( $uri->scheme !~ m,^http, ) {
        $self->debug and $self->write_log(
            uri => $uri,
            msg => "skipping, unsupported scheme"
        );
        return 0;
    }

    # check if we're on the same host.
    if ( $uri->rel( $self->{_base} ) eq $uri ) {

        # not on this host. check our aliases
        if ( !exists $self->{same_host_lookup}
            ->{ $uri->canonical->authority || '' } )
        {
            my $host = $uri->canonical->authority;
            $self->debug
                and $self->write_log(
                uri => $uri,
                msg => "skipping, different host $host",
                );
            return 0;
        }

        # in same host lookup, so proceed.
    }

    my $path = $uri->path;
    my $mime = $utils->mime_type($path);

    if ( !exists $parser_types{$mime} ) {
        $self->debug and $self->write_log(
            uri => $uri,
            msg => "skipping, no parser for $mime",
        );
        return 0;
    }

    # check regex
    if ( $self->file_rules ) {

        if ( $self->_apply_file_rules( $uri->path_query, $self->file_rules )
            && !$self->_apply_file_match( $uri->path_query,
                $self->file_rules ) )
        {
            $self->debug and $self->write_log(
                uri => $uri,
                msg => "skipping, matched file_rules",
            );
            return 0;
        }
    }

    # head request to check max_size and modified_since
    if ( $self->max_size or $self->modified_since ) {
        my %head_args = (
            uri     => $uri,
            delay   => 0,                # assume each get() applies the delay
            debug   => $self->debug,
            verbose => $self->verbose,
        );

        if ( my ( $user, $pass ) = $self->_get_user_pass($uri) ) {
            $head_args{user} = $user;
            $head_args{pass} = $pass;
        }
        my $resp = $self->ua->head(%head_args);

        # early abort if resource doesn't exist
        if ( $resp->status == 404 ) {
            $self->debug
                and $self->write_log(
                uri => $uri,
                msg => "skipping, 404 not found",
                );
            return 0;
        }

        # redirect? assume ok now and _make_request will check on it later.
        if ( $resp->is_redirect ) {
            $self->debug
                and $self->write_log(
                uri => $uri,
                msg => "deferring, is_redirect",
                );
            return 1;
        }

        my $last_mod = $resp->last_modified;
        if (    $last_mod
            and $self->modified_since
            and $self->modified_since > $last_mod )
        {
            $self->debug
                and $self->write_log(
                uri => $uri,
                msg => sprintf(
                    "skipping, last modified %s (%s < %s)",
                    $resp->header('last-modified'), $last_mod,
                    $self->modified_since
                ),
                );
            return 0;
        }

        if ( $resp->content_length and $self->max_size ) {
            if ( $resp->content_length > $self->max_size ) {
                $self->debug
                    and $self->write_log(
                    uri => $uri,
                    msg => sprintf( "skipping, %s > max_size",
                        $resp->content_length ),
                    );
                return 0;
            }
        }

    }

    ( $self->verbose > 1 || $self->debug ) and $self->write_log(
        uri => $uri,
        msg => "ok",
    );
    return 1;
}

sub _add_links {
    my ( $self, $parent, @links ) = @_;

    # calc depth
    if ( !$self->{_parent} || $self->{_parent} ne $parent ) {
        $self->{_current_depth}++;
    }

    $self->{_parent} ||= $parent;    # first time.

    $self->debug and $self->write_log(
        uri => $parent,
        msg => sprintf( 'evaluating %s links', scalar(@links) ),
    );

    for my $l (@links) {
        my $uri = $l->abs( $self->{_base} ) or next;
        $uri = $uri->canonical;      # normalize
        if ( $self->uri_cache->has("$uri") ) {
            $self->debug and $self->write_log(
                uri => $uri,
                msg => "skipping, already checked",
            );
            next;
        }
        $self->uri_cache->add( "$uri" => $self->{_current_depth} );

        if ( $self->uri_ok($uri) ) {
            $self->add_to_queue($uri);
        }
    }
}

# ported from spider.pl
# Do we need to authorize?  If so, ask for password and request again.
# First we try using any cached value
# Then we try using the get_password callback
# Then we ask.

sub _authorize {
    my ( $self, $uri, $response ) = @_;

    delete $self->{last_auth};    # since we know that doesn't work

    if (   $response->header('WWW-Authenticate')
        && $response->header('WWW-Authenticate') =~ /realm="([^"]+)"/i )
    {
        my $realm = $1;
        my $user_pass;

        # Do we have a cached user/pass for this realm?
        # only each URI only once
        unless ( $self->{_request}->{auth}->{$uri}++ ) {
            my $key = $uri->canonical->host_port . ':' . $realm;

            if ( $user_pass = $self->{_auth_cache}->get($key) ) {

                # If we didn't just try it, try again
                unless ( $uri->userinfo && $user_pass eq $uri->userinfo ) {

                    # add the user/pass to the URI
                    $uri->userinfo($user_pass);

                   #warn " >> set userinfo via _auth_cache\n" if $self->debug;
                    return 1;
                }
                else {
                    # we've tried this before
                    #warn "tried $user_pass before";
                    return 0;
                }
            }
        }

        # now check for a callback password (if $user_pass not set)
        unless ( $user_pass || $self->{_request}->{auth}->{callback}++ ) {

            # Check for a callback function
            if ( $self->{authn_callback}
                and ref $self->{authn_callback} eq 'CODE' )
            {
                $user_pass = $self->{authn_callback}
                    ->( $self, $uri, $response, $realm );
                $uri->userinfo($user_pass);

                #warn " >> set userinfo via authn_callback\n" if $self->debug;
                return 1;
            }
        }

        # otherwise, prompt (over and over)
        if ( !$user_pass ) {
            $user_pass = $self->_get_basic_credentials( $uri, $realm );
        }

        if ($user_pass) {
            $uri->userinfo($user_pass);
            $self->{cur_realm} = $realm;  # save so we can cache if it's valid
            return 1;
        }
    }

    return 0;

}

# From spider.pl
sub _get_basic_credentials {
    my ( $self, $uri, $realm ) = @_;

    # Exists but undefined means don't ask.
    return
        if exists $self->{credential_timeout}
        && !defined $self->{credential_timeout};

    my $netloc = $uri->canonical->host_port;

    my ( $user, $password );

    eval {
        local $SIG{ALRM} = sub { die "timed out\n" };

        # a zero timeout means don't time out
        alarm( $self->{credential_timeout} ) unless $^O =~ /Win32/i;

        if ( $uri->userinfo ) {
            print STDERR "\nSorry: invalid username/password\n";
            $uri->userinfo(undef);
        }

        print STDERR
            "Need Authentication for $uri at realm '$realm'\n(<Enter> skips)\nUsername: ";
        $user = <STDIN>;
        chomp($user) if $user;
        die "No Username specified\n" unless length $user;

        alarm( $self->{credential_timeout} ) unless $^O =~ /Win32/i;

        print STDERR "Password: ";
        system("stty -echo");
        $password = <STDIN>;
        system("stty echo");
        print STDERR "\n";    # because we disabled echo
        chomp($password);
        alarm(0) unless $^O =~ /Win32/i;
    };

    alarm(0) unless $^O =~ /Win32/i;

    return if $@;

    return join ':', $user, $password;

}

=head2 add_to_queue( I<uri> )

Add I<uri> to the queue.

=cut

sub add_to_queue {
    my $self = shift;
    my $uri = shift or croak "uri required";
    return $self->queue->put($uri);
}

=head2 next_from_queue

Return next I<uri> from queue.

=cut

sub next_from_queue {
    my $self = shift;
    return $self->queue->get();
}

=head2 left_in_queue

Returns queue()->size().

=cut

sub left_in_queue {
    return shift->queue->size();
}

=head2 remove_from_queue( I<uri> )

Calls queue()->remove(I<uri>).

=cut

sub remove_from_queue {
    my $self = shift;
    my $uri = shift or croak "uri required";
    return $self->queue->remove($uri);
}

=head2 get_doc

Returns the next URI from the queue() as a SWISH::Prog::Doc object,
or the error message if there was one.

Returns undef if the queue is empty or max_depth() has been reached.

=cut

sub get_doc {
    my $self = shift;

    # return unless we have something in the queue
    return unless $self->left_in_queue();

    # pop the queue and make it a URI
    my $uri   = $self->next_from_queue();
    my $depth = $self->uri_cache->get("$uri");

    $self->debug
        and $self->write_log(
        uri => $uri,
        msg => sprintf(
            "depth:%d max_depth:%s",
            $depth, ( $self->max_depth || 'undef' )
        ),
        );

    return if defined $self->max_depth && $depth > $self->max_depth;

    $self->{_cur_depth} = $depth;

    my $doc = $self->_make_request($uri);

    if ($doc) {
        $self->remove_from_queue($uri);
    }

    return $doc;
}

=head2 get_authorized_doc( I<uri>, I<response> )

Called internally when the server returns a 401 or 403 response.
Will attempt to determine the correct credentials for I<uri>
based on the previous attempt in I<response> and what you 
have configured in B<credentials>, B<authn_callback> or when
manually prompted.

=cut

sub get_authorized_doc {
    my $self     = shift;
    my $uri      = shift or croak "uri required";
    my $response = shift or croak "response required";

    # set up credentials
    $self->_authorize( $uri, $response->http_response ) or return;

    return $self->_make_request($uri);
}

sub _make_request {
    my ( $self, $uri ) = @_;

    # get our useragent
    my $ua    = $self->ua;
    my $delay = 0;
    if ( $self->{keep_alive} ) {
        $delay = 0;
    }
    elsif ( !$self->{delay} or !$self->{_last_response_time} ) {
        $delay = 0;
    }
    else {
        my $elapsed = time() - $self->{_last_response_time};
        $delay = $self->{delay} - $elapsed;
        $delay = 0 if $delay < 0;
        $self->debug
            and $self->write_log(
            uri => $uri,
            msg => "elapsed:$elapsed delay:$delay",
            );
    }

    $self->write_log(
        uri => $uri,
        msg => "GET delay:$delay",
    ) if $self->verbose;

    my %get_args = (
        uri     => $uri,
        delay   => $delay,
        debug   => $self->debug,
        verbose => $self->verbose,
    );

    if ( my ( $user, $pass ) = $self->_get_user_pass($uri) ) {
        $get_args{user} = $user;
        $get_args{pass} = $pass;
    }

    # fetch the uri. $ua handles delay internally.
    my $response      = $ua->get(%get_args);
    my $http_response = $response->http_response;

    # flag current time for next delay calc.
    $self->{_last_response_time} = time();

    # redirect? follow, conditionally.
    if ( $response->is_redirect ) {
        my $location = $response->header('location');
        if ( !$location ) {
            $self->write_log(
                uri => $uri,
                msg => "skipping, redirect without a Location header",
            );
            return $response->status;
        }
        $self->debug
            and $self->write_log(
            uri => $uri,
            msg => "redirect: $location",
            );
        if ( $self->follow_redirects ) {
            $self->_add_links( $uri,
                URI->new_abs( $location, $http_response->base ) );
        }
        return $response->status;
    }

    if ( $response->ct ) {
        $self->debug and $self->write_log(
            uri => $uri,
            msg => 'content-type: ' . $response->ct,
        );
    }

    # add its links to the queue.
    # If the resource looks like an XML feed of some kind,
    # glean its links differently than if it is an HTML response.
    if ( my $feed = $self->looks_like_feed($http_response) ) {
        $self->debug and $self->write_log(
            uri => $uri,
            msg => 'looks like feed'
        );
        my @links;
        for my $entry ( $feed->entries ) {
            push @links, URI->new( $entry->link );
        }
        $self->_add_links( $uri, @links );

        # we don't want the feed content, we want the links.
        # TODO make this optional
        return $response->status;
    }
    elsif ( my $sitemap = $self->looks_like_sitemap($http_response) ) {
        $self->debug and $self->write_log(
            uri => $uri,
            msg => 'looks like sitemap',
        );
        my @links;
        for my $url ( $sitemap->urls ) {
            push @links, URI->new( $url->loc );
        }
        $self->_add_links( $uri, @links );

        # we don't want the feed content, we want the links.
        # TODO make this optional
        return $response->status;
    }
    else {
        $self->_add_links( $uri, $response->links );
    }

    # return $uri as a Doc object
    my $use_uri = $response->success ? $ua->uri : $uri;
    my $meta = {
        org_uri => $uri,
        ret_uri => ( $use_uri || $uri ),
        depth   => delete $self->{_cur_depth},
        status  => $response->status,
        success => $response->success,
        is_html => $response->is_html,
        title   => (
            $response->success
            ? ( $response->is_html
                ? ( $response->title || "No title: $use_uri" )
                : $use_uri
                )
            : "Failed: $use_uri"
        ),
        ct => ( $response->success ? $response->ct : "Unknown" ),
    };

    my $headers = $http_response->headers;
    my $buf     = $response->content;

    if ( $self->{use_md5} ) {
        my $fingerprint = $response->header('Content-MD5')
            || Digest::MD5::md5_base64($buf);
        if ( $self->md5_cache->has($fingerprint) ) {
            return "duplicate content for "
                . $self->md5_cache->get($fingerprint);
        }
        $self->md5_cache->add( $fingerprint => $uri );
    }

    if ( $response->success ) {

        my $content_type = $meta->{ct};
        if ( !exists $parser_types{$content_type} ) {
            $self->write_log(
                uri => $uri,
                msg => "no parser for $content_type",
            );
        }
        my $charset = $headers->content_type;
        $charset =~ s/;?$meta->{ct};?//;
        my $encoding = $headers->content_encoding || $charset;
        my %doc = (
            url     => $meta->{org_uri},
            modtime => ( $headers->last_modified || $headers->date ),
            type    => $meta->{ct},
            content => ( $encoding =~ m/utf-8/i ? to_utf8($buf) : $buf ),
            size => $headers->content_length || length( pack 'C0a*', $buf ),
            charset => $encoding,
        );

        # cache whatever credentials were used so we can re-use
        if ( $self->{cur_realm} and $uri->userinfo ) {
            my $key = $uri->canonical->host_port . ':' . $self->{cur_realm};
            $self->{_auth_cache}->add( $key => $uri->userinfo );

            # not too sure of the best logic here
            my $path = $uri->path;
            $path =~ s!/[^/]*$!!;
            $self->{last_auth} = {
                path => $path,
                auth => $uri->userinfo,
            };
        }

        # return doc
        return $self->doc_class->new(%doc);

    }
    elsif ( $response->status == 401 ) {

        # authorize and try again
        $self->write_log(
            uri => $uri,
            msg => sprintf( "authn denied, retrying, %s",
                $response->status_line ),
        );
        return $self->get_authorized_doc( $uri, $response )
            || $response->status;
    }
    elsif ($response->status == 403
        && $http_response->status_line =~ m/robots.txt/ )
    {

        # ignore
        $self->write_log(
            uri => $uri,
            msg => sprintf( "skipped, %s", $http_response->status_line ),
        );
        return $self->get_authorized_doc( $uri, $response )
            || $response->status;
    }
    elsif ( $response->status == 403 ) {

        # authorize and try again
        $self->write_log(
            uri => $uri,
            msg => sprintf( "retrying, %s", $http_response->status_line ),
        );
        return $self->get_authorized_doc( $uri, $response );
    }
    else {

        $self->write_log(
            uri => $uri,
            msg => $http_response->status_line,
        );
        return $response->status;
    }

    return;    # never get here.
}

sub _get_user_pass {
    my $self = shift;
    my $uri  = shift;

    # Set basic auth if defined - use URI specific first, then credentials.
    # this doesn't track what should have authorization
    my $last_auth;
    if ( $self->{last_auth} ) {
        my $path = $uri->path;
        $path =~ s!/[^/]*$!!;
        $last_auth = $self->{last_auth}->{auth}
            if $self->{last_auth}->{path} eq $path;
    }

    my ( $user, $pass ) = split /:/,
        ( $last_auth || $uri->userinfo || $self->credentials || '' );

    return ( $user, $pass );
}

=head2 looks_like_feed( I<http_response> )

Called internally to perform naive heuristics on I<http_response>
to determine whether it looks like an XML feed of some kind,
rather than a HTML page.

=cut

sub looks_like_feed {
    my $self     = shift;
    my $response = shift or croak "response required";
    my $headers  = $response->headers;
    my $ct       = $headers->content_type;
    if ( $ct eq 'text/html' or $ct eq 'application/xhtml+xml' ) {
        return 0;
    }
    if (   $ct eq 'text/xml'
        or $ct eq 'application/rss+xml'
        or $ct eq 'application/rdf+xml'
        or $ct eq 'application/atom+xml' )
    {
        my $xml = $response->decoded_content;    # TODO or content()
        return XML::Feed->parse( \$xml );
    }

    return 0;
}

=head2 looks_like_sitemap( I<http_response> )

Called internally to perform naive heuristics on I<http_response>
to determine whether it looks like a XML sitemap feed,
rather than a HTML page.

=cut

sub looks_like_sitemap {
    my $self     = shift;
    my $response = shift or croak "response required";
    my $headers  = $response->headers;
    my $ct       = $headers->content_type;
    if ( $ct eq 'text/html' or $ct eq 'application/xhtml+xml' ) {
        return 0;
    }
    if (   $ct eq 'text/xml'
        or $ct eq 'application/xml' )
    {
        my $xml     = $response->decoded_content;    # TODO or content()
        my $sitemap = WWW::Sitemap::XML->new();
        eval { $sitemap->load( string => $xml ); };
        if ($@) {
            return 0;
        }
        return $sitemap;
    }

    return 0;
}

=head2 crawl( I<uri> )

Implements the required crawl() method. Recursively fetches I<uri>
and its child links to a depth set in max_depth(). 

Will quit after max_files() unless max_files==0.

Will quit after max_time() seconds unless max_time==0.

=cut

sub crawl {
    my $self = shift;
    my @urls = @_;

    my $indexer = $self->indexer;    # may be undef

    for my $url (@urls) {
        my $started = time();
        $self->debug and $self->write_log(
            uri => $url,
            msg => "crawling",
        );

        my $uri = URI->new($url)->canonical;
        $self->uri_cache->add( "$uri" => 1 );
        $self->add_to_queue($uri);
        $self->{_base} = $uri->as_string;
        while ( my $doc = $self->get_doc ) {
            $self->debug and $self->write_log_line();
            next unless blessed($doc);

            # indexer not required
            $indexer->process($doc) if $indexer;

            $self->_increment_count;

            # abort if we've met any max_* conditions
            last if $self->max_files and $self->count >= $self->max_files;
            last
                if $self->max_time
                and ( time() - $started ) > $self->max_time;
        }
    }

    return $self->count;
}

=head2 write_log( I<args> )

Passes I<args> to SWISH::Prog::Utils::write_log().

=cut

sub write_log {
    SWISH::Prog::Utils::write_log(@_);
}

=head2 write_log_line([I<char>, I<width>])

Pass through to SWISH::Prog::Utils::write_log_line().

=cut

sub write_log_line {
    SWISH::Prog::Utils::write_log_line(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
