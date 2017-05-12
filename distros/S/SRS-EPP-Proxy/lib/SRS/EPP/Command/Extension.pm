
package SRS::EPP::Command::Extension;
{
  $SRS::EPP::Command::Extension::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

sub match_class {
	"XML::EPP::Extension";
}

1;
