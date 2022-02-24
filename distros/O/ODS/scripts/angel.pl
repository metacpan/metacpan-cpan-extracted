use strict;
use warnings;

use lib 'lib';

use ODS::Angel; # daemon

use Getopt::Long;

use YAML::XS;

our (
	$spec,
	$queue,
	$lib
);

BEGIN {
	GetOptions (
		"spec:s" => \$spec,
		"queue:s" => \$queue,
		"lib:s" => \$lib
	) or die $!;
}

use lib qw/$lib/;

ODS::Angel->new(
	spec => $spec,
	queue => $queue
)->run();
