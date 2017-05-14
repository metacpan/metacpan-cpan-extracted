# ABSTRACT: Web interface to a Pinto repository

package Pinto::Server;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw(Int HashRef);

use Carp;
use Path::Class;
use Class::Load;
use Scalar::Util qw(blessed);
use IO::Interactive qw(is_interactive);
use Plack::Middleware::Auth::Basic;

use Pinto::Types qw(Dir);
use Pinto::Constants qw(:server);
use Pinto::Server::Router;
use Pinto::Repository;

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------


has root => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);


has auth => (
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    handles => { auth_options => 'elements' },
);


has router => (
    is      => 'ro',
    isa     => 'Pinto::Server::Router',
    default => sub { Pinto::Server::Router->new },
    lazy    => 1,
);


class_has default_port => (
    is      => 'ro',
    isa     => Int,
    default => $PINTO_SERVER_DEFAULT_PORT,
);

#-------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $repo = Pinto::Repository->new( root => $self->root );
    $repo->assert_sanity_ok;

    return $self;
}

#-------------------------------------------------------------------------------


sub to_app {
    my ($self) = @_;

    my $app = sub { $self->call(@_) };

    if ( my %auth_options = $self->auth_options ) {

        my $backend = delete $auth_options{backend}
            or carp 'No auth backend provided!';

        my $class = 'Authen::Simple::' . $backend;
        print "Authenticating using $class\n" if is_interactive;
        Class::Load::load_class($class);

        $app = Plack::Middleware::Auth::Basic->wrap( $app, authenticator => $class->new(%auth_options) );
    }

    return $app;
}

#-------------------------------------------------------------------------------


sub call {
    my ( $self, $env ) = @_;

    my $response = $self->router->route( $env, $self->root );

    $response = $response->finalize
        if blessed($response) && $response->can('finalize');

    return $response;
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Server - Web interface to a Pinto repository

=head1 VERSION

version 0.097

=head1 ATTRIBUTES

=head2 root

The path to the root directory of your Pinto repository.  The
repository must already exist at this location.  This attribute is
required.

=head2 auth

The hashref of authentication options, if authentication is to be used within
the server. One of the options must be 'backend', to specify which
Authen::Simple:: class to use; the other key/value pairs will be passed as-is
to the Authen::Simple class.

=head2 router

An object that does the L<Pinto::Server::Handler> role.  This object
will do the work of processing the request and returning a response.

=head2 default_port

Returns the default port number that the server will listen on.  This
is a class attribute.

=head1 METHODS

=head2 to_app()

Returns the application as a subroutine reference.

=head2 call( $env )

Invokes the application with the specified environment.  Returns a
PSGI-compatible response.

There is nothing to see here.

Look at L<pintod> if you want to start the server.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
