use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestUtils;
use File::Spec::Functions;
use SVN::Dump;

eval { require PerlIO::gzip; };
plan skip_all => 'PerlIO::gzip required to test gziped streams' if $@;

my @files = glob catfile( 't', 'dump', 'gzip', '*' );

plan tests => scalar @files;

for my $f (@files) {
    my $src = $f;
    $src =~ s/gzip/full/;
    $src =~ s/\.gz$//;
    my $expected = file_content($src);
    my $dump;

    # open a gzipped filehandle
    open my $fh, $f or do {
        fail("Failed to open $f: $!") for 1 .. 2;
        next;
    };
    binmode( $fh, ':gzip' );

    $dump = SVN::Dump->new( { fh => $fh } );

    my $as_string = '';
    while ( my $r = $dump->next_record() ) {
        $as_string .= $r->as_string();
    }
    is_same_string( $as_string, $expected, "Read $f dump" );

}

