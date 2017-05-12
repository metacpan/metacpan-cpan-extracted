use strict;
use warnings;
use Test::More;
use t::Utils;
use File::Spec::Functions;
use File::Temp qw( tempfile );
use SVN::Dump;

my @files = glob catfile( 't', 'dump', 'full', '*' );

plan tests => 4 * @files;

my $i = 0;
for my $f (@files) {

    # open the original dump
    my $dump = SVN::Dump->new( { file => $f } );
    my $expected = file_content($f);

    # open a target file
    my ( $fh, $tempfile ) = tempfile( 'dump-XXXX', SUFFIX => '.svn' );

    # read the dump
    my $as_string = '';
    while ( my $r = $dump->next_record() ) {
        $as_string .= $r->as_string();

        # transform the dump
        $r->set_text('dummy') if defined $r->get_text();    # replace text
        delete ${ $r->get_headers_block() }{'Text-delta'}   # no more delta
            if $r->get_header('Text-delta');
        print $fh $r->as_string();
    }
    close $fh;

    # quick check that identity still works
    is_same_string( $as_string, $expected, "Read $f dump" );
    is( tell( $dump->{reader} ), -s $f, "Read all of $f (@{[-s $f]} bytes)" );

    # read the transformed version
    $expected = file_content($tempfile);

    # check round trip
    $dump = SVN::Dump->new( { file => $tempfile } );
    $as_string = '';
    while ( my $r = $dump->next_record() ) {
        $as_string .= $r->as_string();
    }

    is_same_string( $as_string, $expected,
        "Read $tempfile dump (transformed $f)" );
    is( tell( $dump->{reader} ),
        -s $tempfile, "Read all of $tempfile (@{[-s $tempfile]} bytes)" );
    unlink $tempfile;
}

