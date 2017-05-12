package Rudesind::WebApp;

use base 'MasonX::WebApp';

use Apache::Session::Wrapper;
use File::Path ();

use Rudesind::Config;
use Rudesind::UI;


__PACKAGE__->UseSession(1);
__PACKAGE__->ActionURIPrefix('/submit/');


sub _init
{
    my $self = shift;

    $self->{config} = Rudesind::Config->new;

    $self->_make_session_wrapper;
}

sub config { $_[0]->{config} }

sub _make_session_wrapper
{
    my $self = shift;

    return unless $self->{config};

    my %p = ( class     => 'Flex',
              store     => 'File',
              lock      => 'File',
              generate  => 'MD5',
              serialize => 'Storable',
              use_cookie  => 1,
              cookie_name => 'Rudesind-session',
              cookie_path => '/',
            );

    $p{directory} = $self->config->session_directory;
    $p{lock_directory} = $self->config->session_directory;

    File::Path::mkpath( $p{directory}, 0, 0700 )
        unless -d $p{directory};

    $self->{wrapper} = Apache::Session::Wrapper->new(%p);
}

sub session_wrapper { $_[0]->{wrapper} }

sub is_admin
{
    my $self = shift;

    if ( defined $self->apache_req->connection->user ? 1 : 0 )
    {
        $self->session->{admin} = 1;
        $self->session->{basic_auth} = 1;
    }

    return $self->session->{admin} ? 1 : 0;
}

sub basic_auth { $_[0]->session->{basic_auth} }

sub _redirect_from_args
{
    my $self = shift;

    $self->redirect( uri => ( $self->args->{redirect_to}
                              ? $self->args->{redirect_to}
                              : $_[0] )
                   );
}

sub login
{
    my $self = shift;

    $self->_handle_error( error => 'No password defined in config file',
                          uri   => $self->config->uri_root . '/admin/login.html',
                        )
        unless defined $self->config->admin_password;

    $self->_handle_error( error => 'Incorrect password',
                          uri   => $self->config->uri_root . '/admin/login.html',
                        )
        unless $self->args->{password} eq $self->config->admin_password;

    $self->session->{admin} = 1;

    $self->_add_message( 'Admin login was successful.' );

    $self->_redirect_from_args( $self->config->uri_root . '/' );
}

sub logout
{
    my $self = shift;

    $self->session->{admin} = 0;

    $self->_add_message( 'Logout was successful.' );

    $self->_redirect_from_args( $self->config->uri_root . '/' );
}

sub edit_caption
{
    my $self = shift;

    $self->redirect( uri => $self->config->uri_root . '/' )
        unless $self->is_admin;

    my ( $dir, $image ) =
        Rudesind::UI::new_from_path( $self->args->{path}, $self->config );
    my $thing = $image ? $image : $dir;

    $thing->save_caption( $self->args->{caption} );

    if ( length $self->args->{caption} )
    {
        $self->_add_message( 'Caption was edited.' );
    }
    else
    {
        $self->_add_message( 'Caption was deleted.' );
    }

    $self->_redirect_from_args( $self->config->uri_root . '/' );
}


1;

__END__

=pod

=head1 NAME

Rudesind::WebApp - A MasonX::WebApp subclass for the Rudesind application.

=head1 SYNOPSIS

  if ( $App->is_admin ) { ... }

=head1 DESCRIPTION

This class provides some Rudesind-specific functionality by
subclassing MasonX::WebApp.  It stores sessions in the a directory
called F<sessions> under the temp directory defined by the
configuration.

=head1 HANDLED URIS

This class handles the following URIs:

=over 4

=item * <URI ROOT>/login

Expects to be given an "admin_password" argument.  If this is defined
in the configuration file, and the given argument matches this
parameter, the browser session is logged-in.

=item * <URI ROOT>/logout

Logs the browser out.

=item * <URI ROOT>/logout

Expects a "path" argument, which will either be a gallery or image.
It calls C<save_caption()> with the "caption" argument on the object
defined by the "path" argument.

=back

=head1 METHODS

This class provides the following methods:

=over 4

=item * config

Returns a C<Rudesind::Config> object.

=item * is_admin

Returns a boolean indicating whether or not the browser is logged-in
as an admin.  If basic auth for the admin area succeeded in the past,
then the browser is logged-in.

=item * basic_auth

Returns a boolean indicating whether or not the basic auth for the
admin area succeeded.

=back

=cut
