#!perl

use strict;
use Test::More;
use File::Basename;
use FindBin;
use Pg::SQL::PrettyPrinter;
use JSON::MaybeXS;
use List::Util qw( uniq );

if ( !$ENV{ 'TEST_HTTP' } ) {
    plan skip_all => 'TEST_HTTP env variable not provided. Skipping. To enable, run before tests: export TEST_HTTP=http://127.0.0.1:15283/';
}
elsif ( $ENV{ 'TEST_HTTP' } !~ m{^http://\d{1,3}(?:\.\d{1,3}){3}:[1-9]\d+/$} ) {
    plan skip_all => "TEST_HTTP env variable doesn't look ok. Skipping. To enable, run before tests: export TEST_HTTP=http://127.0.0.1:15283/";
}

my $want_only    = shift || '.';
my $want_only_re = qr/${want_only}/;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

opendir my $dir, $data_dir;
my @tests = map { join( '-', @{ $_ } ) }
    sort { $a->[ 0 ] <=> $b->[ 0 ] || $a->[ 1 ] cmp $b->[ 1 ] }
    map  { [ split( /-/, $_, 2 ) ] } uniq
    grep { $_ =~ $want_only_re }
    map  { s/\.(?:sql|psql)$//; $_ }
    grep { /^(\d+)-(.*).(?:sql|psql)$/ } readdir $dir;
closedir $dir;

plan 'tests' => scalar @tests;

for my $test ( @tests ) {
    my $input  = load_file( $test . '.sql' );
    my $output = load_file( $test . '.psql' );
    my $pp     = Pg::SQL::PrettyPrinter->new(
        'sql'   => $input,
        service => $ENV{ 'TEST_HTTP' }
    );
    $pp->parse();
    is( trim( $pp->{ 'statements' }->[ 0 ]->pretty_print ), trim( $output ), "Test ${test} - pretty_print()" );
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

