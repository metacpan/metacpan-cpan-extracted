#!perl

use 5.036;
use warnings FATAL => q{all};

use FindBin;
use lib "$FindBin::Bin/lib";

use Scalar::Util qw{reftype};
use Test::More tests => 18;

# Both pass their import list to plan(), so their subs are called by full name.
use Test::Pod           ();
use Test::Pod::Coverage ();

use Pod::Coverage::More;

# The fixtures, whose POD and subs the tests read.
require Quux;
require Xenu;
require Ret;

#Make sure parent is still sane
my @pobjfiles = map { $INC{$_} } ('Quux.pm');
foreach my $pm (@pobjfiles) {
    Test::Pod::pod_file_ok($pm);
}

my @modules = ( 'Quux', 'Xenu' );
foreach my $mod (@modules) {
    note "Verify base Pod::Coverage OK";
    Test::Pod::Coverage::pod_coverage_ok($mod);
    note "Verify Pod::Coverage functionality in Pod::Coverage::More works";
    Test::Pod::Coverage::pod_coverage_ok( $mod, { coverage_class => 'Pod::Coverage::More' } );
}

note "Verify arg coverage is adequate";
my $pc  = Pod::Coverage::More->new( package => 'Quux' );
my $res = $pc->coverage_arguments();
is( reftype($res), 'HASH', "Coverage arguments returns hashref" );
ok( $res->{'status'}, "Got correct arg coverage for test module Quux" );
is( $res->{'message'}, undef, "No message provided when everything is OK" );

$pc  = Pod::Coverage::More->new( package => 'Xenu' );
$res = $pc->coverage_arguments();
is( reftype($res), 'HASH', "Coverage arguments returns hashref" );
ok( $res->{'status'}, "Got correct arg coverage for test module Xenu" );
is( $res->{'message'}, undef, "No message provided when everything is OK" );

note "Verify arg type coverage is adequate";
my $xenu_types = $pc->_documentation->section_for(q{test_case_insensitivity_sigs})->{types}{test_case_insensitivity_sigs};
is( $xenu_types->{cat}{word},  q{scalarref}, "A SCALARREF item is not read as SCALAR" );
is( $xenu_types->{goat}{word}, q{arrayref},  "An ARRAYREF item is not read as ARRAY" );
is( $xenu_types->{pig}{word},  q{hashref},   "A hashref item is not read as HASH" );
$res = $pc->coverage_argument_types();
is( reftype($res), 'HASH', "Coverage arguments types returns hashref" );
ok( $res->{'status'}, "Got correct arg type coverage for test module Xenu" );
is( $res->{'message'}, undef, "No message provided when everything is OK" );

note "Verify return type coverage is adequate";
$pc  = Pod::Coverage::More->new( package => 'Ret' );
$res = $pc->coverage_return_types();
is( reftype($res), 'HASH', "Return type coverage returns a hashref" );
