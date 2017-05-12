#!perl

use strict;
use warnings;
use Test::More tests => 14;

use Sys::Mmap;
use Errno qw(EINVAL);

{
    my $foo;
    eval {munmap($foo)};
    like($@, qr/^undef variable not unmappable /, "munmap detects undef perl variables and fails");
}

{
    my $foo = "234";
    undef($foo);
    eval {munmap($foo)};
    like($@, qr/^undef variable not unmappable /, "munmap detects undef perl variables and fails");
}

{
    eval {munmap(undef)};
    like($@, qr/^undef variable not unmappable /, "munmap detects undef perl variables and fails");
}

SKIP: {
    skip "BSD kernels can't unmap a bad pointer like linux kernels can", 4 if($^O =~ m/bsd/i || $^O =~ m/darwin/i);
    foreach my $foo ("", "1234", "1.232", "abcdefg" ){
	eval {munmap($foo)};
	ok($! == EINVAL, "Unmapped strings die");
    }
}

SKIP: {
    skip "BSD kernels can't unmap a bad pointer like linux kernels can", 7 if($^O =~ m/bsd/i || $^O =~ m/darwin/i);
    foreach my $foo (-1283843, -1, 0, 1, 2222131, 2.3451, -1213.12 ){
	eval {munmap($foo)};
	like($@, qr/^variable is not a string/, "munmap detects ints and floats and fails");
    }
}
