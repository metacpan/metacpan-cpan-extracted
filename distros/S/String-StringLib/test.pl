# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
    $| = 1;
    @b = ("as

df",
	  "asdf",
	  " asdf",
	  "asdf ",
	  "a s d f ",
	  " a s d f ",
	  "as df");
    @L = ("  asdf",
	  " 	
 asdf"
	 );
    @N = ("asdf");
    @T = (
	  "asdf 	 ",
	  "asdf 	 
"
	 );
    @B = (
	  "  asdf   ",
	 );
    
    @a = (@B, @L, @T, @N);
    @b = (@a, @b);
    @L = (@L, @N);
    @T = (@T, @N);
    $t = 1 + @a + @b + @L + @T + 4;

    print "1..$t\n";
}
END {print "not ok 1\n" unless $loaded;}
use String::StringLib;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$t = 'asdf';
for ($i = 0, $b = 2; $i <= $#a; $i++, $b++) {
    $_ = $a[$i];
    StripLTSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $b\n";
}
$q = undef;
StripLTSpace($q);
print defined($q) ? 'not ' : '','ok ',$b++,"\n";

for ($i = 0; $i <= $#b; $i++, $b++) {
    $_ = $b[$i];
    StripSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $b\n";
}
$q = undef;
StripSpace($q);
print defined($q) ? 'not ' : '','ok ',$b++,"\n";

for ($i = 0; $i <= $#L; $i++, $b++) {
    $_ = $L[$i];
    StripLSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $b\n";
}
$q = undef;
StripLSpace($q);
print defined($q) ? 'not ' : '','ok ',$b++,"\n";

for ($i = 0; $i <= $#T; $i++, $b++) {
    $_ = $T[$i];
    StripTSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $b\n";
}
$q = undef;
StripTSpace($q);
print defined($q) ? 'not ' : '','ok ',$b++,"\n";

