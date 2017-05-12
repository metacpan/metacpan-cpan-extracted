
package SRS::EPP::Command::Transfer;
{
  $SRS::EPP::Command::Transfer::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"transfer";
}

1;
