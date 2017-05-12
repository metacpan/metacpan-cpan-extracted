
package SRS::EPP::Command::Info;
{
  $SRS::EPP::Command::Info::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"info";
}

1;
