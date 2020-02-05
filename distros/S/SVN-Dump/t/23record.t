use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestUtils;
use File::Spec::Functions;
use SVN::Dump::Reader;

my @files = glob catfile( 't', 'dump', 'records', '*' );

plan tests => 2 * @files;

for my $f (@files) {
    my $expected = file_content($f);
    open my $fh, $f or do {
        fail("Failed to open $f: $!") for 1 .. 2;
        next;
    };

    my $dump = SVN::Dump::Reader->new($fh);
    my $r    = $dump->read_record();
    is_same_string( $r->as_string(), $expected, "Read $f record" );
    $r = $dump->read_record();
    ok( !$r && tell($fh) == -s $f, "Read all of $f" );
}

