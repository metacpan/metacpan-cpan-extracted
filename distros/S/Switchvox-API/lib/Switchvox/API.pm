package Switchvox::API;

use strict;
use warnings;
use LWP::UserAgent;
use Crypt::SSLeay; #- required for LWP to use https:
use Switchvox::API::Request;
use Switchvox::API::Response;

use base 'LWP::UserAgent';

our $VERSION = '1.02';

sub new
{
	my ($class,%in)  = @_;
	warn "Missing hostname in call to constructor" unless defined $in{hostname};
	warn "Missing username in call to constructor" unless defined $in{username};
	warn "Missing password in call to constructor" unless defined $in{password};

	my $self = new LWP::UserAgent;
	$self->{_sv_hostname} = $in{hostname};
	$self->{_sv_username} = $in{username};
	$self->{_sv_password} = $in{password};
	bless $self, $class;
	return $self;
}

sub api_request
{
	my ($self,%in) = @_;
	$in{hostname} = $self->{_sv_hostname};
	my $request = new Switchvox::API::Request(%in);	
	return $self->_execute_request($request);
}

sub _execute_request
{
    my ($self,$request) = @_;
	$self->credentials($self->{_sv_hostname}.':443', 'switchvox_api_auth', $self->{_sv_username},$self->{_sv_password});
	my $response = $self->request($request);
	my $api_response = new Switchvox::API::Response(response => $response);
	$api_response->process();
    return $api_response;
}

1; #- Switchvox rules!

__END__

=head1 NAME

Switchvox::API - Perl interface to the Switchvox Extend API.

=head1 SYNOPSIS

This module provides a simple interface to interface with the Extend API on a Digium, Switchvox PBX. 
For more complete documentation on the entire Switchvox Extend API please visit L<http://developers.digium.com/switchvox>.
For more information on the Digium, Switchvox PBX product please visit the project home page at L<http://www.switchvox.com>.

Note: The C<Switchvox::API> object is a subclass of L<LWP::UserAgent> so you can use all functionality of LWP::UserAgent.
	
An example of requesting information about two accounts (1106,1107) from the Switchvox PBX.

	my $api = new Switchvox::API(
		hostname => '192.168.0.50',
		username => 'admin',
		password => 'your_admin_password'
	);

	my $response = $api->api_request(
		method		=> 'switchvox.extensions.getInfo',
		parameters	=> 
		{
			account_ids => 
			[
				{ 'account_id' => [1106,1107] }
			],
		}
	);

	if($response->{api_status} eq 'success')
	{
		my $extensions = $response->{api_result}{response}[0]{result}[0]{extensions}[0]{extension};
		foreach my $extension (@$extensions)
		{
			print "Extension:$extension->{number}, Full Name:$extension->{first_name} $extension->{last_name}\n";
		}
	}
	else
	{
		print "Encountered Errors:\n";
		foreach my $error ( @{$response->{api_errors}} )
		{
			print "-Code:$error->{code},Message:$error->{message}\n";
		}
	}

=head1 AUTHOR

Written by David W. Podolsky <api at switchvox dot com>

Copyright (C) 2009 Digium, Inc

=head1 SEE ALSO

L<Switchvox::API::Request>,
L<Switchvox::API::Response>,
L<http://developers.digium.com/switchvox/>


=head1 METHODS

=over

=item new( %args )

Returns a new C<Switchvox::API> object. 

=over

=item hostname

The hostname or IP address of the Switchvox PBX.

=item username

The admin name or the extension used for authentication with the Switchvox. If you use an extension you can only call user methods via the Extend API.

=item password

The admin password or extension password used for authentication.

=back

=item api_request( %args )

Returns an C<Switchvox::API::Response> object.

=over

=item method

Name of the API method you want to call.

=item parameters

List of parameters to pass to the API.

=back

=back

=cut
