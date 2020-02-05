package Bmoogle;

use 5.14.0;

use Exporter 'import';
our @EXPORT = (qw< flow >,
				qw< SH >);

sub flow (&) { shift }

sub SH { say "@_" }

1;
