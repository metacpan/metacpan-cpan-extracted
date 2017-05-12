# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
    $| = 1;
    # @L has strings with leading space
    # @N has strings with no space
    # @B has strings with both leading and trailing space
    # @T has strings with Trailing space
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

    # @a has all strings
    @a = (@B, @L, @T, @N);
    @b = (@a, @b);
    @L = (@L, @N);
    @T = (@T, @N);
    $t = 1 + @a + @b + @L + @T + 4 + 3*4;
    print "1..$t\n";
}
END {print "not ok 1\n" unless $loaded;}
use String::Strip;
$loaded = 1;
print "ok $loaded\n";
$loaded++;

######################### End of black magic.

# At some later date, if $a is undefined, I may want to set it to ''
# The following is test code for that
# print "\$q is ";
# print "undefined" unless defined($q);
# print "defined as '$q'" if defined($q);
# print "\n";

my($i, $t, $to);
## Make sure that undef values don't come back defined
## 2..5
$_ = undef;
&StripLTSpace($_);
print defined($_) ? 'not ' : '','ok ',$loaded++,"\n";
&StripTSpace($_);
print defined($_) ? 'not ' : '','ok ',$loaded++,"\n";
&StripLSpace($_);
print defined($_) ? 'not ' : '','ok ',$loaded++,"\n";
&StripSpace($_);
print defined($_) ? 'not ' : '','ok ',$loaded++,"\n";

my(%V) = (
	  '' => '',	# 6..9
	  ' ' => '',	# 10..13
	  '   	'=> '',	# 14..17
	 );

foreach (keys %V) {
    $to = $_;
    $t = $V{$to};

    $_ = $to;
    StripLSpace($_);
    print $t eq $t ? '' : 'not ','ok ',$loaded++,"\n";
    $_ =  $to;
    StripTSpace($_);
    print $t eq $t ? '' : 'not ','ok ',$loaded++,"\n";
    $_ =  $to;
    StripSpace($_);
    print $t eq $t ? '' : 'not ','ok ',$loaded++,"\n";
    $_ =  $to;
    StripLTSpace($_);
    print $t eq $t ? '' : 'not ','ok ',$loaded++,"\n";
}

$t = 'asdf';
for ($i = 0; $i <= $#a; $i++, $loaded++) {
    $_ = $a[$i];
    &StripLTSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $loaded\n";
}

for ($i = 0; $i <= $#b; $i++, $loaded++) {
    $_ = $b[$i];
    &StripSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $loaded\n";
}

for ($i = 0; $i <= $#L; $i++, $loaded++) {
    $_ = $L[$i];
    &StripLSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $loaded\n";
}

for ($i = 0; $i <= $#T; $i++, $loaded++) {
    $_ = $T[$i];
    &StripTSpace($_);
    print $_ eq $t ? '' : 'not ',"ok $loaded\n";
}

