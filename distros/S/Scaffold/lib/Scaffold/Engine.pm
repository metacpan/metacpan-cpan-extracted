package Scaffold::Engine;

our $VERSION = '0.01';

use 5.8.8;
use Plack::Loader;
use Plack::Builder;

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  accessors => 'server request_handler request_class middlewares scaffold',
  messages => {
      'norequest' => "request_handler is required",
      'nomodule'  => "{server}->{module} is required",
      'noserver'  => "interace is required",
  },
  constant => {
      NOREQUEST => 'scaffold.engine.norequest',
      NOMODULE  => 'scaffold.engine.nomodule',
      NOSERVER  => 'scaffold.engine.noserver',
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub run {
    my ($self) = @_;

    my $server_instance;
    my $request_handler;

    $self->throw_msg(NOSERVER, 'noserver') unless $self->{server};
    $self->throw_msg(NOMODULE, 'nomodule') unless $self->{server}->{module};

    $server_instance = $self->_build_server_instance(
        $self->{server}->{module},
        $self->{server}->{args}
    );

    $request_handler = $self->psgi_handler;
    $server_instance->run($request_handler);

}

sub psgi_handler {
    shift->_build_request_handler;
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    $self->throw_msg(NOREQUEST, 'norequest') unless $config->{request_handler};

    $self->{server} = $config->{server};
    $self->{scaffold} = $config->{scaffold};
    $self->{middlewares} = $config->{middlewares} || [];
    $self->{request_handler} = $config->{request_handler};
    $self->{request_class} = $config->{request_class} || 'Plack::Request';

    Scaffold::Engine::Util::load_class($self->{request_class});

    return $self;

}

sub _build_server_instance {
    my ($class, $server, $args) = @_;

    Plack::Loader->load($server, %$args);

}

sub _build_request_handler {
    my ($self) = @_;

    my $app = $self->_build_app;

    $self->_wrap_with_middlewares($app);

}

sub _build_request {
    my ($self, $env) = @_;

    my $response = $self->{request_class}->new($env);

    return $response;

}

sub _build_app {
    my ($self) = @_;

    return sub {
        my $env = shift;
        my $scaffold = $self->scaffold;
        my $req = $self->_build_request($env);
        my $res = $self->{request_handler}->($scaffold, $req);
        $res->finalize;
    };

}

sub _wrap_with_middlewares {
    my ($self, $request_handler) = @_;

    my $builder = Plack::Builder->new;

    for my $middleware ( @{ $self->{middlewares} } ) {

        $builder->add_middleware( $middleware->{module},
            %{ $middleware->{opts} || {} } );

    }

    $builder->to_app($request_handler);

}

package Scaffold::Engine::Util;

sub load_class {
    my ($class, $prefix) = @_;

    if ( $class !~ s/^\+// && $prefix ) {

        $class = "$prefix\::$class";

    }

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm";    ## no critic

    return $class;

}

1;

__END__

=head1 NAME

Scaffold::Engine - The Scaffold interface to Plack/psgi

=head1 SYNOPSIS

  use Scaffold::Server;
  use Scaffold::Render::TT;

  my $psgi_handler;
  my $server = Scaffold::Server->new(
     locations => [
         {
             route   => qr{^/$},
             handler => 'App::HelloWorld',
         },{
             route   => qr{^/test$},
             handler => 'App::Cached',
         },{
             route   => qr{^/robots.txt$},
             handler => 'Scaffold::Handler::Robots',
         },{
             route   => qr{^/favicon.ico$},
             handler => 'Scaffold::Handler::Favicon',
         },{
             route   => qr{^/static/(.*)$},
             handler => 'Scaffold::Handler::Static',
         },{
            route   => qr{^/login/(.*)$},
            handler => 'Scaffold::Uaf::Login',
         },{
            route   => qr{^/logout$},
            handler => 'Scaffold::Uaf::Logout',
         }
     ],
     authorization => {
         authenticate => 'Scaffold::Uaf::Manager',
         authorize    => 'Scaffold::Uaf::Authorize',
     },
     render => Scaffold::Render::TT->new(
         include_path => 'html:html/resources/templates',
     ),
 );

 $psgi_hander = $server->engine->psgi_handler();

... or

  use Scaffold::Server;
  use Scaffold::Render::TT;

  my $server = Scaffold::Server->new(
     engine => {
         module => 'ServerSimple',
         args => {
             port => 8080,
         }
     },
     locations => [
         {
             route   => qr{^/$},
             handler => 'App::HelloWorld',
         },{
             route   => qr{^/test$},
             handler => 'App::Cached',
         },{
             route   => qr{^/robots.txt$},
             handler => 'Scaffold::Handler::Robots',
         },{
             route   => qr{^/favicon.ico$},
             handler => 'Scaffold::Handler::Favicon',
         },{
             route   => qr{^/static/(.*)$},
             handler => 'Scaffold::Handler::Static',
         },{
            route   => qr{^/login/(.*)$},
            handler => 'Scaffold::Uaf::Login',
         },{
            route   => qr{^/logout$},
            handler => 'Scaffold::Uaf::Logout',
         }
     ],
     authorization => {
         authenticate => 'Scaffold::Uaf::Manager',
         authorize    => 'Scaffold::Uaf::Authorize',
     },
     render => Scaffold::Render::TT->new(
         include_path => 'html:html/resources/templates',
     ),
 );

 $server->engine->run();

=head1 DESCRIPTION

This module is used internally by Scaffold::Server to initialize and return 
the code reference that is needed by the Plack/psgi runtime environment. The
first example in the Synopsis can be ran with the following command:

 # plackup -app app.psgi -port 8080

The second example can be ran with this command:

 # perl app.pl

The first example is more versatile, as the code can be used in any environment
that the Plack runtime supports.

=head1 ACCESSORS

=over 4

=item psgi_handler

Returns a code reference to the dispatch handler.

=item run

Runs Scaffold::Server as a standalone application.

=back

=head1 SEE ALSO

 PlackX::Engine

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

Coded adapted from PlackX::Engine by Takatoshi Kitano <kitano.tk@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
