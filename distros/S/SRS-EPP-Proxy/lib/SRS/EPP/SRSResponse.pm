
package SRS::EPP::SRSResponse;
{
  $SRS::EPP::SRSResponse::VERSION = '0.22';
}

use Moose;

extends 'SRS::EPP::Message';

use XML::SRS;
has "+message" =>
	isa => "XML::SRS::Result|XML::SRS::Error",
	handles => [qw(action_id)],
	;

sub ids {
	my $self = shift;
	$self->message->results->[0]->result_id;
}

1;
