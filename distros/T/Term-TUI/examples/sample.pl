#!/usr/bin/perl -w

use Term::TUI qw(:all);

%modes =
(".HELP"  => "This is the main help.\nNot a lot of info here.",
 "math"   => {".HELP" => "A simple calculator.  Currently it can only\n" .
                         "add and multiply in hex or decimal.",
              "add"   => [ "Add numbers together."  ,    Add,0 ],
              "mult"  => [ "Multiply numbers together.", Mult,0 ],
              "hex"   => {".HELP"  => "Math in hex.",
                          "add"   => [ "Add hex numbers together.",
                                       Add,1 ],
                          "mult"  => [ "Multiply hex numbers together.",
                                       Mult,1 ]
                         }
             },
 "string" => {".HELP" => "String operations",
              "subs"  => [ "Take STRING,POS,LEN and returns a substring.",
                           Substring ],
              "len"   => [ "Returns the length of a string.",
                           Length ]
 }
);

$flag=TUI_Run("sample",\%modes);
print "*** ABORT ***\n"  if ($flag);

print "\nScript Sample:\n\n";

TUI_Script(\%modes,"/math add 3 5; string; subs barnyard 1 3");

sub Add {
  my($hex,@nums)=@_;
  my($tot)=0;
  my($n);
  foreach $n (@nums) {
    $n=hex($n)  if ($hex);
    $tot += $n;
  }
  $tot = sprintf("%x",$tot)  if ($hex);
  TUI_Out("  Total = $tot\n");
  0;
}

sub Mult {
  my($hex,@nums)=@_;
  my($tot)=1;
  my($n);
  foreach $n (@nums) {
    $n=hex($n)  if ($hex);
    $tot *= $n;
  }
  $tot = sprintf("%x",$tot)  if ($hex);
  TUI_Out("  Total = $tot\n");
  0;
}

sub Substring {
  my($string,$pos,$len)=@_;
  $string=""  if (! defined $string);
  $pos=0  if (! defined $pos);
  $len=0  if (! defined $len);
  TUI_Out("  Substring = " . substr($string,$pos,$len) . "\n");
  0;
}

sub Length {
  my($string)=@_;
  $string=""  if (! defined $string);
  TUI_Out("  Length = " . length($string) . "\n");
  0;
}
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

