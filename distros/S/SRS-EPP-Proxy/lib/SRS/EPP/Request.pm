
package SRS::EPP::Request;
{
  $SRS::EPP::Request::VERSION = '0.22';
}

use Moose;

extends 'SRS::EPP::Message';

use XML::SRS;
has "+message" =>
	isa => "XML::SRS::Action|XML::SRS::Query",
	handles => [qw(action_id)],
	;

1;
