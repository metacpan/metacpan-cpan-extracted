#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

sub program { join '', map { "$_\n" } @_ }

my $VIEWS = 'print unpack("H*", $DATA), "/", unpack("H*", join("", @DATA)), "/", unpack("H*", join("", <DATA>)), "\n";';

sub views {
    my ( $name, $expected, $source, @switches ) = @_;
    my $run = run_perl( $source, switches => \@switches );
    is( $run->{stdout}, "$expected/$expected/$expected\n", $name ) or diag( $run->{stderr} );
}

sub prints {
    my ( $name, $expected, @lines ) = @_;
    my $run = run_perl( program(@lines) );
    is( $run->{stdout}, $expected, $name ) or diag( $run->{stderr} );
}

# Defects of 1.00

views( 'a paragraph data-table is not data', '',
    program( 'use Podlite;', '=for data-table :mime-type<text/csv>', 'a,b', '', $VIEWS ) );

prints( 'a delimited data-table leaves no tail', "after\n",
    'use Podlite;', '=begin data-table :mime-type<text/csv>', 'a,b', '=end data-table', 'print "after\n";' );

prints( 'data inside a code example is not data', "real\n",
    'use Podlite;', '=begin code', '=data fake', '', '=end code', '=data real', '', 'print while <DATA>;' );

prints( 'data inside a Markdown fence is not data', "[]\n",
    'use Podlite;', '=begin markdown', '~~~', '=data fake', '~~~', '=end markdown', 'print "[", <DATA>, "]\n";' );

prints( 'data inside a code example inside a comment is not data', "[]\n",
    'use Podlite;', '=begin comment', '=begin code', '=data x', '', '=end code', '=end comment',
    'print "[", <DATA>, "]\n";' );

prints( 'a line starting with = and a digit stays in the data', "value\n=42\n",
    'use Podlite;', '=data value', '=42', '', 'print while <DATA>;' );

views( 'CRLF after =data adds no leading newline', '410d0a',
    join( '', map { "$_\r\n" } 'use Podlite;', '=data', 'A', '', $VIEWS ) );

views( 'the last data block keeps its trailing bytes', '41204220200a',
    program( 'use Podlite;', $VIEWS, '=for data', 'A B  ' ) );

{
    my $run = run_perl( program( 'use utf8;', 'use Podlite;', "=para \x{c6}\x{92}", '', 'print "ok\n";' ),
        switches => ['-CS'] );
    is( $run->{stdout}, "ok\n", 'decoded text above U+00FF is stripped' ) or diag( $run->{stderr} );
}

{
    my $run = run_perl( program( 'use utf8;', 'use Podlite;', '=begin data', "\x{e6}\x{bc}\x{a2}", '=end data',
        'print while <DATA>;' ), switches => ['-CS'] );
    is( $run->{stdout}, "\x{e6}\x{bc}\x{a2}\n", 'decoded data above U+00FF is read through the handle' )
        or diag( $run->{stderr} );
}

# Behaviour kept from 1.00

prints( 'data directly inside a comment is data', "hidden\n",
    'use Podlite;', '=begin comment', '=data hidden', '', '=end comment', 'print while <DATA>;' );

prints( 'an indented code run inside pod hides its lines', "real\n",
    'use Podlite;', '=begin pod', '    my $sample;', '    =data example', '', '=end pod', '=data real', '',
    'print while <DATA>;' );

views( 'three forms in source order', '410a420a430a',
    program( 'use Podlite;', '=begin data', 'A', '=end data', '=for data', 'B', '', '=data C', '', $VIEWS ) );

views( 'raw bytes pass unchanged', 'ff0a', "use Podlite;\n=begin data\n\xff\n=end data\n$VIEWS\n" );

views( 'UTF-8 bytes pass unchanged', 'e6bca20a',
    program( 'use Podlite;', "=data \x{e6}\x{bc}\x{a2}", '', $VIEWS ) );

views( 'abbreviated data starts after the first space', '2020580a', program( 'use Podlite;', '=data   X', '', $VIEWS ) );

views( 'abbreviated data starts after a tab', '580a', program( 'use Podlite;', "=data\tX", '', $VIEWS ) );

views( 'an indented data block loses its margin', '20202020580a',
    "use Podlite;\nif (1) {\n    =begin data\n\tX\n    =end data\n}\n$VIEWS\n" );

prints( 'the handle reads the scalar', "5a0a/410a/5a0a\n",
    'use Podlite;', '=data A', '', '$DATA = "Z\n";', $VIEWS );

{
    my $run = run_perl( program( 'use Podlite;', "=data \x{c3}\x{a9}", '',
        '$DATA = "Z\n"; print join(",", map ord, split //, $DATA), "/", join(",", map ord, split //, $DATA[0]), "/", join(",", map ord, split //, scalar <DATA>), "\n";' ),
        switches => ['-CS'] );
    is( $run->{stdout}, "90,10/233,10/90,10\n", 'decoded Latin-1 data keeps one scalar for the handle' )
        or diag( $run->{stderr} );
}

prints( 'BEGIN sees data declared below', "early=later\n",
    'use Podlite;', 'BEGIN { print "early=", $main::DATA }', '=data later', '', '1;' );

prints( 'a native data section owns the handle', "[native\n]embedded\n",
    'use Podlite;', '=data embedded', '', 'print "[", scalar(<DATA>), "]$DATA";', '__DATA__', 'native' );

done_testing();
