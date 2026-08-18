use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0003-parse.t - the DSL parser turns a plain-text screen into widgets and
# builds the value hash and the focus ring correctly.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;

my $dsl = <<'FORM';
Registration
Company: [______]
Qty:     [###]
Price:   [$$$$$$]
Date:    [YYYYMMDD]
--------
[X] Ship
[ ] Stock

Payment:
(*) Cash
( ) Card
[OK]
[Quit]
FORM

my $t = TUI::Handy->new(dsl => $dsl);
my @w = @{$t->{widgets}};

my %kind;
for my $x (@w) {
    $kind{$x->{kind}}++;
}

# Find the widgets by kind for sub-type checks.
my @text = grep { $_->{kind} eq 'text' } @w;
my %sub;
for my $x (@text) {
    $sub{$x->{key}} = $x->{subtype};
}

my @tests = (
    sub { ok(scalar(@w) == 14, 'parsed 14 widgets') },
    sub { ok($kind{'label'}  == 4, '4 label/separator widgets') },
    sub { ok($kind{'text'}   == 4, '4 text widgets') },
    sub { ok($kind{'check'}  == 2, '2 check widgets') },
    sub { ok($kind{'radio'}  == 2, '2 radio widgets') },
    sub { ok($kind{'button'} == 2, '2 button widgets') },
    sub { ok($sub{'Company'} eq 'hankaku', 'Company is hankaku text') },
    sub { ok($sub{'Qty'}     eq 'num',     'Qty is numeric') },
    sub { ok($sub{'Price'}   eq 'cur',     'Price is currency') },
    sub { ok($sub{'Date'}    eq 'date',    'Date is date') },
    sub { ok($t->form->{'Ship'}  == 1, 'checked box Ship preset to 1') },
    sub { ok($t->form->{'Stock'} == 0, 'unchecked box Stock preset to 0') },
    sub { ok($t->form->{'Payment'} eq 'Cash', 'radio group Payment preset to Cash') },
    sub {
        my $ok = join('|', @{$t->{order_keys}})
              eq 'Company|Qty|Price|Date|Ship|Stock|Payment|OK|Quit';
        ok($ok, 'order_keys preserved in DSL order');
    },
    sub { ok(scalar(@{$t->{focus}}) == 10, 'focus ring has 10 interactive widgets') },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
