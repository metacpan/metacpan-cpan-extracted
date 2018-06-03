package Plack::Middleware::Auth::FCGI;

use strict;

our $VERSION = '0.02';

use base qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(
  on_reject
  host
  port
  fcgi_auth_params
);

sub prepare_app {
    my ($self) = @_;
    Plack::Util::load_class('FCGI::Client');
}

sub call {
    my ( $self, $env ) = @_;
    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
    ) or die $!;
    $env->{$_} = $self->fcgi_auth_params->{$_}
      foreach ( keys %{ $self->fcgi_auth_params } );
    my $client = FCGI::Client::Connection->new( sock => $sock );
    my ( $stdout, $stderr ) = $client->request($env);
    my $rejApp = $self->on_reject;
    my @lines = split /\r?\n/, $stdout;
    my %hdrs;

    foreach (@lines) {
        if (/^(.*?): (.*)$/) {
            my ( $k, $v ) = ( lc($1), $2 );
            if ( $hdrs{$k} ) {
                $hdrs{$k} = $hdrs{$k} . ",$v";
            }
            else {
                $hdrs{$k} = $v;
            }
        }
    }
    my $code;
    if ( $hdrs{status} =~ /^(\d+)\s+(.*)$/ ) {
        $code = $1;
    }
    else {
        $hdrs{status} ||= '500 Server Error';
        $code = 500;
    }
    if ( $hdrs{location} and $code == 302 or $code == 303 or $code == 401 ) {
        return [ 302, [ Location => $hdrs{location} ], [] ];
    }
    unless ( $code < 300 ) {
        if ($rejApp) {
            return $self->$rejApp( $env, \%hdrs );
        }
        else {
            return [ $code, [%hdrs], [ $hdrs{status} ] ];
        }
    }
    my $app  = $self->app;
    foreach ( keys %hdrs ) {
        $env->{$_} = 'fcgiauth-' . $hdrs{$_} foreach ( keys %hdrs );
    }
    @_ = $env;
    goto $app;
}

1;
__END__

=head1 NAME

Plack::Middleware::Auth::FCGI - authentication middleware that query remote FastCGI server

=head1 SYNOPSIS

  use Plack::Builder;

  my $app   = sub {
    my $env = shift;
    # FastCGI auth response headers are stored in $env->{fcgiauth-<header>}
    # in lower case. Example if FastCGI auth server populates 'Auth-User' header:
    my $user = $env->{fcgiauth-auth-user};
    #...
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $user" ] ];
  };
  
  # Optionally ($fcgiResponse is the PSGI response of remote FCGI auth server)
  #sub on_reject {
  #    my($self,$env,$fcgiResponse) = @_;
  #    my $statusCode = $fcgiResponse->{status};
  #    ...
  #}
  
  builder
  {
    enable "Auth::FCGI",
      host => '127.0.0.1',
      port => '9090',
      # Optional parameters to give to remote FCGI server
      #fcgi_auth_params => {
      #  RULES_URL => 'https://my-server/my.json',
      #},
      # Optional rejection subroutine
      #on_reject => \&on_reject;
      ;
    $app;
  };

=head1 DESCRIPTION

Plack::Middleware::Auth::FCGI permits to protect an application by querying
a remote FastCGI server I<(like Nginx auth_request)>.

It can be used with L<Lemonldap::NG|https://lemonldap-ng.org> in a
L<SSO-as-a-Service (SSOaaS)|https://lemonldap-ng.org/documentation/2.0/ssoaas>
system.

=head1 SEE ALSO

=over

=item L<Lemonldap::NG|https://lemonldap-ng.org>

=item L<SSO-as-a-Service (SSOaaS)|https://lemonldap-ng.org/documentation/2.0/ssoaas>

=back

=head1 AUTHOR

Xavier Guimard L<x.guimard@free.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Xavier Guimard L<x.guimard@free.fr>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
