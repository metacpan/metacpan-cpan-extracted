
package PRANG::Graph::Class;
$PRANG::Graph::Class::VERSION = '0.21';
# this role is a hangover from the pre-metarole conversion.  It should
# not be required any more.  You should use
# $class->meta->does_role("PRANG::Graph::Meta::Class");

use Moose::Role;

BEGIN {
	warn "PRANG::Graph::Class is now deprecated"
		unless $0 =~ /00-load.t/;
}

1;

