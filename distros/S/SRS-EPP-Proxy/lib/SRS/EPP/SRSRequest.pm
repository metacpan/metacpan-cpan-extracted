
package SRS::EPP::SRSRequest;
{
  $SRS::EPP::SRSRequest::VERSION = '0.22';
}

use Moose;
use Moose::Util::TypeConstraints qw(subtype coerce as where enum);

extends 'SRS::EPP::Message';

use XML::SRS;
has "+message" =>
	isa => "XML::SRS::Action|XML::SRS::Query",
	handles => [qw(action_id)],
	;

1;
