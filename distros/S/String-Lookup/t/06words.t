
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

my $tests;
BEGIN { $tests= 2 + 1 + 1 + 1 + 2 + 3 + 1 } #BEGIN;

use Test::More tests => $tests;
use strict;
use warnings;

# modules that we need
use List::Util qw( sum );
use String::Lookup;
use Time::HiRes qw( time );

my $dictwords= '/usr/share/dict/words';
my $ourwords=  'words';
SKIP : {
    skip "No 'words' file available", $tests
      if !( -s $dictwords and -r $dictwords );

    # initializations
    my $cpu=   sum times;
    my $clock= time;
    my $seen;

    # provide scope for file handles
    my $ro_hash;
    do {
        open my $in,  '<', $dictwords or die "Could not open '$dictwords': $!";
        open my $out, '>', $ourwords  or die "Could not open '$ourwords': $!";

        tie my %hash, 'String::Lookup',
          autoflush => 100000,
          flush     => sub {
              my ( $list, $todo )= @_;
              diag "Seen $seen strings";
              print $out "$list->[$_]\n" foreach @{$todo};
              return 1;
          };
        $ro_hash= %hash;

        # do our lookup
        diag "Reading strings from $dictwords...";
        my $id;
        my $string;
        chomp($string), $seen++, $id= $ro_hash->{$string} || $hash{ \$string }
          while $string= readline $in;
    };

    # looks the same
    if ( is( -s $ourwords, -s $dictwords, 'did we see the same file' ) ) {

        # we can do a diff
        if ( open my $diff, "diff $dictwords $ourwords |" ) {
            my $text= '';
            my $line;
            $text .= $line while $line= readline($diff);
            is( $text, '', 'should see no output in diff' );
        }

        # no easy way to diff, don't bother
        else {
            ok( 1, 'no diff to use' );
        }
    }

    # different
    else {
        ok( 1, 'size differ, no sense in using diff' );
    }

    # stats
    $cpu=   sum(times) - $cpu;
    $clock= time - $clock;
    diag sprintf "\nSaw %d new strings in %.2f seconds using %.2f CPU seconds",
      $seen, $clock, $cpu;
    diag sprintf "That's %.2f new ID's / second", $seen / $clock;

    # clean up
    is( unlink($ourwords), 1, 'clean up' );

    # re-initializations
    my $reseen= 0;
    $cpu=   sum times;
    $clock= time;

    # unoptimized old strings
    do {
        open my $in,  '<', $dictwords or die "Could not open '$dictwords': $!";

        tie my %hash, 'String::Lookup',
          init  => $ro_hash,
          flush => sub { die "No flushing should happen" };

        # do our lookup
        diag "Reading strings from $dictwords...";
        my $id;
        my $string;
        chomp($string), $reseen++, $id= $hash{ \$string }
          while $string= readline $in;
    };
    is( $reseen, $seen, 'same number of strings seen' );

    # stats
    $cpu=   sum(times) - $cpu;
    $clock= time - $clock;
    diag sprintf "\nSaw %d old strings in %.2f seconds using %.2f CPU seconds",
      $seen, $clock, $cpu;
    diag sprintf "That's %.2f ID's / second", $seen / $clock;

    # re-initializations
    $reseen= 0;
    $cpu=   sum times;
    $clock= time;

    # optimized old strings
    do {
        open my $in,  '<', $dictwords or die "Could not open '$dictwords': $!";

        tie my %hash, 'String::Lookup',
          init  => $ro_hash,
          flush => sub { die "No flushing should happen" };
        $ro_hash= %hash;

        # do our lookup
        diag "Reading strings from $dictwords...";
        my $id;
        my $string;
        chomp($string), $reseen++, $id= $ro_hash->{$string} || $hash{ \$string }
          while $string= readline $in;
    };
    is( $reseen, $seen, 'same number of strings seen' );

    # stats
    $cpu=   sum(times) - $cpu;
    $clock= time - $clock;
    diag sprintf "\nSaw %d optimized strings in %.2f seconds using %.2f CPU seconds",
      $seen, $clock, $cpu;
    diag sprintf "That's %.2f ID's / second", $seen / $clock;

    # flatfile test initializations
    my $tag=      'words_test';
    my $filename= "$tag.lookup";
    my @storage=  ( storage => 'FlatFile', dir => '.', tag => $tag );

    # re-initializations
    $reseen= 0;
    $cpu=   sum times;
    $clock= time;

    # write using flatfile
    do {
        open my $in,  '<', $dictwords or die "Could not open '$dictwords': $!";

        tie my %hash, 'String::Lookup',
          autoflush => 100000,
          @storage;
        $ro_hash= %hash;

        # do our lookup
        diag "Reading strings from $dictwords...";
        my $id;
        my $string;
        chomp($string), $reseen++, $id= $ro_hash->{$string} || $hash{ \$string }
          while $string= readline $in;
    };
    my ( $size, $changed )= ( stat $filename )[ 7,9 ];
    is( $reseen, $seen, 'same number of strings seen' );
    ok( $size, 'check if file exists with something in it' );

    # stats
    $cpu=   sum(times) - $cpu;
    $clock= time - $clock;
    diag sprintf "\nSaw %d flatfiled strings in %.2f seconds using %.2f CPU seconds",
      $seen, $clock, $cpu;
    diag sprintf "That's %.2f ID's / second", $seen / $clock;

    # re-initializations
    $reseen= 0;
    $cpu=   sum times;
    $clock= time;

    # read from existing flatfile
    do {
        open my $in,  '<', $dictwords or die "Could not open '$dictwords': $!";

        tie my %hash, 'String::Lookup',
          autoflush => 100000,
          @storage;
        $ro_hash= %hash;

        # do our lookup
        diag "Reading strings from $dictwords...";
        my $id;
        my $string;
        chomp($string), $reseen++, $id= $ro_hash->{$string} || $hash{ \$string }
          while $string= readline $in;
    };
    my ( $new_size, $new_changed )= ( stat $filename )[ 7,9 ];
    is( $reseen, $seen, 'same number of strings seen' );
    is( $new_size, $size, 'check if file exists with same size' );
    is( $new_changed, $changed, 'check if file exists with same mtime' );

    # stats
    $cpu=   sum(times) - $cpu;
    $clock= time - $clock;
    diag sprintf "\nSaw %d strings from flatfile in %.2f seconds using %.2f CPU seconds",
      $seen, $clock, $cpu;
    diag sprintf "That's %.2f ID's / second", $seen / $clock;

    # clean up
    is( unlink($filename), 1, 'clean up' );
} #SKIP
