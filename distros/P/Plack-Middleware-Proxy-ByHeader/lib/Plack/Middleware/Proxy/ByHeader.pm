package Plack::Middleware::Proxy::ByHeader;
use strict;
use warnings;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw(header allowed);
use Plack::Request;
use Carp qw(croak);

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    $self->header( ['Host'] ) if !defined $self->header;
    $self->allowed( [] ) if !defined $self->allowed;

    croak("argument to 'allowed' must be an array reference")
      if not( ref( $self->allowed ) eq 'ARRAY' );

    croak("argument to 'header' must be an array reference")
      if not( ref( $self->header ) eq 'ARRAY' );

    return;
}

sub call {
    my ( $self, $env ) = @_;

    my $req  = Plack::Request->new($env);
    my $uri  = $req->uri;

    my $host;
    for my $header ( @{$self->header} ) {
	$host = $req->header($header);
	last if $host;
    }

    if ($host) {
	my $host = (split(/\s*,\s*/,$host))[-1];

        my $allow = 1;
        if ( @{ $self->allowed } ) {
            my %allowed = map { $_ => 1 } @{ $self->allowed };
            $allow = 0 if not $allowed{$host};
        }

        if ($allow) {
            $uri->host($host);
            $env->{'plack.proxy.url'} = $uri;
        }
    }
    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::Proxy::ByHeader - choose remote host by header

=head1 SYNOPSIS

  my $app = builder {
    enable "Proxy::ByHeader", 
        header  => [ 'X-Taz-Proxy-To', 'Host' ];
        allowed => [ 'example.com', 'www.example.com', 'www2.example.com' ];

    Plack::App::Proxy->new()->to_app;
  }

=head1 DESCRIPTION

Plack::Middleware::Proxy::ByHeader examines the request header to set
the special environment variable I<plack.proxy.url> which is used by
Plack::App::Proxy to proxy the request.

If any of the header field names set with the option I<header> is present
in the request and if its value matches one of the allowed values,
I<plack.proxy.url> is set to the request uri with the hostname changed
to the value of the header field.

The first present header short circuits the check even its value is not
allowed. In this case the request is left unchanged.

If multiple headers with the same field name are present, the last
value is used.

=head1 ATTRIBUTES

=over 4

=item header

An array reference of headers to check. Defaults to the I<HOST> header.

=item allowed

An array reference of allowed remote hosts. The hosts has to match
perfectly, subdomains or wildcards are not possible. Defaults to an
empty array reference which has the special meaning of allowing every
remote target.

=back

=head1 SEE ALSO

L<Plack::App::Proxy>

=head1 AUTHOR

Mario Domgoergen L<E<lt>mario@domgoergen.comE<gt>>

