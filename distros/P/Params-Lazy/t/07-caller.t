use strict;
use warnings;

use Test::More;
use Params::Lazy lazy_run => '^';
#line 6
sub lazy_run { force($_[0]) };

use Data::Dumper;

my $caller  = [lazy_run caller()];
my $against = [ __PACKAGE__, __FILE__, __LINE__ - 1 ];

is_deeply(
    $caller,
    $against,
    "lazy_run caller() shows the correct data"
);

sub calls_caller { caller(0); }

$caller  = [ (lazy_run(calls_caller()))[0..3] ];
$against = [ __PACKAGE__, __FILE__, 21, __PACKAGE__ . '::calls_caller' ];

is_deeply($caller, $against, "lazy_run calls_caller()")
    or diag(Dumper($caller));

done_testing;
