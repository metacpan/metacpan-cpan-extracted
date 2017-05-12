#!/usr/bin/perl -w

use strict;

#use constant CPAN_HOST => 'ftp.cpan.org'; # 'cpan.cse.msu.edu';
#use constant CPAN_DIR => '/pub/CPAN'; # '/';
use constant CPAN_HOST => 'cpan.cse.msu.edu';
use constant CPAN_DIR => '/';
use constant CPAN_FILE => 'MIRRORED.BY';


use Net::FTP;
use Net::FTP::RetrHandle;
use IO::Handle;
use Fcntl ':seek';
use Test::More tests => 432;
use Symbol;

our $ftp = Net::FTP->new(CPAN_HOST,
			$ENV{DEBUG} ? (Debug => 1) : ()
			)
    or die "Couldn't FTP to : $!\n";
ok($ftp,"Connect to @{[ CPAN_HOST ]}");
ok($ftp->login('ftp','testing@example.com'),"Login anonymously to @{[ CPAN_HOST ]}");
ok($ftp->cwd(CPAN_DIR),"chdir(@{[ CPAN_DIR ]}) on @{[ CPAN_HOST ]}");
ok($ftp->get(CPAN_FILE),"Get @{[ CPAN_FILE ]} from @{[ CPAN_DIR ]} on @{[ CPAN_HOST ]}");

our($f1,$f2);
ok(open($f1,CPAN_FILE),"Opening local copy of @{[ CPAN_FILE ]} ($!)");
$f2 = gensym;
ok((tie *$f2,'Net::FTP::RetrHandle', $ftp, CPAN_FILE),
   "tying var to Net::FTP::RetrHandle");

SKIP: {
  skip "Your Perl version may not support readline on tied objects properly",30
    if ($] < 5.008);
       
  for my $i (1..10)
  {
    my($l1,$l2);
    $l1 = <$f1>;
    $l2 = <$f2>;
    ok(defined($l1),"Read line $i from local file");
    ok(defined($l2),"Read line $i from remote file");

    is($l1,$l2,"Comparing line $i from local and remote files");
  }
}

# seek
ok(seek($f1,-10,SEEK_END),"local seek");
ok(seek(*$f2,-10,SEEK_END),"remote seek");

# getc/ungetc
for my $i (1..10)
{
  my($c1,$c2);
  ok(defined($c1 = getc($f1)),"getc #$i in local file");
  ok(defined($c2 = getc($f2)),"getc #$i in remote file");
  is($c1,$c2,"Comparing getc #$i");
}

ok(!defined(getc($f1)),"at EOF in local file after getc");
ok(!defined(getc($f2)),"at EOF in remote file after getc");

# read

ok(seek($f1,-8320,SEEK_END),"local seek for read test");
ok(seek($f2,-8320,SEEK_END),"remote seek for read test"); 

{
  my($b1,$b2);
  for my $i (1..65)
  {
    my $s1 = read($f1,$b1,128,defined($b1)?length($b1):0);
    my $s2 = read($f2,$b2,128,defined($b2)?length($b2):0);
    ok((defined($s1) and ($s1 >= 1)),"reading local part $i in read test");
    ok((defined($s2) and ($s2 >= 1)),"reading remote part $i in read test");
    ok((length($b1) == (128 * $i) and length($b2) == (128*$i)),
       "block $i is right size in read test");
    is($b1,$b2,"read test blocks $i are identical");
  }

  ok(read($f1,$b1,128) == 0, "local EOF after read test");
  ok(read($f2,$b1,128) == 0, "remote EOF after read test");
}

# Backwards seeking
{
  my $obj = tied(*$f2)
    or die "Couldn't get tied object for f2\n";
  $obj->{max_skipsize} = 1;
  
  my($b1,$b2);
  for my $i (1..5)
  {
    ok(seek($f1,-8192*$i,SEEK_END),"local seek #$i in backwards seek test");
    ok(seek($f2,-8192*$i,SEEK_END),"remote seek #$i in backwards seek test");
    ok((tell($f2) == $obj->{size} - 8192 * $i),"remote tell 1 in backwards seek test"); 
    ok(read($f1,$b1,128),"local read #$i in backwards seek test");
    ok(read($f2,$b2,128),"remote read #$i in backwards seek test");
    ok((length($b1) == 128 and length($b2) == 128),
       "block $i is right size in backwards seek test");
    is($b1,$b2,"matching read #$i in backwards seek test");
    ok((tell($f2) == $obj->{size} - 8192 * $i + 128),"remote tell 2 in backwards seek test"); 
  }
}


# big seek
{
  my($b1,$b2);
  ok(seek($f1,0,SEEK_SET),"local seek 1 in big seek test");
  ok(defined(seek($f2,0,SEEK_SET)),"remote seek 1 in big seek test");
  ok(read($f1,$b1,128),"local read 1 in big seek test");
  ok(read($f2,$b2,128),"remote read 1 in big seek test");
  ok((length($b1) == 128 and length($b2) == 128),
     "block 2 is right size in big seek test");
  is($b1,$b2,"matching read 1 in big seek test");
  
  ok(seek($f1,40000,SEEK_SET),"local seek 2 in big seek test");
  ok(seek($f2,40000,SEEK_SET),"remote seek 2 in big seek test");
  ok(read($f1,$b1,128),"local read 2 in big seek test");
  ok(read($f2,$b2,128),"remote read 2 in big seek test");
  ok((length($b1) == 128 and length($b2) == 128),
     "block 2 is right size in big seek test");
  is($b1,$b2,"matching read 2 in big seek test");
  
  ok(seek($f1,100000,SEEK_SET),"local seek 3 in big seek test");
  ok(seek($f2,100000,SEEK_SET),"remote seek 3 in big seek test");
  ok(read($f1,$b1,128),"local read 3 in big seek test");
  ok(read($f2,$b2,128),"remote read 3 in big seek test");
  ok((length($b1) == 128 and length($b2) == 128),
     "block 3 is right size in big seek test");
  is($b1,$b2,"matching read 3 in big seek test");
}

# sysseek/sysread
{
  my($b1,$b2);
  for my $i (1..5)
  {
    ok(sysseek($f1,-8192*$i,SEEK_END),"local seek #$i in backwards sysseek test");
    ok(sysseek($f2,-8192*$i,SEEK_END),"remote seek #$i in backwards sysseek test");
    ok(sysread($f1,$b1,128),"local read #$i in backwards seek test");
    ok(sysread($f2,$b2,128),"remote read #$i in backwards seek test");
    ok((length($b1) == 128 and length($b2) == 128),
       "block $i is right size in backwards sysseek test");
    is($b1,$b2,"matching read #$i in backwards sysseek test");
  }
}

# getlines
# This also tests EOF/getline.
SKIP: {
  skip "Your Perl version may not support readline on tied objects properly",4
    if ($] < 5.008);
  ok(seek($f1,-8192,SEEK_END),"local seek for getlines test");
  ok(seek($f2,-8192,SEEK_END),"remote seek for getlines test");
  my @l1 = <$f1>;
  my @l2 = <$f2>;
  ok($#l1 == $#l2,"local and remote files had same number of lines in getlines test");
  my $match = 0;
  for my $i (0..$#l1)
  {
    if ($l1[$i] eq $l2[$i])
    {
      $match++;
    }
  }
  ok($match == scalar(@l1),"all lines matched in getlines test");
}


# eof()
ok(seek($f1,0,SEEK_END),"local seek for eof test");
ok(seek($f2,0,SEEK_END),"remote seek for eof test");
ok(eof($f1),"local eof test");
ok(eof($f2),"remote eof test");

ok(close($f1),"close local filehandle");
ok(close($f2),"close remote filehandle");

1;
