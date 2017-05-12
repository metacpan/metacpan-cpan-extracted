use strict;
use warnings;
use Test::More tests => 11;

use File::Spec::Functions;

use Module::Collect;

my $collect = Module::Collect->new( path => [ catfile('t', 'plugin1'), catfile('t', 'plugin2') ]);

my($module) = grep { $_->package eq 'One' } @{ $collect->modules };
isa_ok $module, 'Module::Collect::Package';
ok $module->require;
ok grep {catfile($_) eq catfile('t', 'plugin1', 'one.pm')} keys %INC;

my $obj = $module->new;
ok $obj;
isa_ok $obj, 'One';

my $obj2 = $module->new({one => 2});
is $obj2->one, 2;

my($module2) = grep { $_->package eq 'Two' } @{ $collect->modules };
$module2->require;
do {
    local $@;
    eval { $module2->new };
    like $@, qr/Can't locate object method "new" via package "Two"/;
};
is $module2->package->two, 2;
is catfile($module2->path), catfile(qw/ t plugin2 two.pm/);
is $module2->package, 'Two';

my($module3) = grep { $_->package eq 'two2' } @{ $collect->modules };
do {
    local $@;
    eval { $module3->require };
    like $@, qr/Bareword "error" not allowed while "strict subs"/;
};
