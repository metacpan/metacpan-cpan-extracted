use Benchmark ':all';

sub arrayskip1 { shift; @_ }           # Fastest
sub arrayskip2 { @_[ 1 .. $#_ ] }      # Slowest
sub arrayskip3 { @_[ 1 .. (@_-1) ] }   # Surprisingly slightly faster than arrayskip2
sub arrayskip4 { shift; return @_ }    # Slightly slower than arrayskip1

sub v1 { my @r = arrayskip1(1 .. 10) }
sub v2 { my @r = arrayskip2(1 .. 10) }
sub v3 { my @r = arrayskip3(1 .. 10) }
sub v4 { my @r = arrayskip4(1 .. 10) }

cmpthese(250_000, {
	v1   => \&v1,
	v2   => \&v2,
	v3   => \&v3,
	v4   => \&v4,
});