#!perl

use strict;
use Test::More;
use File::Basename;
use FindBin;
use Pg::SQL::PrettyPrinter;
use JSON::MaybeXS;
use List::Util qw( uniq );

my $want_only    = shift || '.';
my $want_only_re = qr/${want_only}/;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

opendir my $dir, $data_dir;
my @tests = map { join( '-', @{ $_ } ) }
    sort { $a->[ 0 ] <=> $b->[ 0 ] || $a->[ 1 ] cmp $b->[ 1 ] }
    map  { [ split( /-/, $_, 2 ) ] } uniq
    grep { $_ =~ $want_only_re }
    map  { s/\.(?:json|sql)$//; $_ }
    grep { /^(\d+)-(.*).(?:json|sql)$/ } readdir $dir;
closedir $dir;

plan 'tests' => scalar @tests;

for my $test ( @tests ) {
    my $input_struct = decode_json( load_file( $test . '.json' ) );
    my $text_output  = load_file( $test . '.sql' );
    my $pp           = Pg::SQL::PrettyPrinter->new(
        'sql'    => 'irrelevant',
        'struct' => $input_struct
    );
    $pp->parse();
    is( trim( $pp->{ 'statements' }->[ 0 ]->as_text ), trim( $text_output ), "Test ${test} - as_text()" );
}

exit;

sub trim {
    my $t = shift;
    $t =~ s/\s*\z//;
    return $t;
}

sub load_file {
    my $filename = shift;

    open my $fh, '<', sprintf( "%s/%s", $data_dir, $filename );
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    return $file_content;
}

