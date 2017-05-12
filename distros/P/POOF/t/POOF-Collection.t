# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('POOF::Collection') };
BEGIN { use_ok('POOF::Example::Vehicle::Automobile::NissanXterra') };
BEGIN { use_ok('POOF::Example::Vehicle::Bicycle::BMX') };
BEGIN { use_ok('POOF::Example::Key') };
BEGIN { use_ok('POOF::Example::Engine') };
BEGIN { use_ok('POOF::Example::Wheels') };
#########################

$POOF::TRACE = 0;

my $t1 =
[
    POOF::Example::Vehicle::Automobile::NissanXterra->new,
    POOF::Example::Vehicle::Automobile::NissanXterra->new,
    POOF::Example::Vehicle::Automobile::NissanXterra->new
];

my $c1 = POOF::Collection->new
(
    'name'      => 'Xterras',
    'access'    => 'Public',
    'otype'     => 'POOF::Example::Vehicle::Automobile::NissanXterra',
    'maxsize'   => 10,
);

foreach my $xterra (@{$t1})
{
    push @{$c1},$xterra;
}


is_deeply($t1,$c1,'problem with push');

isa_ok( $c1->[0]->{'Wheels'}, 'POOF::Example::Wheels', 'Wheels is of type POOF::Example::Wheels');

for my $w (0 .. 3)
{
    isa_ok( $c1->[0]->{'Wheels'}->[$w],'POOF::Example::Wheel',"Testing element $w in Wheels Collection");
}



exit;


