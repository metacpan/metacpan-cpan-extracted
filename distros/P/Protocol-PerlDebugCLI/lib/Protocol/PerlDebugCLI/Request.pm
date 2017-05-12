
# thin object wrapper, avoid CPAN indexer since this doesn't
# do enough yet to have proper documentation
package
 Protocol::PerlDebugCLI::Request;

use strict;
use warnings;

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub command { shift->{command} }

1;

