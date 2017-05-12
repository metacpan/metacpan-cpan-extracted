# Testing module for exporting subs and UIDs

package expo;


use lib "lib"; use Params::Clean;
use base "Exporter";
our @EXPORT=qw/stuff things ID/;	

use UID qw/ID FOO/;
# We're not exporting FOO, so it has to be used fully-qualified from other packages


sub stuff
{
	my ($answer, @rest) = args ID, REST;
	return \$answer, \@rest;
}

sub things
{
	my ($answer, @rest) = args FOO, REST;
	return \$answer, \@rest;
}
