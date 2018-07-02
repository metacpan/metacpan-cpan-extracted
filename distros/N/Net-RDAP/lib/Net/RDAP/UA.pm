package Net::RDAP::UA;
use base qw(LWP::UserAgent);
use Mozilla::CA;
use strict;

=pod

=head1 NAME

L<Net::RDAP::UA> - an RDAP user agent, based on L<LWP::UserAgent>.

=head1 DESCRIPTION

This module extends L<LWP::UserAgent> in order to inject various
RDAP-related configuration settings and HTTP request headers. Nothing
should ever need to use it.

=head1 COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

#
# create a new object, which is just an LWP::UserAgent with
# some additional
#
sub new {
	my ($package, %options) = @_;

	$options{'agent'} = sprintf('%s/%f', $package, $Net::RDAP::VERSION) if (!defined($options{'agent'}));

	$options{'ssl_opts'}= {} if (!defined($options{'ssl_opts'}));

	$options{'ssl_opts'}->{'verify_hostname'} = 1 unless (defined($options{'ssl_opts'}->{'verify_hostname'}));
	$options{'ssl_opts'}->{'SSL_ca_file'} = Mozilla::CA::SSL_ca_file() unless (defined($options{'ssl_opts'}->{'SSL_ca_file'}));

	return $package->SUPER::new(%options);
}

#
# override the default request() method to make sure that we ask the
# server for JSON:
#
sub request {
	my ($self, $request) = @_;

	$request->header('Accept' => 'application/rdap+json, application/json');

	print STDERR $request->as_string if (1 == $ENV{'NET_RDAP_UA_DEBUG'});

	my $response = $self->SUPER::request($request);

	print STDERR $response->as_string if (1 == $ENV{'NET_RDAP_UA_DEBUG'});

	return $response;
}

1;
