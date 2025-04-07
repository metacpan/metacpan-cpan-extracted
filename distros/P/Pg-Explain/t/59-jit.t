#!perl

use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my @all_plans = @ARGV;
if ( 0 == scalar @all_plans ) {
    opendir my $dir, $data_dir;
    @all_plans = sort grep { /\.plan\.(?:text|json|yaml|xml)$/ } readdir $dir;
    closedir $dir;
}

my @jit_plans   = grep { /^jit/ } @all_plans;
my @nojit_plans = grep { /^nojit/ } @all_plans;

# 3 tests each for non-jit plans (4 formats)
# 9 tests each for jit-including plans (4 formats)
plan 'tests' => 3 * scalar( @nojit_plans ) + 9 * scalar( @jit_plans );

for my $test ( @nojit_plans ) {
    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );
    isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
    lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );
    is( $explain->jit, undef, "${test} JIT info, correctly, missing" );
}

for my $test ( @jit_plans ) {

    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );
    isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
    lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );
    isnt( $explain->jit, undef, "${test} JIT info exists" );
    isa_ok( $explain->jit, 'Pg::Explain::JIT', "(${test}) JIT info is of correct class" );

    my $rexplain = Pg::Explain->new( 'source' => $explain->as_text() );
    isa_ok( $rexplain, 'Pg::Explain', "(r-${test}) Object creation" );
    lives_ok( sub { $rexplain->parse_source(); }, "(r-${test}) Parsing lives" );
    isnt( $rexplain->jit, undef, "r-${test} JIT info exists" );
    isa_ok( $rexplain->jit, 'Pg::Explain::JIT', "(r-${test}) JIT info is of correct class" );

    my $struct_orig = $explain->get_struct();
    my $struct_re   = $rexplain->get_struct();
    cmp_deeply( $struct_orig, $struct_re, "(${test}) Struct and re-Struct are the same" );
}

exit;

sub load_file {
    my $filename = shift;
    open my $fh, '<', sprintf( "%s/%s", $data_dir, $filename );
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    $file_content =~ s/\s*\z//;

    return $file_content;
}

