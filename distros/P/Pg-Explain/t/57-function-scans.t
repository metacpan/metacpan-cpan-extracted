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

my $test_count = 0;

if ( 0 == scalar @ARGV ) {
    opendir( my $dir, $data_dir );

    for my $file ( sort readdir $dir ) {
        next unless $file =~ m/^plan\.(plain|alias)\.(json|text|yaml|xml)$/;

        $test_count++ if $1 eq "alias";
        $test_count += 5;

        push @tests, $file;
    }

    closedir $dir;
}
else {
    @tests = @ARGV;
}

plan 'tests' => $test_count;

for my $test ( @tests ) {

    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );

    isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
    lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );
    my $n = $explain->top_node;
    my $s = $n->scan_on;

    is( $n->type, 'Function Scan', "(${test}) Top node type as expected" );
    ok( defined $s, "(${test}) Top node has scan info" );

    $s //= {};
    is( $s->{ 'function_name' }, 'generate_series', "(${test}) Top node has proper function name" );

    if ( $test =~ /\.alias\./ ) {
        is( $s->{ 'function_alias' }, 'i', "(${test}) Top node has proper function alias" );
    }
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

