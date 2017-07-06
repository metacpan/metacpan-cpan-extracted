#!/usr/bin/env perl

# This blows up on at least 5.20.3 64 bit Linux non-threaded
# with Sub::Attribute 0.05 and Class::Trigger 0.14. But the
# bug is sensitive as hell, depending on deep C stuff and when
# perl decides to grow/re-allocate a stack
#
# taken from https://rt.perl.org/Ticket/Display.html?id=126145

# See also https://github.com/test-class-moose/test-class-moose/issues/78


package Foo;

use Test::More;
END { done_testing }

use Sub::Attribute;
use Class::Trigger;

sub Crash :ATTR_SUB {
    shift->add_trigger(x => sub { });
}

pass("Yay, I didn't blow up!");

package Bar;

use base 'Foo';

sub f01 :Crash { }
sub f02 :Crash { }
sub f03 :Crash { }
sub f04 :Crash { }
sub f05 :Crash { }
sub f06 :Crash { }
sub f07 :Crash { }
sub f08 :Crash { }
sub f09 :Crash { }
sub f10 :Crash { }
sub f11 :Crash { }
sub f12 :Crash { }
sub f13 :Crash { }
sub f14 :Crash { }
sub f15 :Crash { }
sub f16 :Crash { }
sub f17 :Crash { }
sub f18 :Crash { }
sub f19 :Crash { }
sub f20 :Crash { }
sub f21 :Crash { }
sub f22 :Crash { }
sub f23 :Crash { }
sub f24 :Crash { }
sub f25 :Crash { }
sub f26 :Crash { }
sub f27 :Crash { }
sub f28 :Crash { }
sub f29 :Crash { }
sub f30 :Crash { }
sub f31 :Crash { }
sub f32 :Crash { }
sub f33 :Crash { }
sub f34 :Crash { }
sub f35 :Crash { }
sub f36 :Crash { }
sub f37 :Crash { }
sub f38 :Crash { }
sub f39 :Crash { }
sub f40 :Crash { }
sub f41 :Crash { }
sub f42 :Crash { }
sub f43 :Crash { }
sub f44 :Crash { }
sub f45 :Crash { }
sub f46 :Crash { }
sub f47 :Crash { }
sub f48 :Crash { }
sub f49 :Crash { }
sub f50 :Crash { }
