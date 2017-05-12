BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
    unless (find PerlIO::Layer 'perlio') {
        print "1..0 # Skip: PerlIO not used\n";
        exit 0;
    }
}

use strict;
use warnings;
use Test::More tests => 26;

BEGIN { use_ok('PerlIO::via::LineNumber') }

can_ok( 'PerlIO::via::LineNumber',qw(line format increment) );
cmp_ok( PerlIO::via::LineNumber->line,'==',1,	'check line number, #1' );
is( PerlIO::via::LineNumber->format,'%4d %s',	'check format, #1' );
cmp_ok( PerlIO::via::LineNumber->increment,'==',1,'check increment, #1' );

my $file = 'test.ln';

# Check numbering when writing

ok(
 open( my $out,'>:via(PerlIO::via::LineNumber)', $file ),
 "opening '$file' for writing"
);

ok( (print $out <<EOD),		'print to file' );
This is a text
with a number
of lines that
will get numbers
prefixed.
EOD
ok( close( $out ),			'closing writing handle' );

# Check numbering without layers

{
local $/ = undef;
ok( open( my $test,$file ),		'opening without layer' );
is( readline( $test ),<<EOD,		'check numbered content' );
   1 This is a text
   2 with a number
   3 of lines that
   4 will get numbers
   5 prefixed.
EOD
ok( close( $test ),			'close test handle' );
}

PerlIO::via::LineNumber->line( 1001 );
PerlIO::via::LineNumber->format( '%04d %s' );
cmp_ok( PerlIO::via::LineNumber->line,'==',1001,'check line number, #2' );
is( PerlIO::via::LineNumber->format,'%04d %s',	'check format, #2' );
cmp_ok( PerlIO::via::LineNumber->increment,'==',1,'check increment, #2' );

# Check numbering when reading

ok(
 open( my $in,'<:via(LineNumber)', $file ),
 "opening '$file' for reading"
);
is( join( '',<$in> ),<<EOD,		'read from file numbered, #1' );
1001    1 This is a text
1002    2 with a number
1003    3 of lines that
1004    4 will get numbers
1005    5 prefixed.
EOD
ok( close( $in ),			'close reading handle numbered, #1' );

use_ok('PerlIO::via::LineNumber', increment => 10);
cmp_ok( PerlIO::via::LineNumber->line,'==',10,'check line number, #3' );
is( PerlIO::via::LineNumber->format,'%04d %s',	'check format, #3' );
cmp_ok( PerlIO::via::LineNumber->increment,'==',10,'check increment, #3' );

# Check numbering when reading

ok(
 open( $in,'<:via(LineNumber)', $file ),
 "opening '$file' for reading"
);
PerlIO::via::LineNumber->format( 'whoopee' );
is( PerlIO::via::LineNumber->format,'whoopee',	'check format, #4' );
is( join( '',<$in> ),<<EOD,		'read from file numbered, #2' );
0010    1 This is a text
0020    2 with a number
0030    3 of lines that
0040    4 will get numbers
0050    5 prefixed.
EOD
ok( close( $in ),			'close reading handle numbered, #2' );

# Remove whatever we created now

ok( unlink( $file ),			"remove test file '$file'" );
1 while unlink $file; # multiversioned filesystems
