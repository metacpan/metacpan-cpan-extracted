
package SRS::EPP::Command::Renew;
{
  $SRS::EPP::Command::Renew::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use Module::Pluggable search_path => [__PACKAGE__];
with 'SRS::EPP::Command::PayloadClass';

sub action {
	"renew";
}

1;
