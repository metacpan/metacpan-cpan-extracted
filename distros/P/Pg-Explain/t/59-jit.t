#!perl

use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

# 3 tests each for non-jit plans (4 formats)
# 9 tests each for jit-including plans (4 formats)
plan 'tests' => 3 * 4 + 9 * 4;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

for my $format ( qw( text json yaml xml ) ) {
    my $test    = "nojit.plan.${format}";
    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );
    isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
    lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );
    is( $explain->jit, undef, "${test} JIT info, correctly, missing" );
}

for my $format ( qw( text json yaml xml ) ) {
    my $test = "jit.plan.${format}";

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

