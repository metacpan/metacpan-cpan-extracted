use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0001-load.t - the module loads, has a version, and exposes its API.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;

my @tests = (
    sub { ok(defined $TUI::Handy::VERSION, 'VERSION is defined') },
    sub { ok($TUI::Handy::VERSION eq '0.01', 'VERSION is 0.01') },
    sub { ok(TUI::Handy->can('new'),        'can new') },
    sub { ok(TUI::Handy->can('run'),        'can run') },
    sub { ok(TUI::Handy->can('set'),        'can set') },
    sub { ok(TUI::Handy->can('form'),       'can form') },
    sub { ok(TUI::Handy->can('pressed'),    'can pressed') },
    sub { ok(TUI::Handy->can('close_form'), 'can close_form') },
    sub {
        my $t = TUI::Handy->new(dsl => "Hello\n");
        ok(ref($t) eq 'TUI::Handy', 'new returns a TUI::Handy object');
    },
    sub {
        my $t = TUI::Handy->new(dsl => "Name: [____]\n");
        ok(ref($t->form) eq 'HASH', 'form returns a hash reference');
    },
);

plan_tests(scalar(@tests));
for my $t (@tests) {
    $t->();
}
