
package SRS::EPP::Command::Create;
{
  $SRS::EPP::Command::Create::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"create";
}

1;
