#===============================================================================
#
#         FILE:  FCGI.pm
#
#  DESCRIPTION:  Common FastCGI applications framework
#
#        NOTES:  This fr
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  15.07.2008 16:54:45 EEST
#===============================================================================

=head1 NAME

NetSDS::App::FCGI - FastCGI applications superclass

=head1 SYNOPSIS

	# Run application
	MyFCGI->run();

	1;

	# Application package itself
	package MyFCGI;

	use base 'NetSDS::App::FCGI';

	sub process {
		my ($self) = @_;

		$self->data('Hello World');
		$self->mime('text/plain');
		$self->charset('utf-8');

	}


=head1 DESCRIPTION

C<NetSDS::App::FCGI> module contains superclass for FastCGI applications.
This class is based on C<NetSDS::App> module and inherits all its functionality
like logging, configuration processing, etc.

=cut

package NetSDS::App::FCGI;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::App';

use CGI::Fast;
use CGI::Cookie;

use version; our $VERSION = '1.301';

#***********************************************************************

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Normally constructor of application framework shouldn't be invoked directly.

=cut 

#-----------------------------------------------------------------------

sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(
		cgi      => undef,
		mime     => undef,
		charset  => undef,
		data     => undef,
		redirect => undef,
		cookie   => undef,
		status   => undef,
		headers  => {},
		%params,
	);

	return $self;

}

#***********************************************************************

=item B<cgi()> - accessor to CGI.pm request handler

	my $https_header = $self->cgi->https('X-Some-Header');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('cgi');

#***********************************************************************

=item B<status([$new_status])> - set response HTTP status

Paramters: new status to set

Returns: response status value

	$self->status('200 OK');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('status');

#***********************************************************************

=item B<mime()> - set response MIME type

Paramters: new MIME type for response

	$self->mime('text/xml'); # output will be XML data

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('mime');

#***********************************************************************

=item B<charset()> - set response character set if necessary

	$self->mime('text/plain');
	$self->charset('koi8-r'); # ouput as KOI8-R text

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('charset');

#***********************************************************************

=item B<data($new_data)> - set response data

Paramters: new data "as is"

	$self->mime('text/plain');
	$self->data('Hello world!');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('data');

#***********************************************************************

=item B<redirect($redirect_url)> - send HTTP redirect

Paramters: new URL (relative or absolute)

This method send reponse with 302 status and new location.

	if (havent_data()) {
		$self->redirect('http://www.google.com'); # to google!
	};

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('redirect');

#***********************************************************************

=item B<cookie()> - 

Paramters:

Returns:

This method provides..... 

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('cookie');

#***********************************************************************

=item B<headers($headers_hashref)> - set/get response HTTP headers

Paramters: new headers as hash reference

	$self->headers({
		'X-Beer' => 'Guiness',
	);

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('headers');

#***********************************************************************

=item B<main_loop()> - main FastCGI loop

Paramters: none

This method implements common FastCGI (or CGI) loop.

=cut 

#-----------------------------------------------------------------------

sub main_loop {

	my ($self) = @_;

	$self->start();

	$SIG{TERM} = undef;
	$SIG{INT}  = undef;

	# Switch of verbosity
	$self->{verbose} = undef;

	# Enter FastCGI loop
	while ( $self->cgi( CGI::Fast->new() ) ) {

		# Retrieve request cookies
		$self->_set_req_cookies();

		# Set default response parameters
		$self->mime('text/plain');    # plain text output
		$self->charset('utf-8');      # UTF-8 charset
		$self->data('');              # empty string response
		$self->status("200 OK");      # everything OK
		$self->cookie( [] );          # no cookies
		$self->redirect(undef);       # no redirects

		# Call request processing method
		$self->process();

		# Send 302 and Location: header if redirect
		if ( $self->redirect ) {
			print $self->cgi->header(
				-cookie    => $self->cookie,
				-status    => '302 Moved',
				'Location' => $self->redirect
			);

		} else {

			# Implement generic content output
			use bytes;
			print $self->cgi->header(
				-type           => $self->mime,
				-status         => $self->status,
				-charset        => $self->charset,
				-cookie         => $self->cookie,
				-Content_length => bytes::length( $self->data ),
				%{ $self->headers },
			);
			no bytes;

			# Send return data to client
			if ( $self->data ) {
				$| = 1;    # set autoflushing mode to avoid output buffering
				binmode STDOUT;
				print $self->data;
			}
		} ## end else [ if ( $self->redirect )

	} ## end while ( $self->cgi( CGI::Fast...

	# Call finalization hooks
	$self->stop();

} ## end sub main_loop

#***********************************************************************

=item B<set_cookie(%params)> - set cookie

Paramters: hash (name, value, expires)

	$self->set_cookie(name => 'sessid', value => '343q5642653476', expires => '+1h');

=cut 

#-----------------------------------------------------------------------

sub set_cookie {

	my ( $self, %par ) = @_;

	push @{ $self->{cookie} }, $self->cgi->cookie( -name => $par{name}, -value => $par{value}, -expires => $par{expires} );

}

#***********************************************************************

=item B<get_cookie(%params)> - get cookie by name

Paramters: cookie name

Returns cookie value by it's name

	my $sess = $self->get_cookie('sessid');

=cut 

#-----------------------------------------------------------------------

sub get_cookie {

	my ( $self, $name ) = @_;

	return $self->{req_cookies}->{$name}->{value};

}

#***********************************************************************

=item B<param($name)> - CGI request parameter

Paramters: CGI parameter name

Returns: CGI parameter value

This method returns CGI parameter value by it's name.

	my $cost = $self->param('cost');

=cut 

#-----------------------------------------------------------------------

sub param {
	my ( $self, @par ) = @_;
	return $self->cgi->param(@par);
}

#***********************************************************************

=item B<url_param($name)> - CGI request parameter

Paramters: URL parameter name

Returns: URL parameter value

This method works similar to B<param()> method, but returns only parameters
from the query string.

	my $action = $self->url_param('a');

=cut

#-----------------------------------------------------------------------

sub url_param {
	my ( $self, @par ) = @_;
	return $self->cgi->url_param(@par);
}

#***********************************************************************

=item B<http($http_field)> - request HTTP header

Paramters: request header name

Returns: header value

This method returns HTTP request header value by name.

	my $beer = $self->http('X-Beer');

=cut 

#-----------------------------------------------------------------------

sub http {

	my $self = shift;
	my $par  = shift;

	return $self->cgi->http($par);
}

#***********************************************************************

=item B<https($https_field)> - request HTTPS header

This method returns HTTPS request header value by name and is almost
the same as http() method except of it works with SSL requests.

	my $beer = $self->https('X-Beer');

=cut 

#-----------------------------------------------------------------------

sub https {

	my $self = shift;
	my $par  = shift;

	return $self->cgi->https($par);
}

#***********************************************************************

=item B<raw_cookie()> - get raw cookie data

Just proxying C<raw_cookie()> method from CGI.pm

=cut 

#-----------------------------------------------------------------------

sub raw_cookie {
	my ($self) = @_;

	return $self->cgi->raw_cookie;
}

#**************************************************************************

=item B<user_agent()> - User-Agent request header

	my $ua_info = $self->user_agent();

=cut

#-----------------------------------------------------------------------
sub user_agent {
	my ($self) = @_;

	return $self->cgi->user_agent;
}

#***********************************************************************

=item B<request_method()> - HTTP request method

	if ($self->request_method eq 'POST') {
		$self->log("info", "Something POST'ed from client");
	}

=cut 

#-----------------------------------------------------------------------

sub request_method {
	my ($self) = @_;

	return $self->cgi->request_method;
}

#***********************************************************************

=item B<script_name()> - CGI script name

Returns: script name from CGI.pm

=cut 

#-----------------------------------------------------------------------

sub script_name {

	my ($self) = @_;

	return $self->cgi->script_name();
}

#***********************************************************************

=item B<path_info()> - get PATH_INFO value

	if ($self->path_info eq '/help') {
		$self->data('Help yourself');
	}

=cut 

#-----------------------------------------------------------------------

sub path_info {

	my ($self) = @_;

	return $self->cgi->path_info();
}

#***********************************************************************

=item B<remote_host()> - remote (client) host name

	warn "Client from: " . $self->remote_host();

=cut 

#-----------------------------------------------------------------------

sub remote_host {

	my ($self) = @_;

	return $self->cgi->remote_host();

}

#***********************************************************************

=item B<remote_addr()> - remote (client) IP address

Returns: IP address of client from REMOTE_ADDR environment

	if ($self->remote_addr eq '10.0.0.1') {
		$self->data('Welcome people from our gateway!');
	}

=cut 

#-----------------------------------------------------------------------

sub remote_addr {

	my ($self) = @_;

	return $ENV{REMOTE_ADDR};
}

#***********************************************************************

=item B<_set_req_cookies()> - fetching request cookies (internal method)

Fetching cookies from HTTP request to object C<req_cookies> variable.

=cut 

#-----------------------------------------------------------------------

sub _set_req_cookies {
	my ($self) = @_;

	my %cookies = CGI::Cookie->fetch();
	$self->{req_cookies} = \%cookies;

	return 1;
}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> catalog for more example code.

=head1 SEE ALSO

L<CGI>, L<CGI::Fast>, L<NetSDS::App>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


