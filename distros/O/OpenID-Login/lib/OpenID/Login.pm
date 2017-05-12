package OpenID::Login;
{
  $OpenID::Login::VERSION = '0.1.2';
}

# ABSTRACT: A simple lightweight OpenID consumer with very few dependencies

use Moose;
use Moose::Util::TypeConstraints;

use LWP::UserAgent;
use Carp;
use URI::Escape;

use OpenID::Login::Extension;
use OpenID::Login::Types;
use OpenID::Login::Discover;
use OpenID::Login::URI;


my $TIMEOUT = 4;


has claimed_id => (
    is  => 'rw',
    isa => 'Str',
);


has realm => (
    is  => 'rw',
    isa => 'Str',
);


has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new(
            agent => sprintf 'OpenID-Login/%s ',
            __PACKAGE__->VERSION,
            timeout      => $TIMEOUT,
            max_redirect => 0,
        );
    },
);


has return_to => (
    is  => 'rw',
    isa => 'Str',
);


has cgi => (
    is  => 'rw',
    isa => duck_type( ['param'] ),
);


has cgi_params => (
    is  => 'ro',
    isa => 'HashRef'
);


has extensions => (
    is     => 'rw',
    isa    => 'Extension_List',
    coerce => 1,
);


has endpoint => (
    is  => 'rw',
    isa => 'Str',
);


sub get_auth_url {
    my $self = shift;

    my $endpoint = $self->get_openid_endpoint;
    return unless $endpoint;

    #if the endpoint already contains params, put in a param separator ('&') otherwise start params ('?')
    $endpoint .=
        ( $endpoint =~ /\?/ )
        ? '&'
        : '?';
    $endpoint .= $self->_get_request_parameters;

    return $endpoint;
}


sub get_openid_endpoint {
    my $self = shift;

    my $identifier = normalize( $self->claimed_id );
    my $endpoint   = $self->endpoint;
    if ( !$endpoint ) {
        my $discoverer = OpenID::Login::Discover->new( ua => $self->ua, claimed_id => $identifier );
        $endpoint = $discoverer->perform_discovery;
    }
    return $endpoint;
}


sub normalize {
    my ($uri) = @_;

    unless ( $uri =~ /^https?:\/\// ) {
        $uri = sprintf q{http://%s}, $uri;
    }

    $uri =~ s/\#.*$//;    # remove fragment

    $uri = OpenID::Login::URI->normalize($uri);
    return unless OpenID::Login::URI->is_uri($uri);
    my $u = URI->new($uri)->canonical;
    $u->path( $u->path || '/' );
    $u->port(undef) if $u->port == 80 || $u->port == 443;
    $u->fragment(undef);
    return $u->as_string;
}

sub _get_request_parameters {
    my $self = shift;

    croak 'No return_to address provided' unless $self->return_to;
    my $params = 'openid.mode=checkid_setup' . '&openid.ns=http://specs.openid.net/auth/2.0' . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select' . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select' . '&openid.return_to=' . $self->return_to;

    if ( my $realm = $self->realm ) {
        $params .= '&openid.realm=' . $realm;
    }

    my $extensions = $self->extensions;
    if ( $extensions && %$extensions ) {
        $params .= '&' . $_->get_parameter_string() foreach map { $extensions->{$_} } sort keys %$extensions;
    }

    return $params;
}


sub verify_auth {
    my $self = shift;

    return if $self->_get_param('openid.mode') eq 'cancel';

    my $return_to       = $self->return_to;
    my $param_return_to = $self->_get_param('openid.return_to');
    croak 'Return_to value must be set for validation purposes' unless $return_to;
    croak sprintf q{Return_to parameter (%s) doesn't match provided value(%s)}, $param_return_to, $return_to unless $param_return_to eq $return_to;

    my $claimed_id       = $self->claimed_id;
    my $param_claimed_id = $self->_get_param('openid.claimed_id');
    if ( !$claimed_id ) {
        $self->claimed_id($param_claimed_id);
    } elsif ( $claimed_id ne $param_claimed_id ) {
        carp "Identity from parameters ($param_claimed_id) is not the same as the previously set claimed identity ($claimed_id); using the parameter version.";
        $self->claimed_id($param_claimed_id);
    }

    my $verify_endpoint = $self->get_openid_endpoint;
    $verify_endpoint .=
        ( $verify_endpoint =~ /\?/ )
        ? '&'
        : '?';
    $verify_endpoint .= join '&', map {
        my $param = $_;
        my $val   = $self->_get_param($param);
        $val = 'check_authentication' if $param eq 'openid.mode';
        sprintf '%s=%s', uri_escape($param), uri_escape($val);
    } $self->_get_param;

    my $ua = $self->ua;

    my $response = $ua->get( $verify_endpoint, Accept => 'text/plain' );
    my $response_data = _parse_direct_response($response);

    croak "Unexpected verification response namespace: $response_data->{ns}" unless $response_data->{ns} eq 'http://specs.openid.net/auth/2.0';

    return unless $response_data->{is_valid} eq 'true';
    return $param_claimed_id;
}

sub _parse_direct_response {
    my $response = shift;

    my $response_content = $response->decoded_content;
    my @lines            = split /\n/, $response_content;
    my %data             = map { my ( $key, $value ) = split /:/, $_, 2; $key => $value } @lines;
    return \%data;
}


sub get_extension {
    my $self = shift;
    my $uri  = shift;

    my $extension;

    my $extensions = $self->extensions;
    if ($extensions) {
        $extension = $extensions->{$uri};
    }

    unless ($extension) {
        $extension = OpenID::Login::Extension->new( uri => $uri, cgi => $self->cgi, cgi_params => $self->cgi_params );
        $self->set_extension($extension) if $extension;
    }
    return $extension;
}


sub set_extension {
    my $self      = shift;
    my $extension = shift;

    my $extensions = $self->extensions || {};
    $extensions->{ $extension->{uri} } = $extension;
    $self->extensions($extensions);
}

sub _get_param {
    my $self  = shift;
    my $param = shift;

    if ( my $cgi = $self->cgi ) {
        if ($param) {
            return $cgi->param($param);
        } else {
            return $cgi->param();
        }
    } elsif ( my $cgi_params = $self->cgi_params ) {
        if ($param) {
            return $cgi_params->{$param};
        } else {
            return keys %$cgi_params;
        }
    } else {
        croak('Neither cgi nor cgi_params attributes have been provided (needed to verify OpenID parameters)');
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

OpenID::Login - A simple lightweight OpenID consumer with very few dependencies

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

Sending user to be authenticated:

  my $claimed_id = 'https://example.openssl.com';
  my $o = OpenID::Login->new(claimed_id => $claimed_id, return_to => 'https://example.com/auth');
  my $auth_url = $o->get_auth_url();

Verifying the user was correctly authenticated:

  my $o = OpenID::Login->new(cgi => $cgi, return_to => 'https://example.com/auth');
  my $id = $o->verify_auth();
  # $id is the verified identity, or false if it wasn't verified (eg by the user handcrafting the url, or disallowing access)

=head1 DESCRIPTION

OpenID::Login is an simple alternative OpenID consumer to L<Net::OpenID::Consumer> with less dependencies especially not to 
L<Crypt::DH::GMP> which itself has dependencies to libgmp, etc. and is sometimes difficult to install.

This module only does XRDS discovery, no YARDIS and will only do OpenID in "dumb" aka stateless mode. 

OpenID::Login is inspired and based on L<Net::Google::FederatedLogin> written by Glenn Fowler.

=head1 ATTRIBUTES

=head2 claimed_id

B<Required for L<"get_auth_url">:> The email address, or an OpenID URL of the identity to be checked.

=head2 realm

Optional field that is used to populate the openid.realm parameter.
If not provided the parameter will not be used (as opposed to being 
calculated from the L<"return_to">" value).

=head2 ua

The useragent internally used for communications that the module needs to do.
If not provided, a new L<LWP::UserAgent> will be instantiated.

=head2 return_to

B<Required for L<"get_auth_url"> and L<"verify_auth">:> The URL the user should be
returned to after verifying their identity.

=head2 cgi

B<Required for L<"verify_auth">:> A CGI-like object (same param() method behaviour)
that is used to access the parameters that assert the identity has been verified. May optionally
be replaced by L<"cgi_params">.

=head2 cgi_params

B<Required for L<"verify_auth"> unless L<"cgi"> is supplied:> A hashref containing the cgi
parameters for verifying the identity.

=head2 extensions

Hashref of L<OpenID::Login::Extension> objects (keyed off the extension type URI).

=head2 endpoint

Static URI of the authorizing OpenID server. If set no XRDS discovery will be done.

=head1 METHODS

=head2 get_auth_url

Gets the URL to send the user to where they can verify their identity.

=head2 get_openid_endpoint

Gets the unadorned OpenID authentication URL (like L<"get_auth_url">, but doesn't contain values specific to
this request (return_to, mode etc))

=head2 normalize

Normalizes and checks the claimed OpenID identifier for synthactical validity.

=head2 verify_auth

Checks if the user has been validated based on the parameters in the L<"cgi"> object,
and checks that these parameters do come from the correct OpenID provider (rather
than having been hand-crafted to appear to validate the identity). If the id is
successfully verified, it is returned (otherwise a false value is returned).

=head2 get_extension

Retrieve a single L<OpenID::Login::Extension> object, based on the type URI provided.
This method is most likely to be useful for handling the response to an OpenID request.

=head2 set_extension

Save an extension into the list of extensions for this login object

=head1 AUTHOR

Holger Eiboeck <realholgi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Holger Eiboeck.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



