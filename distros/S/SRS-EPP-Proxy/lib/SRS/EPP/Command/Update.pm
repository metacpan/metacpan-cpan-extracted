
package SRS::EPP::Command::Update;
{
  $SRS::EPP::Command::Update::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"update";
}

1;
