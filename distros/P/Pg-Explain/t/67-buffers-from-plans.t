#!perl

use strict;
use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my @formats = qw( text json yaml xml );

# tests * formats * plans
plan 'tests' => 2 * scalar @formats;

for my $format ( @formats ) {
    my $explain = Pg::Explain->new( 'source' => load_file( $format . '.plan' ) );
    $explain->parse_source();

    my $struct_string = load_file( $format . '.struct' );
    my $expect_struct = eval $struct_string;

    cmp_deeply( $explain->get_struct, $expect_struct, "($format) Struct as expected" );
    my $ex2 = Pg::Explain->new( 'source' => $explain->as_text );
    cmp_deeply( $ex2->get_struct, $expect_struct, "($format) Struct from textual as expected" );
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

