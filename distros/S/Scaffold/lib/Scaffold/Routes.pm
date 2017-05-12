package Scaffold::Routes;

our $VERSION = '0.02';

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  constants => 'ARRAY',
  accessors => 'routes',
  messages => {
      invparams => "%s"
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub dispatcher {
    my ($self, $url) = @_;

    my ($handler, @vars) = $self->_parse_url($url);

    return ($handler, @vars);
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    if (ref($config->{routes}) ne ARRAY) {

        $self->throw_msg('scaffold.routes.init.invparams', 'invparams', 'not an array');

    }

    $self->{routes} = $config->{routes};

    return $self;

}

sub _parse_url {
    my ($self, $url) = @_;

    my @temp;

    for (@{$self->{routes}}) {

        if (my (@vars) = $url =~ m/$_->{route}/i) {

            # clean out any undef's

            foreach my $item (@vars) {
                if (defined($item)) {
                    push(@temp, $item);
                }
            }

            return ($_->{handler}, @temp);

        }

    }

    return ('', @temp);

}

1;

__END__

=head1 NAME

Scaffold::Routes - Implementing Routes for url dispatching within Scaffold

=head1 SYNOPSIS

 my $routes = Scaffold::Routes->new(
     [
         {
             route   => qr{^/(.*\..*)$},
             handler => 'Scaffold::Handler::Static',
         },{
             route   => qr{^/static/(.*)$},
             handler => 'Scaffold::Handler::Static'
         },{
             route   => qr{^/login/(\w+)$},
             handler => 'Scaffold::Uaf::Login',
	     },{
             route   => qr{^/logout$},
             handler => 'Scaffold::Uaf::Logout',
         }
     ]
 );

 my ($handler, @params) = $routes->dispatcher('/index.html');

=head1 DESCRIPTION

This class implements the concept of routes. Routes are dispatching to 
handlers, depending on regex parsing of the incomming url.

=head1 ACCESSORS

=over 4

=item routes

This returns the configured routes.

=back

=head1 METHODS

=over 4

=item dispatcher

Takes the routes and compares them to the incomming url. When a match is
found, it returns the handler and any resulting parameters.

=back

=head1 SEE ALSO

 Badger::Base
 Sleep::Routes

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 ACKNOWLEDGMENTS

Based on Sleep::Routes by Peter Stuifzand <peter@stuifzand.eu>

Thank you Peter

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
