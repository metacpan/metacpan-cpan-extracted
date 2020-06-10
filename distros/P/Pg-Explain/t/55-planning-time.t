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

my @tests = ();

if ( 0 == scalar @ARGV ) {
    opendir( my $dir, $data_dir );

    for my $file ( sort readdir $dir ) {
        next unless $file =~ s/\.plan$//;
        push @tests, $file;
    }

    closedir $dir;
}
else {
    @tests = @ARGV;
}

plan 'tests' => 4 * scalar keys @tests;

for my $test ( @tests ) {

    my $explain = Pg::Explain->new( 'source' => load_file( $test . '.plan' ) );

    isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
    lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );
    ok( defined $explain->planning_time, "(${test}) Planning time defined" );
    is( $explain->planning_time, load_file( $test . '.expect' ), "(${test}) Planning time as expected" );
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

