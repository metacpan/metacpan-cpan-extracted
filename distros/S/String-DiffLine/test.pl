# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::DiffLine qw(diffline);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my @tests=(
           [2 ,sub{},        ["abcdef"       ,"abcxyz"      ],[3,1,3],    ],
           [3 ,sub{},        ["abcdef"       ,"abc"         ],[3,1,3],	  ],
           [4 ,sub{},        ["abc"          ,"abc"         ],[undef,1,3],],
           [5 ,sub{},        ["abc\ndefg"    ,"abc\ndxy"    ],[5,2,1],	  ],
           [6 ,sub{},        ["abc\n\ndefg"  ,"abc\n\ndxy"  ],[6,3,1],	  ],
           [7 ,sub{},        ["abc\ndef\n"   ,"abc\ndef\n"  ],[undef,3,0],],
           [8 ,sub{$/="x"},  ["abcxdefg"     ,"abcxdefy"    ],[7,2,3],	  ],
           [9 ,sub{$/=""} ,  ["abc\n\n\ndefg","abc\n\n\nxy" ],[6,2,0],	  ],
           [10,sub{$/="121"},["1212121def"   ,"1212121dex"  ],[9,3,2],	  ],
           [11,sub{$/="112"},["11121112de"   ,"11121112df"  ],[9,3,1],    ],
           [12,sub{$/="112"},["112112x"      ,"112112ab"    ],[6,3,0],    ],
          );

foreach my $test (@tests)
{
  my($n,$s,$in,$tout)=@$test;
  &$s;
  my(@in2)=@$in; 
  my $nl=$/;
  s/\n/\\n/g foreach ($nl,@in2);
  my(@out2)=my(@out)=diffline($in->[0],$in->[1]);
  my $fail=grep($_ ne shift @out,@$tout);
  local $"=",";
  print "\$/=$nl in=@in2 out=@out2 expected=@$tout\n";
  printf "%s %d\n",($fail?"not ok":"ok"),$n;
}
