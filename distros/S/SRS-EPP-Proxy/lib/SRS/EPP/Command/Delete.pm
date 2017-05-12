
package SRS::EPP::Command::Delete;
{
  $SRS::EPP::Command::Delete::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"delete";
}

1;
