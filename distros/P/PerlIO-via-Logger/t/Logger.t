#!perl -T

use strict;
use warnings;
use Test::More tests => 13;

BEGIN {				
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
    unless (find PerlIO::Layer 'perlio') {
        print "1..0 # Skip: PerlIO not used\n";
        exit 0;
    }
    use_ok('PerlIO::via::Logger');
}

can_ok( 'PerlIO::via::Logger',qw(format logify) );
PerlIO::via::Logger->format('[%d]');
is( PerlIO::via::Logger->format,'[%d]',	'check format' );

my $file = 'testlog.f';

# Check prefix when writing
ok(
 open( my $out,'>:via(PerlIO::via::Logger)', $file ),
 "opening '$file' for writing"
);

ok( (print $out <<END),		'print to the file' );
Some Line
Another Line
END
ok( close($out),			'closing file' );

# Check the file we just made without using the io layer

my @datetime = localtime(time);
my $daynum = sprintf('%02d', $datetime[3]);
my $teststring = "[$daynum]Some Line\n[$daynum]Another Line\n";

{
local $/ = undef;
ok( open( my $test,$file ),		'opening without IO layer' );
is( readline( $test ), $teststring,		'check prefixed content' );
ok( close( $test ),			'close test file' );
}

# Check prefix when reading. Required PerlIO functionality...albeit pointless!

ok(
 open( my $in,'<:via(Logger)', $file ),
 "opening '$file' for reading"
);
my $teststring2 = "[$daynum][$daynum]Some Line\n";
is( readline($in), $teststring2,		'read from the previously created file' );
ok( close( $in ),			'close reading file' );

ok( unlink( $file ),			"remove test file '$file'" );

