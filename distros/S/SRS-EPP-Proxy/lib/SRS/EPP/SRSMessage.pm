
package SRS::EPP::SRSMessage;
{
  $SRS::EPP::SRSMessage::VERSION = '0.22';
}

use 5.010;
use Moose;

extends "SRS::EPP::Message";

has 'parts' =>
	is => "rw",
	isa => "ArrayRef[SRS::EPP::Message]",
	;

has "+message" =>
	isa => "XML::SRS",
	;

after 'message_trigger' => sub {
	my $self = shift;
	return if $self->parts and @{$self->parts};
	my $message = $self->message;
	my ($class, $method);
	if ( $message->isa("XML::SRS::Request") ) {
		$class = "SRS::EPP::SRSRequest";
		$method = "requests";
	}
	else {
		$class = "SRS::EPP::SRSResponse";
		$method = "results";
	}
	$self->parts( [
			map {
				$class->new( message => $_ )
				}
				@{ $message->$method//[] }
		]
	);
};

1;
