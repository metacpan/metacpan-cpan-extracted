#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use FindBin;
use File::Spec;
use Test::More;

my $root = File::Spec->catdir( $FindBin::RealBin, '..' );
my $readme = File::Spec->catfile( $root, 'README.pod' );

open my $fh, '<:encoding(UTF-8)', $readme or die "open $readme: $!";

my @tests;
my $heading = '';
my $line_num = 0;
my $example_count = 0;

while ( my $line = <$fh> ) {
    $line_num++;

    if ( $line =~ /^=head\d\s+(.+)/ ) {
        $heading = $1;
        @tests = ();
        next;
    }

    if ( $line =~ /^=for test\s+(.+)/ ) {
        @tests = split /\s+/, $1;
        for my $test ( @tests ) {
            my $path = File::Spec->catfile( $root, $test );
            ok( -f $path, "$test exists for README section '$heading'" );
            like( $test, qr{^t/.+\.t$}, "$test is a .t test" );
        }
        next;
    }

    next unless $line =~ /^\s+(?:novel-robot\b|my \$xs\b|my \$r\s*=\s*\$xs->|\$xs->get_novel\b)/;
    $example_count++;
    ok( @tests, "README example at line $line_num has a corresponding .t test" );
}

ok( $example_count > 0, 'README contains checked examples' );
done_testing;
