use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestUtils;
use File::Spec::Functions;
use SVN::Dump;

my @files = glob catfile( 't', 'dump', 'full', '*' );

plan tests => 2 * @files;

my $i = 0;
for my $f (@files) {
    my $expected = file_content($f);
    my $dump;

    # test each file twice
    my $fh;

    # once with a filehandle
    if ( $i % 2 ) {
        open $fh, $f or do {
            fail("Failed to open $f: $!") for 1 .. 2;
            next;
        };

        $dump = SVN::Dump->new( { fh => $fh, check_digest => 1 } );
    }
    # once with a filename
    else {
        $dump = SVN::Dump->new( { file => $f } );
    }

    my $as_string = '';
    while ( my $r = $dump->next_record() ) {
        $as_string .= $r->as_string();
    }
    is_same_string( $as_string, $expected, "Read $f dump" );
    is( tell($dump->{reader}), -s $f, "Read all of $f (@{[-s $f]} bytes)" );

    $i++;
}

