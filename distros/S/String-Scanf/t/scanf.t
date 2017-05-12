use String::Scanf;

print "1..135\n";

($i, $s, $x) = sscanf('%d %3s %g', ' -5_678     abc 3.14e-99 9');

print 'not ' unless ($i == -5678);
print "ok 1\n";

print 'not ' unless ($s eq 'abc');
print "ok 2\n";

print 'not ' unless ($x == 3.14e-99);
print "ok 3\n";

($x, $y, $z) = sscanf('%i%3[a-e]%2c', ' 42acxde');

print 'not ' unless ($x == 42);
print "ok 4\n";

print 'not ' unless ($y eq 'ac');
print "ok 5\n";

print 'not ' unless ($$z[0] == ord("x") and $$z[1] == ord("d"));
print "ok 6\n";

($a, $b) = sscanf('%2$d %1$d', '12 34');

print 'not ' unless ($a == 34);
print "ok 7\n";

print 'not ' unless ($b == 12);
print "ok 8\n";

($h, $o, $hh, $oo) = sscanf('%x %o %x %o', '0xa_b_c_d 0234_5 3_45_6 45_67');

print 'not ' unless ($h == 0xabcd);
print "ok 9\n";

print 'not ' unless ($o == 02345);
print "ok 10\n";

print 'not ' unless ($hh == 0x3456);
print "ok 11\n";

print 'not ' unless ($oo == 04567);
print "ok 12\n";

($a, $b, $c) = sscanf("%f %f %f", "123. 0123. 0123");

print 'not ' unless ($a == 123);
print "ok 13\n";

print 'not ' unless ($b == 123);
print "ok 14\n";

print 'not ' unless ($c == 123);
print "ok 15\n";

($a, $b, $c) = sscanf("%f %f %f", "+123. +0123. +0123");

print 'not ' unless ($a == 123);
print "ok 16\n";

print 'not ' unless ($b == 123);
print "ok 17\n";

print 'not ' unless ($c == 123);
print "ok 18\n";

($a, $b, $c) = sscanf("%f %f %f", "-123. -0123. -0123");

print 'not ' unless ($a == -123);
print "ok 19\n";

print 'not ' unless ($b == -123);
print "ok 20\n";

print 'not ' unless ($c == -123);
print "ok 21\n";

$line = "2002-08-19 16:03:00  65.2  88.7 111131.65 +170911.2    64.017681122   102375.7472  65.2  88.7 111131.15 +170918.3    64.014927982  -102336.8523 12:03";

($year, $month, $day, $hour, $min, $sec, $elR, $azR, $HMSR, $DMSR, $RTTR, $DopR, $elT, $azT, $HMST, $DMST, $RTTT, $DopT, $local) = sscanf("%f-%f-%f %f:%f:%f %f%f%f%f%f%f%f%lf%lf%lf%lf%lf %s", $line);

sub arecibo {
    print 'not '
	unless ($year == 2002 && $month == 8 && $day == 19 &&
	        $hour == 16   && $min   == 3 && $sec == 0  &&
	        $elR  == 65.2 && $azR == 88.7 &&
	        $HMSR == 111131.65 && $DMSR == 170911.2 &&
	        $RTTR == 64.017681122 && $DopR == 102375.7472 &&
	        $elT == 65.2 && $azT == 88.7 &&
	        $HMST == 111131.15 && $DMST == 170918.3 &&
	        $RTTT == 64.014927982 && $DopT == -102336.8523 &&
	        $local eq "12:03");
}

arecibo;
print "ok 22\n";

($year, $month, $day, $hour, $min, $sec, $elR, $azR, $HMSR, $DMSR, $RTTR, $DopR, $elT, $azT, $HMST, $DMST, $RTTT, $DopT, $local) = sscanf("%d-%d-%d %d:%d:%d %f%f%f%f%f%f%f%lf%lf%lf%lf%lf %s", $line);

arecibo;
print "ok 23\n";

if ($] < 5.005) {
  print "ok 24 # skip in Perl $]\n";
  print "ok 25 # skip in Perl $]\n";
} else {
  my $s = String::Scanf->new("%d");

  my @s1 = $s->sscanf("123");
  print "not " unless @s1 == 1 && $s1[0] == 123;
  print "ok 24\n";

  $_ = "456";
  my @s2 = $s->sscanf();
  print "not " unless @s2 == 1 && $s2[0] == 456;
  print "ok 25\n";
}

my $t = 26;

sub eps () { 1e-50 }

while (<DATA>) {
  chomp;
  ($f, $d, $e) = split(/\s*;\s*/);
  my @r = sscanf($f, $d);
  my @e = split(/\s*,\s*/,$e);
  my $i;
  for ($i = 0; $i < @e; $i++) {
    unless (($e[$i] =~ /^[\d-]/ && ($e[$i] - $r[$i]) < eps) || $e[$i] eq $r[$i]) {
      last;
    }
  }
  unless ($i == @e) {
    print "not ok $t # [@r] [@e]\n";
  } else {
    print "ok $t\n";
  }
  $t++;
}

__DATA__
%d	; 123		; 123
%d	; +123		; 123
%d	; -123		; -123
%d	; 0123		; 123
%d	; 1_2_3		; 123
%d	; d123		; 
%i	; 123		; 123
%i	; +123		; 123
%i	; -123		; -123
%i	; 0123		; 123
%i	; 1_2_3		; 123
%d	; d123		; 
%u	; 123		; 123
%u	; +123		; 123
%u	; -123		; 
%u	; 0123		; 123
%u	; 1_2_3		; 123
%u	; u123		; 
%e	; 1		; 1
%e	; 1.		; 1
%e	; 1.23		; 1.23
%e	; .23		; 0.23
%e	; +1		; 1
%e	; +1.		; 1
%e	; +1.23		; 1.23
%e	; +.23		; 0.23
%e	; -1		; -1
%e	; -1.		; -1
%e	; -1.23		; -1.23
%e	; -.23		; -0.23
%e	; 1e45		; 1e45
%e	; 1.e45		; 1e45
%e	; 1.23e45	; 1.23e45
%e	; .23e45	; 0.23e45
%e	; +1e45		; 1e45
%e	; +1.e45	; 1e45
%e	; +1.23e45	; 1.23e45
%e	; +.23e45	; 0.23e45
%e	; -1e45		; -1e45
%e	; -1.e45	; -1e45
%e	; -1.23e45	; -1.23e45
%e	; -.23e45	; -0.23e45
%e	; 1e-45		; 1e-45
%e	; 1.e-45	; 1e-45
%e	; 1.23e-45	; 1.23e-45
%e	; .23e-45	; 0.23e-45
%e	; +1e-45	; 1e-45
%e	; +1.e-45	; 1e-45
%e	; +1.23e-45	; 1.23e-45
%e	; +.23e-45	; 0.23e-45
%e	; -1e-45	; -1e-45
%e	; -1.e-45	; -1e-45
%e	; -1.23e-45	; -1.23e-45
%e	; -.23e-45	; -0.23e-45
%e	; 1e045		; 1e45
%e	; 1.e045	; 1e45
%e	; 1.23e045	; 1.23e45
%e	; .23e045	; 0.23e45
%e	; +1e045	; 1e45
%e	; +1.e045	; 1e45
%e	; +1.23e045	; 1.23e45
%e	; +.23e045	; 0.23e45
%e	; -1e045	; -1e45
%e	; -1.e045	; -1e45
%e	; -1.23e045	; -1.23e45
%e	; -.23e045	; -0.23e45
%e	; 1_2_3e4_5	; 1.23e47
%e	; 0123		; 123
%e	; e123		; 
%f	; 1		; 1
%f	; 1.		; 1
%f	; 1.23		; 1.23
%f	; .23		; 0.23
%g	; 1		; 1
%g	; 1.		; 1
%g	; 1.23		; 1.23
%g	; .23		; 0.23
%x	; a		; 10
%x	; A		; 10
%x	; 0xa		; 10
%x	; 0Xa		; 10
%x	; 11		; 17
%x	; 011		; 17
%x	; 1_1		; 17
%x	; x11		; 
%o	; 11		; 9
%o	; 011		; 9
%o	; 1_1		; 9
%o	; o11		; 
%hd	; 123		; 123
%ld	; 123		; 123
%hi	; 123		; 123
%li	; 123		; 123
%hu	; 123		; 123
%lu	; 123		; 123
%he	; 123		; 123
%le	; 123		; 123
%hx	; 123		; 291
%lx	; 123		; 291
%ho	; 123		; 83
%lo	; 123		; 83
%s	; foo bar	; foo
%s %s	; foo bar	; foo,bar
%s %s	; foo  bar	; foo,bar
%s %d	; foo  123	; foo,123
%3s%3s	; foobar	; foo,bar
%4s%2s	; foobar	; foob,ar
%2s%4s	; foobar	; fo,obar
State:%s; State: Active ; Active
n=%g    ; n=1.234       ; 1.234
