#!/usr/local/bin/perl  -I./blib/arch -I./blib/lib
print "1..6\n";
no warnings;
my @stringstodo;
push(@stringstodo, qq|what?!|);
push(@stringstodo, qq|hello|);
push(@stringstodo, qq|Testing |.chr(02).qq| stx|);
push(@stringstodo, qq|end of test|);
use lib "./blib/arch";
use lib "./blib/lib";
#use String::LRC qw(lrc getPerlLRC);
require String::LRC;
my $i = 0;
foreach my $string (@stringstodo){
$i++;
my $lrc = String::LRC::getPerlLRC($string, length($string));
my $lrc2 = String::LRC::lrc($string);
print qq|The LRC for "$string"|;
print qq||.($lrc eq $lrc2 ? qq| (LRC = "$lrc" [ASCII |.ord($lrc).qq|])\n| 
	.qq|ok $i\n|
	:  qq|(Perl says LRC = "$lrc" [#|.ord($lrc)
	.qq|] String::LRC says LRC = "$lrc2" [#|.ord($lrc2).qq|])\n| 
	."not ok $i\n"
	).qq||;
}# for
my $string = shift(@stringstodo);

 $i++;
 my @loop = (chr(31),undef,chr(21),undef,chr(30));
 print "Test the LRC for sub-strings (using lrc initialized to previous lrc)\n";
 my $v1;
 for (my $j = 0; $j < length($string); $j = $j + 2) {
  my $subs = substr($string, $j, 2);
  $v1 = String::LRC::lrc($subs, $v1);
  my $ov1 = ord($v1);
  my $lo = ord($loop[$j]);
  if ($v1 ne $loop[$j]) { last; } elsif ($j == 0) { print "ok $i\n"; }
  print ($v1 eq $loop[$j] ? 
	"" #" Got $v1 for '$subs'\n" 
	: "not ok $j (had $v1 [#$ov1] for '$subs' expected $loop[$j] [#$lo])\n");
 } # for

  $i++;
  $string = "t";
  print "Test the LRC for a single char\n";
  my $v1 = String::LRC::lrc($string);
  print ($v1 eq $string ? "ok $i\n" : "not ok $i\n");

