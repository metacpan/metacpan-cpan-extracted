package Net::ThreeScale::Response;

use warnings;
use strict;

sub new {
	my $class = shift; 
	my $self = {@_};
	return bless $self, $class;	
}

sub is_success{
	return $_[0]->{success};	
}

sub usage_reports{
	return $_[0]->{usage_reports};
}

sub application_plan {
	return $_[0]->{application_plan};
}

sub error_code{
	return $_[0]->{error_code};	
}

sub error_message{
	return $_[0]->{error_message};
}

sub errors{
	return $_[0]->{errors};
}  
1;
=head1 NAME

Net::ThreeScale::Response - object encapsulating a response to a 3Scale API v2.0 call

=head1 SYNOPSIS

 $response = $client->authorize(app_id=>$app_id, app_key=>$app_key);
 if($response->is_success){ 
	my @usage = @{$response->usage_reports()};
 }else{ 
 	print STDERR "An error occurred with code ", $response->error_code, ":" ,$response->error,"\n";
 }
 
=head1 DESCRIPTION

A response object is returned from various calls in the 3Scale API, the following fields are of relevance:
Objects are constructed within the API, you should not create them yourself.

=over 4

=item $r->is_success

Indicates if the operation which generated the response was successfull. Successful responses will 
have an associated transaction within the response. 
 
=item $r->usage_reports

A list of usage reports returned by 3Scale indicating how much of the user's
quota has been used.
 
=item $r->error_code

Returns the error code  (as a string) which was genrerated by this response, these correspond 
to constants exported by the Net::ThreeScale::Client module. see 
Net::ThreeScale::Client for a list of available response codes. 

 
=item $r->error_message

Returns a textual description of the error returned by the server. 

=back

=head1 SEE ALSO

L<Net::ThreeScale::Client>
 
=head1 AUTHOR
  Owen Cliffe 
  Eugene Oden
  Collaborators: Dave Lambley, Ed Freyfogle and Marc Metten.
