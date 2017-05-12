use strict;
use Carp ();

############################################################################
package Net::OpenID::Association;
$Net::OpenID::Association::VERSION = '1.18';
use fields (
            'server',    # author-identity identity provider endpoint
            'secret',    # the secret for this association
            'handle',    # the 255-character-max ASCII printable handle (33-126)
            'expiry',    # unixtime, adjusted, of when this association expires
            'type',      # association type
            );

use Storable ();
use Digest::SHA ();
use Net::OpenID::Common;
use URI::Escape qw(uri_escape);

################################################################
# Association and Session Types

# session type hash
#    name  - by which session type appears in URI parameters (required)
#    len   - number of bytes in digest (undef => accommodates any length)
#    fn    - DH hash function (undef => secret passed in the clear)
#    https - must use encrypted connection (boolean)
#
my %_session_types = ();
# {versionkey}{name} -> session type
# {NO}{versionkey}   -> no-encryption stype for this version
# {MAX}{versionkey}  -> strongest encryption stype for this version

# association type hash
#    name  - by which assoc. type appears in URI parameters (required)
#    len   - number of bytes in digest (required)
#    macfn - MAC hash function (required)
#
my %_assoc_types   = ();
# {versionkey}{name} -> association type
# {MAX}{versionkey}  -> strongest encryption atype for this version

my %_assoc_macfn   = ();
# {name} -> hmac function
# ... since association types in the cache are only listed by name
# and don't say what version they're from.  Which should not matter
# as long as the macfn associated with a given association type
# name does not change in future versions.

# (floating point version numbers scare me)
# (also version key can stay the same if the
#  set of hash functions available does not change)
# ('NO' and 'MAX' should never be used as version keys)
sub _version_key_from_numeric {
    my ($numeric_protocol_version) = @_;
    return $numeric_protocol_version < 2 ? 'v1' : 'v2';
}
# can SESSION_TYPE be used with ASSOC_TYPE?
sub _compatible_stype_atype {
    my ($s_type, $a_type) = @_;
    return !$s_type->{len} || $s_type->{len} == $a_type->{len};
}

{
    # Define the no-encryption session types.
    # In version 1.1/1.0, the no-encryption session type
    # is the default and never explicitly specified
    $_session_types{$_->[0]}{$_->[1]}
      = $_session_types{NO}{$_->[0]}
        = {
           name => $_->[1],
           https => 1,
          }
          foreach ([v1 => ''], [v2 => 'no-encryption']);

    # Define SHA-based session and association types
    my %_sha_fns =
      (
       SHA1   => { minv  => 'v1', # first version group in which this appears
                   v1max => 1,    # best encryption for v1
                   len   => 20,   # number of bytes in digest
                   fn    => \&Digest::SHA::sha1,
                   macfn => \&Digest::SHA::hmac_sha1,  },
       SHA256 => { minv  => 'v2',
                   v2max => 1,  # best encryption for v2
                   len   => 32,
                   fn    => \&Digest::SHA::sha256,
                   macfn => \&Digest::SHA::hmac_sha256,  },
       # doubtless there will be more...
      );
    foreach my $SHAX (keys %_sha_fns) {
        my $s = $_sha_fns{$SHAX};
        my $a_type = { name => "HMAC-${SHAX}", map {$_,$s->{$_}} qw(len macfn) };
        my $s_type = { name => "DH-${SHAX}",   map {$_,$s->{$_}} qw(len fn) };
        my $seen_minv = 0;
        foreach my $v (qw(v1 v2)) {
            $seen_minv = 1 if $v eq $s->{minv};
            next unless $seen_minv;
            $_assoc_types{$v}{$a_type->{name}} = $a_type;
            $_session_types{$v}{$s_type->{name}} = $s_type;
            if ($s->{"${v}max"}) {
                $_assoc_types{MAX}{$v} = $a_type;
                $_session_types{MAX}{$v} = $s_type;
            }
        }
        $_assoc_macfn{$a_type->{name}} = $a_type->{macfn};
    }
}
################################################################

sub new {
    my Net::OpenID::Association $self = shift;
    $self = fields::new( $self ) unless ref $self;
    my %opts = @_;
    for my $f (qw( server secret handle expiry type )) {
        $self->{$f} = delete $opts{$f};
    }
    Carp::croak("unknown options: " . join(", ", keys %opts)) if %opts;
    return $self;
}

sub handle {
    my $self = shift;
    die if @_;
    $self->{'handle'};
}

sub secret {
    my $self = shift;
    die if @_;
    $self->{'secret'};
}

sub type {
    my $self = shift;
    die if @_;
    $self->{'type'};
}

sub generate_signature {
    my Net::OpenID::Association $self = shift;
    my $string = shift;
    return OpenID::util::b64($_assoc_macfn{$self->type}->($string, $self->secret));
}

sub server {
    my Net::OpenID::Association $self = shift;
    Carp::croak("Too many parameters") if @_;
    return $self->{server};
}

sub expired {
    my Net::OpenID::Association $self = shift;
    return time() > $self->{'expiry'};
}

sub usable {
    my Net::OpenID::Association $self = shift;
    return 0 unless $self->{'handle'} =~ /^[\x21-\x7e]{1,255}$/;
    return 0 unless $self->{'expiry'} =~ /^\d+$/;
    return 0 unless $self->{'secret'};
    return 0 if $self->expired;
    return 1;
}


# server_assoc(CSR, SERVER, FORCE_REASSOCIATE, OPTIONS...)
#
# Return an association for SERVER (provider), whether already
# cached and not yet expired, or freshly negotiated.
# Return undef if no local storage/cache is available
# or negotiation fails for whatever reason,
# in which case the caller goes into dumb consumer mode.
# FORCE_REASSOCIATE true => ignore the cache
# OPTIONS... are passed to new_server_assoc()
#
sub server_assoc {
    my ($csr, $server, $force_reassociate, @opts) = @_;

    # closure to return undef (dumb consumer mode) and log why
    my $dumb = sub {
        $csr->_debug("server_assoc: dumb mode: $_[0]");
        return undef;
    };

    my $cache = $csr->cache;
    return $dumb->("no_cache") unless $cache;

    unless ($force_reassociate) {
        # try first from cached association handle
        if (my $handle = $cache->get("shandle:$server")) {
            my $assoc = handle_assoc($csr, $server, $handle);

            if ($assoc && $assoc->usable) {
                $csr->_debug("Found association from cache (handle=$handle)");
                return $assoc;
            }
        }
    }

    # make a new association
    my ($assoc, $err, $retry) = new_server_assoc($csr, $server, @opts);
    return $dumb->($err)
      if $err;
    ($assoc, $err) = new_server_assoc($csr, $server, @opts, %$retry)
      if $retry;
    return $dumb->($err || 'second_retry')
      unless $assoc;

    my $ahandle = $assoc->handle;
    $cache->set("hassoc:$server:$ahandle", Storable::freeze({%$assoc}));
    $cache->set("shandle:$server", $ahandle);

    # now we test that the cache object given to us actually works.  if it
    # doesn't, it'll also fail later, making the verify fail, so let's
    # go into stateless (dumb mode) earlier if we can detect this.
    $cache->get("shandle:$server")
        or return $dumb->("cache_broken");

    return $assoc;
}

# new_server_assoc(CSR, SERVER, OPTIONS...)
#
# Attempts to negotiate a fresh association from C<$server> (provider)
# with session and association types determined by OPTIONS...
# (accepts protocol_version and all assoc_options from Consumer,
#  however max_encrypt and session_no_encrypt_https are ignored
#  if assoc_type and session_type are passed directly as hashes)
# Returns
#   ($association) on success
#   (undef, $error_message) on unrecoverable failure
#   (undef, undef, {retry...}) if identity provider suggested
#     alternate session/assoc types in an error response
#
sub new_server_assoc {
    my ($csr, $server, %opts) = @_;
    my $server_is_https = lc($server) =~ m/^https:/;
    my $protocol_version = delete $opts{protocol_version} || 1;
    my $version_key = _version_key_from_numeric($protocol_version);
    my $allow_eavesdropping = (delete $opts{allow_eavesdropping} || 0) && $protocol_version < 2;

    my $a_maxencrypt = delete $opts{max_encrypt} || 0;
    my $s_noencrypt  = delete $opts{session_no_encrypt_https} && $server_is_https;

    my $s_type = delete $opts{session_type} || "DH-SHA1";
    unless (ref $s_type) {
        if ($s_noencrypt) {
            $s_type = $_session_types{NO}{$version_key};
        }
        elsif ($a_maxencrypt) {
            $s_type = $_session_types{MAX}{$version_key};
        }
    }

    my $a_type = delete $opts{assoc_type} || "HMAC-SHA1";
    unless (ref $a_type) {
        $a_type = $_assoc_types{MAX}{$version_key}
          if $a_maxencrypt;
    }

    Carp::croak("unknown options: " . join(", ", keys %opts)) if %opts;

    $a_type = $_assoc_types{$version_key}{$a_type} unless ref $a_type;
    Carp::croak("unknown association type") unless $a_type;

    $s_type = $_session_types{$version_key}{$s_type} unless ref $s_type;
    Carp::croak("unknown session type") unless $s_type;

    my $error = sub { return (undef, $_[0].($_[1]?" ($_[1])":'')); };

    return $error->("incompatible_session_type")
      unless _compatible_stype_atype($s_type, $a_type);

    return $error->("https_required")
      if $s_type->{https} && !$server_is_https && !$allow_eavesdropping;

    my %post = ( "openid.mode" => "associate" );
    $post{'openid.ns'} = OpenID::util::version_2_namespace()
      if $protocol_version == 2;
    $post{'openid.assoc_type'} = $a_type->{name};
    $post{'openid.session_type'} = $s_type->{name} if $s_type->{name};

    my $dh;
    if ($s_type->{fn}) {
        $dh = OpenID::util::get_dh();
        $post{'openid.dh_consumer_public'} = OpenID::util::int2arg($dh->pub_key);
    }

    my $req = HTTP::Request->new(POST => $server);
    $req->header("Content-Type" => "application/x-www-form-urlencoded");
    $req->content(join("&", map { "$_=" . uri_escape($post{$_}) } keys %post));

    $csr->_debug("Associate mode request: " . $req->content);

    my $ua  = $csr->ua;
    my $res = $ua->request($req);

    return $error->("http_no_response") unless $res;

    my $recv_time = time();
    my $content = $res->content;
    my %args = OpenID::util::parse_keyvalue($content);
    $csr->_debug("Response to associate mode: [$content] parsed = " . join(",", %args));

    my $r_a_type = $_assoc_types{$version_key}{$args{'assoc_type'}};
    my $r_s_type = $_session_types{$version_key}{$args{'session_type'}||''};

    unless ($res->is_success) {
        # direct error
        return $error->("http_failure_no_associate")
          if ($protocol_version < 2);
        return $error->("http_direct_error")
          unless $args{'error_code'} eq 'unsupported_type';
        return (undef,undef,{assoc_type => $r_a_type, session_type => $r_s_type})
          if $r_a_type && $r_s_type && ($r_a_type != $a_type || $r_s_type != $s_type);
        return $error->("unsupported_type");
    }
    return $error->("unknown_assoc_type",$args{'assoc_type'})
      unless $r_a_type;
    return $error->("unknown_session_type",$args{'session_type'})
      unless $r_s_type;
    return $error->("wrong_assoc_type",$r_a_type->{name})
      unless $a_type == $r_a_type;
    return $error->("wrong_session_type",$r_s_type->{name})
      unless $s_type == $r_s_type || ($protocol_version < 2);

    # protocol version 1.1
    my $expires_in = $args{'expires_in'};

    # protocol version 1.0 (DEPRECATED)
    if (! $expires_in) {
        if (my $issued = OpenID::util::w3c_to_time($args{'issued'})) {
            my $expiry = OpenID::util::w3c_to_time($args{'expiry'});
            my $replace_after = OpenID::util::w3c_to_time($args{'replace_after'});

            # seconds ahead (positive) or behind (negative) the provider is
            $expires_in = ($replace_after || $expiry) - $issued;
        }
    }

    # between 1 second and 2 years
    return $error->("bogus_expires_in")
      unless $expires_in > 0 && $expires_in < 63072000;

    my $ahandle = $args{'assoc_handle'};

    my $secret;
    unless ($r_s_type->{fn}) {
        $secret = OpenID::util::d64($args{'mac_key'});
    }
    else {
        my $server_pub = OpenID::util::arg2int($args{'dh_server_public'});
        my $dh_sec = $dh->compute_secret($server_pub);
        $secret = OpenID::util::d64($args{'enc_mac_key'})
          ^ $r_s_type->{fn}->(OpenID::util::int2bytes($dh_sec));
    }
    return $error->("bad_secret_length")
      if $r_s_type->{len} && length($secret) != $r_s_type->{len};

    my %assoc = (
                 handle => $ahandle,
                 server => $server,
                 secret => $secret,
                 type   => $r_a_type->{name},
                 expiry => $recv_time + $expires_in,
                 );

    return Net::OpenID::Association->new( %assoc );
}

# returns association, or undef if it can't be found
sub handle_assoc {
    my ($csr, $server, $handle) = @_;

    # closure to return undef (dumb consumer mode) and log why
    my $dumb = sub {
        $csr->_debug("handle_assoc: dumb mode: $_[0]");
        return undef;
    };

    return $dumb->("no_handle") unless $handle;

    my $cache = $csr->cache;
    return $dumb->("no_cache") unless $cache;

    my $frozen = $cache->get("hassoc:$server:$handle");
    return $dumb->("not_in_cache") unless $frozen;

    my $param = eval { Storable::thaw($frozen) };
    return $dumb->("not_a_hashref") unless ref $param eq "HASH";

    return Net::OpenID::Association->new( %$param );
}

sub invalidate_handle {
    my ($csr, $server, $handle) = @_;
    my $cache = $csr->cache
        or return;
    $cache->set("hassoc:$server:$handle", "");
}

1;

__END__

=head1 NAME

Net::OpenID::Association - A relationship with an identity provider

=head1 VERSION

version 1.18

=head1 DESCRIPTION

Internal class.

=head1 COPYRIGHT, WARRANTY, AUTHOR

See L<Net::OpenID::Consumer> for author, copyright and licensing information.

=head1 SEE ALSO

L<Net::OpenID::Consumer>

L<Net::OpenID::VerifiedIdentity>

L<Net::OpenID::Server>

Website:  L<http://openid.net/>
