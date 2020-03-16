#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use File::Basename;
use autodie;
use FindBin;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

use Pg::Explain;

my @tests = @ARGV;
if ( 0 == scalar @tests ) {
    opendir( my $dir, $data_dir );

    my %uniq = ();
    @tests = sort { $a <=> $b }
        grep { !$uniq{ $_ }++ }
        grep { /^\d+\.plan+$/ } readdir $dir;

    closedir $dir;
}

plan 'tests' => 3 * scalar @tests;

for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $expect_file = $test;
    $expect_file =~ s/\.plan$/.expect/;
    my $expected_type = load_file( $expect_file );
    chomp $expected_type;

    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );

    isa_ok( $explain,           'Pg::Explain',       "Object creation for test $test" );
    isa_ok( $explain->top_node, 'Pg::Explain::Node', "Parsing for test $test" );
    is( $explain->top_node->type, $expected_type, "Type of top node for test $test" );

}

exit;

sub load_file {
    my $filename = shift;
    my $filepath = $data_dir . '/' . $filename;

    open my $fh, '<', $filepath;
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    return $file_content;
}
