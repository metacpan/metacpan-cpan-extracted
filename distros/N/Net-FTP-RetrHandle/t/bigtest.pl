
warn "f1=$f1, f2=$f2\n";
for my $i (1..10)
{
  my($l1,$l2);
  ok($l1 = $f1->getline,"Read line $i from local file");
  ok($l2 = $f2->getline,"Read line $i from remote file");

  is($l1,$l2,"Comparing line $i from local and remote files");
}

# seek
ok(seek($f1,-10,SEEK_END),"local seek");
ok($f2->seek(-10,SEEK_END),"remote seek");

# getc/ungetc
for my $i (1..10)
{
  my($c1,$c2);
  ok(defined($c1 = $f1->getc),"getc #$i in local file");
  ok(defined($c2 = $f2->getc),"getc #$i in remote file");
  is($c1,$c2,"Comparing getc #$i");

  $f1->ungetc(ord($c1));
  $f2->ungetc(ord($c2));
  ok(defined($c1 = $f1->getc),"getc #$i in local file after ungetc");
  ok(defined($c2 = $f2->getc),"getc #$i in remote file after ungetc");
  is($c1,$c2,"Comparing getc #$i after ungetc");
}

ok(!defined($f1->getc),"at EOF in local file after getc");
ok(!defined($f2->getc),"at EOF in remote file after getc");

# read

ok(seek($f1,-8320,SEEK_END),"local seek for read test");
ok($f2->seek(-8320,SEEK_END),"remote seek for read test"); 

{
  my($b1,$b2);
  for my $i (1..65)
  {
    my $s1 = $f1->read($b1,128,defined($b1)?length($b1):0);
    my $s2 = $f2->read($b2,128,defined($b2)?length($b2):0);
    ok((defined($s1) and ($s1 >= 1)),"reading local part $i in read test");
    ok((defined($s2) and ($s2 >= 1)),"reading remote part $i in read test");
    ok((length($b1) == (128 * $i) and length($b2) == (128*$i)),
       "block $i is right size in read test");
    is($b1,$b2,"read test blocks $i are identical");
  }

  ok($f1->read($b1,128) == 0, "local EOF after read test");
  ok($f2->read($b1,128) == 0, "remote EOF after read test");
}

# Backwards seeking
{
  $f2->{max_skipsize} = 1;
  
  my($b1,$b2);
  for my $i (1..5)
  {
    ok(seek($f1,-8192*$i,SEEK_END),"local seek #$i in backwards seek test");
    ok($f2->seek(-8192*$i,SEEK_END),"remote seek #$i in backwards seek test");
    ok(($f2->tell() == $f2->{size} - 8192 * $i),"remote tell 1 in backwards seek test"); 
    ok($f1->read($b1,128),"local read #$i in backwards seek test");
    ok($f2->read($b2,128),"remote read #$i in backwards seek test");
    ok((length($b1) == 128 and length($b2) == 128),
       "block $i is right size in backwards seek test");
    is($b1,$b2,"matching read #$i in backwards seek test");
    ok(($f2->tell() == $f2->{size} - 8192 * $i + 128),"remote tell 2 in backwards seek test"); 
  }
}

# sysseek/sysread
{
  $f2->{max_skipsize} = 1;
  
  my($b1,$b2);
  for my $i (1..5)
  {
    ok(sysseek($f1,-8192*$i,SEEK_END),"local seek #$i in backwards sysseek test");
    ok($f2->sysseek(-8192*$i,SEEK_END),"remote seek #$i in backwards sysseek test");
    ok($f1->sysread($b1,128),"local read #$i in backwards seek test");
    ok($f2->sysread($b2,128),"remote read #$i in backwards seek test");
    ok((length($b1) == 128 and length($b2) == 128),
       "block $i is right size in backwards sysseek test");
    is($b1,$b2,"matching read #$i in backwards sysseek test");
  }
}

# getlines
# This also tests EOF/getline.
ok(seek($f1,-8192,SEEK_END),"local seek for getlines test");
ok($f2->seek(-8192,SEEK_END),"remote seek for getlines test");
my @l1 = $f1->getlines;
my @l2 = $f2->getlines;
ok($#l1 == $#l2,"local and remote files had same number of lines in getlines test");
for my $i (0..$#l1)
{
  is($l1[$i], $l2[$i], "line $i in getlines test");
}

# eof()
ok(seek($f1,0,SEEK_END),"local seek for eof test");
ok($f2->seek(0,SEEK_END),"remote seek for eof test");
ok($f1->eof(),"local eof test");
ok($f2->eof(),"remote eof test");

ok($f1->close(),"close local filehandle");
ok($f2->close(),"close remote filehandle");

# Now try a different file.
$f2 = Net::FTP::RetrHandle->new($ftp,'no.such.file');
ok(!defined($f2),"getting nonexistent filehandle");

1;
