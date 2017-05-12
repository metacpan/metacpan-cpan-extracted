use strict;
use warnings;
use Test::More;
use t::Utils;
use File::Spec::Functions;
use SVN::Dump::Reader;

my @files = glob catfile( 't', 'dump', 'full', '*' );

plan tests => 2 * @files;

for my $f (@files) {
    my $expected = file_content($f);
    open my $fh, $f or do {
        fail( "Failed to open $f: $!" ) for 1..2;
        next;
    };

    my $dump = SVN::Dump::Reader->new($fh);
    my $as_string = '';
    while( my $r = $dump->read_record() ) {
        $as_string .= $r->as_string();
    }
    is_same_string( $as_string, $expected, "Read $f dump" );
    is( tell($fh), -s $f, "Read all of $f (@{[-s $f]} bytes)" );
}

