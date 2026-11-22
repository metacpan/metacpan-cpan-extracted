#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

sub program { join '', map { "$_\n" } @_ }

my $dir = tempdir( CLEANUP => 1 );

sub source_file {
    my ( $name, @lines ) = @_;
    my $path = File::Spec->catfile( $dir, $name );
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} program(@lines);
    close $fh;
    return $path;
}

source_file( 'M.pm', 'package M;', 'use Podlite;', '=data module-data', '', '1;' );
source_file( 'N.pm', 'use Podlite;', 'package N;', '=data n-data', '', '1;' );
source_file( 'Mm.pm', 'use Podlite;', 'package main;', '=data module', '', 'package Mm;', '1;' );
source_file( 'Ea.pm', 'package Ea;', 'use Podlite;', '=data a', '', '1;', '__END__', 'tail' );
source_file( 'Eb.pm', 'package Eb;', 'use Podlite;', '=data b', '', '1;' );
source_file( 'Ka.pm', 'package Ka;', 'use Podlite;', '=data a', '', '#line 1 "other.pm"', 'use Podlite;', '1;', '__END__' );
source_file( 'Fa.pm', 'package Fa;', 'use Podlite;', 'BEGIN { die q(boom) }', '1;', '__END__' );
source_file( 'Fc.pm', 'package Fc;', 'use Podlite;', '=data c', '', 'BEGIN { die q(boom) }', '1;' );
source_file( 'twice.pl', 'package Tw;', 'use Podlite;', '=data again', '', 'print "S=$DATA";', '__END__' );

sub prints {
    my ( $name, $expected, @lines ) = @_;
    my $run = run_perl( program(@lines), switches => ["-I$dir"] );
    is( $run->{stdout}, $expected, $name ) or diag( $run->{stderr} );
}

my @read_both = (
    'package App;',
    'print "A=", scalar(<App::DATA>) // "EOF\n"; print "M=", scalar(<main::DATA>) // "EOF\n"; print "S=$DATA";',
    '1;'
);

sub required {
    my ( $name, $expected, $marker ) = @_;
    my $path = source_file( "req-$marker.pl", 'use Podlite;', '=data embed', '', @read_both, $marker, 'native',
        'second' );
    my $run = run_perl( "require q($path);\n" );
    is( $run->{stdout}, $expected, $name ) or diag( $run->{stderr} );
}

# Defects of 1.00

prints( 'a module with package then use keeps main data', "main=program-data\nM=module-data\n",
    'use Podlite;', '=data program-data', '', 'use M;', 'print "main=", scalar(<main::DATA>);', 'print "M=$M::DATA";' );

prints( 'a module with use then package keeps main data', "main=program-data\nN=n-data\n",
    'use Podlite;', '=data program-data', '', 'use N;', 'print "main=", scalar(<main::DATA>);', 'print "N=$N::DATA";' );

prints( 'a module required at run time keeps the native handle', "before=native-one\nafter=native-two\n",
    'use Podlite;', 'print "before=", scalar(<DATA>);', 'require M;', 'print "after=", scalar(<DATA>);', '__DATA__',
    'native-one', 'native-two' );

prints( 'a package declared before use reads its data', "App=embed\nmain=embed\n",
    'package App;', 'use Podlite;', '=data embed', '', 'print "App=", $App::DATA // "undef\n";',
    'print "main=", $main::DATA // "undef\n";' );

prints( 'a repeated use keeps data and position', "B=first\nR=second\n",
    'use Podlite;', '=begin data', 'first', 'second', '=end data', 'BEGIN { print "B=", scalar(<main::DATA>) }',
    'use Podlite;', 'print "R=", scalar(<main::DATA>) // "EOF\n";' );

prints( 'a package named in a code example gets no data', "bogus=undef\n",
    'use Podlite;', '=begin code', 'package Bogus;', '=end code', '=data x', '',
    'print "bogus=", $Bogus::DATA // "undef\n";' );

prints( 'a module switching to package main keeps main data', "main=host\n",
    'use Podlite;', '=data host', '', 'require Mm;', 'print "main=$main::DATA";' );

prints( 'a module after one that ends at __END__ gets its data', "A=a\nB=b\n",
    'require Ea; require Eb;', 'print "A=$Ea::DATA", "B=$Eb::DATA";' );

prints( 'a repeated use in an area ended by __END__ keeps data and position', "B=first\nR=second\nS=first\nsecond\n",
    'use Podlite;', '=begin data', 'first', 'second', '=end data', 'BEGIN { print "B=", scalar(<main::DATA>) }',
    'use Podlite;', 'BEGIN { print "R=", scalar(<main::DATA>) // "EOF\n" }', 'print "S=$DATA";', '__END__' );

prints( 'a module after one that died before __END__ gets its data', "B=b\n",
    'eval { require Fa };', 'require Eb;', 'print "B=$Eb::DATA";' );

prints( 'a module after one that died before its end gets its data', "B=b\n",
    'eval { require Fc };', 'require Eb;', 'print "B=$Eb::DATA";' );

prints( 'a repeated use after #line in an area ended by __END__', "A=a\nB=b\n",
    'require Ka; require Eb;', 'print "A=$Ka::DATA", "B=$Eb::DATA";' );

prints( 'a file ended by __END__ run twice gets its data each time', "S=again\nS=again\n",
    'do q(twice.pl) or die $@ || $! for 1 .. 2;' );

prints( 'a repeated use after #line keeps data and position', "B=first\nR=second\n",
    'use Podlite;', '=begin data', 'first', 'second', '=end data', 'BEGIN { print "B=", scalar(<main::DATA>) }',
    '#line 900 "virtual.pl"', 'use Podlite;', 'print "R=", scalar(<main::DATA>) // "EOF\n";' );

prints( 'a heredoc line spelled use Podlite stays text', "75736520506f646c6974653b0a\n",
    'use Podlite;', 'my $s = <<END;', 'use Podlite;', 'END', 'print unpack("H*", $s), "\n";' );

required( 'a required file with __DATA__ leaves main alone', "A=native\nM=EOF\nS=embed\n", '__DATA__' );

# Behaviour kept from 1.00

{
    for my $marker (qw(__DATA__ __END__)) {
        my $path = source_file( "prog-$marker.pl", 'use Podlite;', '=data embed', '', @read_both, $marker,
            'native', 'second' );
        my $top = run_perl( do { local ( @ARGV, $/ ) = $path; <> } );
        is( $top->{stdout}, "A=native\nM=second\nS=embed\n", "a program with $marker shares the native handle" )
            or diag( $top->{stderr} );
    }
}

required( 'a required file with __END__ reads Podlite data', "A=embed\nM=EOF\nS=embed\n", '__END__' );

prints( 'packages share one position', "A=one\nM=two\n",
    'use Podlite;', 'package App;', '=begin data', 'one', 'two', '=end data', 'print "A=", scalar(<App::DATA>);',
    'print "M=", scalar(<main::DATA>);' );

prints( 'a new area after no and use', "main=second\nold=first\n",
    'use Podlite;', 'package Old;', '=data first', '', 'package main;', 'no Podlite;', 'use Podlite;',
    '=data second', '', 'print "main=$main::DATA", "old=$Old::DATA";' );

prints( 'a package named in a Perl string gets data', "ghost=x\n",
    'use Podlite;', 'my $s = "package Ghost;";', '=data x', '', 'print "ghost=", $Ghost::DATA // "undef\n";' );

prints( 'a comment between package and its name hides it', "app=undef\n",
    'use Podlite;', 'package # reader', '    App;', '=data x', '', 'package main; print "app=", $App::DATA // "undef\n";' );

done_testing();
