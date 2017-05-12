#!/usr/bin/perl

use lib "/prj/dsnew/perlmods/lib/site_perl/current";
use lib "/prj/dsnew/perlmods/lib/site_perl/current/aix";
use lib "/prj/dsnew/perlmods/lib/current";
use lib "./blib/lib";

BEGIN { $| = 1; $Ntst=12; print "1..$Ntst\n"; $tst=1; }
END { if ( $tst != $Ntst ) { print "not ok $tst\n"; } }

###############################################################################

if (defined($ENV{AUTOMATED_TESTING})) {
  while ($tst<$Ntst) {
     print "ok $tst\n";
     $tst+=1;
  }
  exit;
}

###############################################################################

print "Test $tst, loading the module and allocating screen\n";

use Term::Screen::ReadLine;

$scr = new Term::Screen::ReadLine;

print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr;

print "setstr test\n\r";

print $scr->setstr("*",10)," - ",length $scr->setstr("*",10),"\n\r";
print $scr->setstr("A",75)," - ",length $scr->setstr("A",75),"\n\r";

$N=3000;
$L=1000;

$b=time();
for (1..$N) {my $line="";
  for(1..$L) {
    $line.="*";
  }
}
$e=time()-$b;
print "$N*$L : $e secs\n\r";

$N=10000;

$b=time();
for (1..$N) {
  my $line=$scr->setstr("*",100);
}
$e=time()-$b;
print "$N*setstr($L) : $e secs\n\r";

print "\nAny key to continue:";
$scr->getch();

print "\n\rok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, Press one time Esc to escape or Two times escape?\n";

$scr->at(2,1)->puts("first input a character (Esc mode): ");
  $a=$scr->getch();
  print $a," ",length $a," ",ord($a),"\n";

$scr->at(3,1)->puts("Now input another character (EscEsc mode): ");
$scr->two_esc;
  $a=$scr->getch();
  print $a," ",length $a," ",ord($a),"\n";

$scr->one_esc;
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input a line of 40 max. (anything allowed)\n";

$scr->at(4,4)->puts(">");
$line=$scr->readline(ROW => 4, COL => 6 );

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

if ($L>40) { exit; }

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input a line of 40 max. (anything allowed), display length=20\n\r";
print "          Conversion to uppercase.\n";

$scr->at(4,4)->puts(">");
$line=$scr->readline(ROW => 4, COL => 6, DISPLAYLEN => 20, CONVERT => "up");

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input a line of 40 max. (anything allowed), display length=20\n\r";
print "          Conversion to lowercase.\n\r";
print "          Value is 'Hi There!' (should be converted)\n";

$scr->at(4,4)->puts(">");
$line=$scr->readline(
    ROW => 4,
    COL => 6,
    DISPLAYLEN => 20,
    CONVERT => "lo",
    LINE => "Hi There!"
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input a double\n";

$line=$scr->at(4,4)->puts(">")->readline(
       ROW        => 4,
       COL        => 6,
       DISPLAYLEN => 20,
       LEN        => 20,

       ONLYVALID  => "[0-9]+([,.][0-9]*)?",
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input a password (only a-z, A-Z, 0-9 and . allowed)\n";

$line=$scr->at(4,4)->puts(">")->readline(
       ROW        => 4,
       COL        => 6,
       DISPLAYLEN => 20,
       LEN        => 20,
       ONLYVALID  => "[a-zA-Z0-9.]+",
       PASSWORD   => 1
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input one letter (A-Z allowed)\n";

$line=$scr->at(4,4)->puts(">")->readline(
       ROW        => 4,
       COL        => 6,
       DISPLAYLEN => 1,
       LEN        => 1,
       ONLYVALID  => "[a-zA-Z]+",
 
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, input one letter (A-Z allowed), without Commit\n";

$line=$scr->at(4,4)->puts(">")->readline(
       ROW        => 4,
       COL        => 6,
       DISPLAYLEN => 1,
       LEN        => 1,
       ONLYVALID  => "[a-zA-Z]+",
       CONVERT    => "up",
       NOCOMMIT   => 1
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

$scr->clrscr();

$scr->at(0,0);
print "Test $tst, Read only input ;-)\n";

$line=$scr->at(4,4)->puts(">")->readline(
       ROW        => 4,
       COL        => 6,
       DISPLAYLEN => 20,
       LEN        => 20,
       ONLYVALID  => "[a-zA-Z]+",
       CONVERT    => "up",
       READONLY   => 1,
       LINE       => "Read only display",
);

$L=length $line;
$scr->at(5,5);print "%$line%, len=$L";
$scr->at(8,4)->puts("Any key to continue.")->getch();

$scr->at(20,0);
print "ok $tst\n";
$tst++;

###############################################################################

exit;



