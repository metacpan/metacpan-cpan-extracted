package Module::Release::WebUpload::Mojo;

use strict;
use warnings;
use Exporter qw(import);
use vars qw($VERSION);

use Carp qw(croak);
use Mojo::UserAgent;
use File::Basename qw(basename);

our @EXPORT = qw(
	web_upload
	make_agent
	default_web_hostname
	pause_add_uri
	);

$VERSION = '2.123';

=encoding utf8

=head1 NAME

Module::Release::WebUpload::Mojo - Upload through the PAUSE web interface

=head1 SYNOPSIS

The release script automatically loads this module when it's time
to upload a file. It's implemented with C<Mojo::UserAgent>.

=head1 DESCRIPTION

=over 4

=item web_upload( PARAMS )

Upload the file to PAUSE

=cut

sub web_upload {
	my $self = shift;

	my $ua = $self->make_agent;

	$self->_debug( sprintf "Uploading file %s", $self->local_file );

	my $params = {
		HIDDENNAME                    => $self->config->cpan_user,
		CAN_MULTIPART                 => 1,
		pause99_add_uri_subdirtext    => '',
		SUBMIT_pause99_add_uri_httpupload => ' Upload this file from my disk ',
		pause99_add_uri_httpupload    => { file => $self->local_file },
		};

	$self->_print( "File uploading\n" );
	my $tx = $ua->post(
		$self->pause_add_uri(
		 	$self->config->cpan_user,
		 	$self->config->cpan_pass,
		 	),
		 form => $params,
		 );

	if( my $res = $tx->success ) {
		$self->_print( "File uploaded\n" );
		return 1;
		}
	else {
		my $err = $tx->error;
		$self->_print( "$err->{code} response: $err->{message}" ) if $err->{code};
		$self->_print( "Connection error: $err->{message}" );
		return 0;
		}
	}

sub make_agent {
	my( $self ) = @_;
	my $agent = Mojo::UserAgent->new;
	$agent->transactor->name( 'release' );
	$agent->http_proxy( $self->config->http_proxy ) if $self->config->http_proxy;
	$agent->https_proxy( $self->config->https_proxy ) if $self->config->https_proxy;

	return $agent;
	}

# XXX: Until I can upgrade OpenSSL
BEGIN {
use Mojo::IOLoop::Client;

use constant TLS => $ENV{MOJO_NO_TLS}
  ? 0
  : eval 'use IO::Socket::SSL 1.94 (); 1';

no warnings 'redefine';
sub Mojo::IOLoop::Client::_try_tls {
  my ($self, $args) = @_;

  my $handle = $self->{handle};
  return $self->_cleanup->emit(connect => $handle) unless $args->{tls};
  return $self->emit(error => 'IO::Socket::SSL 1.94+ required for TLS support')
    unless TLS;

  # Upgrade
  weaken $self;
  my %options = (
    SSL_ca_file => $args->{tls_ca}
      && -T $args->{tls_ca} ? $args->{tls_ca} : undef,
    SSL_cert_file  => $args->{tls_cert},
    SSL_error_trap => sub { $self->emit(error => $_[1]) },
    SSL_hostname   => IO::Socket::SSL->can_client_sni ? $args->{address} : '',
    SSL_key_file   => $args->{tls_key},
    SSL_startHandshake  => 0,
    SSL_verify_mode     => 0x00,  # XXX turn off hostname verification
    SSL_verifycn_name   => $args->{address},
    SSL_verifycn_scheme => $args->{tls_ca} ? 'http' : undef
  );

  my $reactor = $self->reactor;
  $reactor->remove($handle);
  return $self->emit(error => 'TLS upgrade failed')
    unless IO::Socket::SSL->start_SSL($handle, %options);
  $reactor->io($handle => sub { $self->_tls })->watch($handle, 0, 1);
}
}

=back

=head2 Default values

Override these methods to change the default values. Remember that
the overridden methods have to show up in the C<Module::Release>
namespace.

=over 4

=item default_web_hostname

pause.perl.org

=item pause_add_uri

http://pause.perl.org/pause/authenquery

=cut

sub default_web_hostname   { "pause.perl.org" }
sub pause_add_uri          {
	my( $self, $user, $pass ) = @_;
	sprintf 'https://%s:%s@pause.perl.org/pause/authenquery', $user, $pass;
	};

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
