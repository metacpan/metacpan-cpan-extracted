use strict;
use warnings;
use Test::More;
use Test::Output;
use App::LiquidTidy;
use vars qw($t2_expected);
require "./t/results.pl";

plan tests => 1;

my $app = App::LiquidTidy->new({file => './t/source.html'});

stdout_is { $app->run } $t2_expected, "App T1";

1;
