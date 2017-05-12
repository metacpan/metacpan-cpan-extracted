use strict;
use warnings FATAL   => 'all';
use Test::More tests => 7;
use constant EPS     => 1e-3;
use Statistics::Data;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();

my $cmp_aref = Array::Compare->new;

$dat->load( morphine => [ 1, 2, 3 ], love => [ 2013, 1984, 1999 ] );
my $ret = $dat->labels();
ok( scalar @{$ret} == 2,
    "Error in getting data labels(): expected 2; got " . scalar @{$ret} );

ok(
    $cmp_aref->simple_compare(
        [ sort { $a cmp $b } @{$ret} ],
        [qw/love morphine/]
    ),
    'Error getting data labels(); expected <love morphine>; got '
      . join( ' ', @{$ret} )
);

my $val = $dat->equal_n();
ok( $val == 3, "Error in equal_n: got <$val> not <3>" );

$dat->add( new => [qw/a b/] );
$val = $dat->equal_n();
ok( $val == 0, "Error in equal_n: got <$val> not <0>" );

# - equal_n by name:
$val = $dat->equal_n( name => [qw/morphine love/] );
ok( $val == 3, "Error in equal_n: got <$val> not <3>" );

$val = $dat->equal_n( name => [qw/morphine love new/] );
ok( $val == 0, "Error in equal_n: got <$val> not <0>" );

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;
