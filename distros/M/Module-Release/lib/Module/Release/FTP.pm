package Module::Release::FTP;

use strict;
use warnings;
use Exporter qw(import);
use vars qw($VERSION);

use Carp qw(croak);

our @EXPORT = qw(
	ftp_upload ftp_passive_on ftp_passive_off ftp_passive
	ftp_class_name get_ftp_object
	default_ftp_hostname default_ftp_user
	default_ftp_password default_ftp_upload_dir
	);

$VERSION = '2.123';

=encoding utf8

=head1 NAME

Module::Release::FTP - Interact with an FTP server

=head1 SYNOPSIS

NOTE: PAUSE has turned off FTP uploads. Methods in this class
will croak. If you want to make a private PAUSE with FTP, you
can adapt this manual.

=head1 DESCRIPTION

=over 4

=item ftp_upload( PARAMS )

Upload the file in C<local_file> as C<remote_file> to the FTP server. You
can pass parameters to ftp_upload to change some of the behavior. Each
parameter has a default value (see the default_* subs at the end of the
module):

	Input key       Default value
	----------      -------------
	upload_dir      /incoming
	user            anonymous
	password        joe@example.com
	hostname        pause.perl.org

=cut

sub ftp_upload {
	croak "PAUSE moved hosts and has turned off FTP uploads\n";
	my $self = shift;

	my %defaults = map { my $m = "default_ftp_$_"; $_, $self->$m() } qw(
		upload_dir
		user
		password
		hostname
		);

	my %params = (
		%defaults,
		@_,
		);

	$self->_print( "Logging in to $params{hostname}\n" );

	my $ftp = $self->get_ftp_object( $params{hostname} );

	$ftp->login( @params{ qw(user password) } )
		or $self->_die( "Couldn't log in to $params{hostname}" );

	$ftp->binary;

	$ftp->cwd( $params{'upload_dir'} )
		or $self->_die( "Couldn't chdir to $params{'upload_dir'}" );

	$self->_print( "Putting " . $self->local_file . "\n" );
	my $remote_file = $ftp->put( $self->local_file, $self->remote_file );
	$self->_die( "PUT failed: " . $ftp->message . "\n" )
		if $remote_file ne $self->remote_file;

	my $remote_size = $ftp->size( $self->remote_file );

	no warnings 'uninitialized';
	$self->_print( "WARNING: Uploaded file is $remote_size bytes, " .
		"but local file is " . -s $self->local_file . " bytes" )
			if $remote_size != -s $self->local_file;

	$ftp->quit;

	$self->_print( "File uploaded\n" );
	}

=item ftp_passive_on

Turn on passive FTP.

=item ftp_passive_off

Turn off passive FTP.

=item ftp_passive

Get the value of the passive FTP setting

=cut

sub ftp_passive_on  { $_[0]->{ftp_passive} = 1 }

sub ftp_passive_off { $_[0]->{ftp_passive} = 0 }

sub ftp_passive     { $_[0]->{ftp_passive} }

=item ftp_class_name

The class name to use to create the FTP object. The class needs to follow
the C<Net::FTP> interface.

=cut

sub ftp_class_name { 'Net::FTP' }

=item get_ftp_object( HOSTNAME )

Create and returnt the FTP object, based on the class name from
C<ftp_class_name>. IT connects to HOSTNAME, but does not login.

=cut

sub get_ftp_object {
	my( $self, $site ) = @_;

	my $class = $self->ftp_class_name;
	my $rc = eval "require $class; 1";

	$self->_die( "Couldn't load $class: $@" ) unless defined $rc;

	$self->_debug( "Will use passive FTP transfers\n" ) if $self->ftp_passive;

	my $ftp = $class->new(
		$site,
		Hash    => \*STDOUT,
		Debug   => $self->debug,
		Passive => $self->ftp_passive,
		) or $self->_die( "Couldn't open FTP connection to $site: $@" );

	return $ftp;
	}

=back

=head2 Default values

Override these methods to change the default values. Remember that
the overridden methods have to show up in the C<Module::Release>
namespace.

=over 4

=item default_ftp_hostname

pause.perl.org

=item default_ftp_user

anonymous

=item default_ftp_password

joe@example.com

=item default_ftp_upload_dir

/incoming

=cut

sub default_ftp_hostname   { "pause.perl.org" }

sub default_ftp_user       { "anonymous" }

sub default_ftp_password   { "joe\@example.com" }

sub default_ftp_upload_dir { "/incoming" }


=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
