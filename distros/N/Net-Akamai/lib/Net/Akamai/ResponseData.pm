package Net::Akamai::ResponseData;

use Moose;

=head1 NAME
    
Net::Akamai::ResponseData - Object to hold response data 
    
=head1 DESCRIPTION

Data container for an akamai purge response 

=cut

=head1 Attributes

=head2 uri_index 

Identifies the index of the first failed URL in the array.
A value of -1 indicates no bad URLs, or error before parsing them.

=cut
has 'uri_index' => (
	is => 'ro', 
	isa => 'Int',
	required => 1,
	default => '-1',
);


=head2 result_code 

Indicates sucess or failure of request

=cut
has 'result_code' => (
	is => 'ro', 
	isa => 'Int',
	required => 1,
	default => '0',
);


=head2 est_time 

Estimated time for request to be processed in seconds

=cut
has 'est_time' => (
	is => 'ro', 
	isa => 'Int',
	required => 1,
	default => '0',
);


=head2 session_id 

Unique id for request

=cut
has 'session_id' => (
	is => 'ro', 
	isa => 'Str',
	required => 1,
	default => '',
);


=head2 result_msg 

Explains result code

=cut
has 'result_msg' => (
	is => 'ro', 
	isa => 'Str',
	required => 1,
	default => '',
);


=head1 Methods

=head2 successful

Returns true if the result code is of the 1xx (successful) variety.

=cut
sub successful {
	my $self = shift;
	return 1 if $self->result_code() =~ /1\d\d/;
	return;
}

=head2 warning

Returns true if the result code is of the 2xx (warning) variety.
The Akamai documentation states that "The remove request has been
accepted" even when a warning response is sent.

=cut
sub warning {
	my $self = shift;
	return 1 if $self->result_code() =~ /2\d\d/;
	return;
}

=head2 accepted

Returns true if the result code is of the 1xx (successful) or 2xx
(warning) varieties.  This indicates that the remove request was
accepted by Akamai.  You should still check to see if there was a
warning, and if their was report it.

=cut
sub accepted {
	my $self = shift;
	return 1 if $self->successful();
	return 1 if $self->warning();
	return;
}

=head2 message

 if (!$res_data->accepted()) {
	# These do the same thing:
	die "$res_data";
	die $res_data->message();
 }

Returns a nicely formatted string containing the result_code and result_msg.

=cut
use overload '""' => \&message, fallback => 1;
sub message {
	my $self = shift;

	my $code = $self->result_code();
	my $message = $self->successful() ? 'SUCCESSFUL'
	            : $self->warning() ? 'WARNING'
	            : 'REJECTED';

	return $self->result_code() . " $message: " . $self->result_msg();
}

=head1 AUTHOR

John Goulah  <jgoulah@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
