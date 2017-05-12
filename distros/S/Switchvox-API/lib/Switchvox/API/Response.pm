package Switchvox::API::Response;

use strict;
use warnings;
use HTTP::Response;
use XML::Simple qw(:strict);
use XML::Parser;

use base 'HTTP::Response';

our $VERSION = '1.02';

#- Force a non sax parser for error validation
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

sub new
{
	my ($class,%in)  = @_;
	warn "Missing response in call to constructor" unless defined $in{response};
	my $self = $in{response};
	bless $self,$class;
	
	$self->{api_errors} = [];
	$self->{api_result} = undef;
	$self->{api_status} = 'unprocessed';
	return $self;
}

sub process
{
	my $self = shift;

	#- Ok check all the status
    if(!$self->is_success())
    {
		return $self->_failed( errors => [{ code => -1, message => 'HTTP Request failed (' . $self->message . ')' }]);
    }

	#- Parse the XML and check for problems
    my $xmlin = eval
	{ 
		XML::Simple::XMLin($self->content, KeyAttr => {}, ForceArray => 1, KeepRoot => 1 );
	};

	#- XML Parse issues
    if($@)
    {
		return $self->_failed( errors => [{ code => -1, message => "Returned XML did not parse correctly ($@)" }]); 
    }

    #- Check on result
    if(exists $xmlin->{response}[0]{result})
    {
		$self->{api_result} = $xmlin;
		$self->{api_status} = 'success';
		return;
    }
    elsif(exists $xmlin->{response}[0]{errors})
    {
		my $errors = [];
		foreach my $error ( @{$xmlin->{response}[0]{errors}[0]{error}} )
        {
			push(@$errors,{ code => $error->{code}, message => $error->{message} });
        }
		return $self->_fault( errors => $errors );
    }
    else
    {
		return $self->_failed( errors => [ {code => -1, message => 'Valid XML was not returned by the API'}] );
    }
	return;
}

sub _failed
{
	my ($self,%in) = @_;
	$self->{api_status} = 'failed';
	$self->{api_errors} = $in{errors} || [];
}

sub _fault
{
	my ($self,%in) = @_;
	$self->{api_status} = 'fault';
	$self->{api_errors} = $in{errors} || [];
}

1; #- Switchvox Rules!

__END__

=head1 NAME

Switchvox::API::Response - A response to the Switchvox Extend API.

=head1 SYNOPSIS

A Switchvox::API::Response object is returned from the api_request method in the C<Switchvox::API> class.

Note: The C<Switchvox::API::Response> object is a subclass of L<HTTP::Response> so you can use all functionality of HTTP::Response.

You mostly only need to interact with three hash keys in the Switchvox::API::Response object (api_status,api_errors,api_result).
If you want to get to the raw xml returned from the API call you can access this through the $response->{_content} field.

=over

=item $response->{api_status}

Status string that represents the success or failure of the API call. Possible values: success,fault,fault.

=over

=item success

Everything went great and you should check the {api_result} for the data. 

=item fault

The connection to the API just fine, but the API returned a fault code (probably due to some invalid parameter) and you should check the {api_errors} for a summary of the problem.

=item failed

There was a problem with the connection to the API. This could because the hostname was incorrect, a bad HTTP response code was returned, etc. You should check the {api_errors} for a summary of the problem.


=back

=item $response->{api_errors}

Array ref containing any connection errors, xml parsing errors, faults returned, etc during the request.

=item $response->{api_result}

If the request was successful this is where the data will be.

=back

=head1 AUTHOR

Written by David W. Podolsky <api at switchvox dot com>

Copyright (C) 2009 Digium, Inc

=head1 SEE ALSO

L<Switchvox::API::Request>,
L<Switchvox::API::Response>,
L<http://developers.digium.com/switchvox/>

=cut

