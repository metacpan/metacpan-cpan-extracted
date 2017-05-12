use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use TAP::Harness;
use TAP::Formatter::HTML;

eval {
    for (1..64) { push @INC, "lib" }
    #my $t = TAP::Formatter::HTML->default_template_processor;

    my @tests = 't/data/01_pass.pl';
    my $f = TAP::Formatter::HTML->new({ silent => 1 });
    my $h = TAP::Harness->new({ merge => 1, formatter => $f });
    $h->runtests(@tests);
};
my $e = $@;
unlike($e, qr/INCLUDE_PATH exceeds .+ directories/i, 'RT 74364 - INCLUDE_PATH exceeds num dirs');
ok(!$e, 'no error set when calling default_template_processor with lots of dirs in @INC') || diag($e);
