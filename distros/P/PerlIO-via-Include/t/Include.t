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
use Test::More tests => 10 + (2*12);

BEGIN { use_ok('PerlIO::via::Include') }

can_ok( 'PerlIO::via::Include',qw(after before regexp) );
is( PerlIO::via::Include->before,'^#include ',	'check before, #1' );
is( PerlIO::via::Include->after,"\n",		'check after, #1' );
ok( !defined( PerlIO::via::Include->regexp ),	'check regexp, #1' );

my $file = 'test.include';
my $file1 = 'test.1';
my $file2 = 'test.2';

test_this( <<EOD,<<EOD1,<<EOD2,<<RESULT );
This is the original file

\#include $file1

This is the original file again.
EOD
This is file 1

\#include $file2

This is file 1 again.
EOD1
This is file 2
and more in 2
and still 2
EOD2
This is the original file

This is file 1

This is file 2
and more in 2
and still 2

This is file 1 again.

This is the original file again.
RESULT

use_ok('PerlIO::via::Include', regexp => qr#<include file="([^"]+)"/># );
ok( !defined( PerlIO::via::Include->before ),	'check before, #2' );
ok( !defined( PerlIO::via::Include->after ),	'check after, #2' );

# fix different stringification of regexps between Perl versions
( my $regexp= PerlIO::via::Include->regexp ) =~ s#\?[^:]+#?#;
is( $regexp, '(?:<include file="([^"]+)"/>)','check regexp, #2' );

test_this( <<EOD, qq(included from 1, <include file="test.2"/>, magically), qq(included <from number="2"/>), <<RESULT );
<xml><file number="0"/>
 This is to be <include file="test.1"/> in here.
</xml>
EOD
<xml><file number="0"/>
 This is to be included from 1, included <from number="2"/>, magically in here.
</xml>
RESULT

# Remove whatever we created now

ok( unlink( $file,$file1,$file2 ),	'remove test files' );
1 while unlink( $file,$file2,$file2 ); # multiversioned filesystems


sub test_this {

  ok( open( my $out,">$file" ),	"opening '$file' for writing" );
  ok( (print $out $_[0]),	"write to '$file'" );
  ok( close( $out ),		"close writing '$file'" );

  ok( open( $out,">$file1" ),	"opening '$file1' for writing" );
  ok( (print $out $_[1]),	"write to '$file1'" );
  ok( close( $out ),		"close writing '$file1'" );

  ok( open( $out,">$file2" ),	"opening '$file2' for writing" );
  ok( (print $out $_[2]),	"write to '$file2'" );
  ok( close( $out ),		"close writing '$file2'" );

  ok(
   open( my $in,"<:via(Include)",$file ),
   "open '$file' for reading"
  );
  is( join('',<$in>),$_[3],	"check result '$file'"  );
  ok( close( $in ),		"close reading '$file'" );
}
