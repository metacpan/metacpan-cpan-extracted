use v5.16;

package Module::Release::WebUpload::Mojo;

use strict;
use warnings;
use Exporter qw(import);

use Carp qw(croak);
use Mojo::UserAgent;
use File::Basename qw(basename);

our @EXPORT = qw(
	web_upload
	make_agent
	default_web_hostname
	pause_add_uri
	);

our $VERSION = '2.131';

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

	$self->_debug( sprintf "Uploading file %s\n", $self->local_file );

	my $params = {
		ACTION                        => 'add_uri',
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

	if( my $res = eval { $tx->result->is_success } ) {
		$self->_debug( "Response headers:\n" . $tx->res->to_string . "\n" );
		$self->_print( "File uploaded\n" );
		return 1;
		}
	else {
		my $err = $tx->res->error;
		$self->_print( $err->{code} ?
			"$err->{code} response: $err->{message}\n"
			:
			"Connection error: $err->{message}\n" );
		return 0;
		}
	}

sub make_agent {
	my( $self ) = @_;
	my $agent = Mojo::UserAgent->new;
	$agent->transactor->name( 'release' );
	$agent->http_proxy( $self->config->http_proxy )   if $self->config->http_proxy;
	$agent->https_proxy( $self->config->https_proxy ) if $self->config->https_proxy;

	return $agent;
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

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2023, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
