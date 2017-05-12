use strict;
use warnings;
use lib "../../lib/", "../lib", "lib/";
use Python::Decorator debug => 1;
use Carp qw(confess);

sub loginout {
    my $f = shift;
    return sub {
	print "entering sub\n";
	&$f(@_);
	print "leaving sub\n";
    };
}

@loginout
@loginout
@loginout
@loginout
sub foo {
    print "running foo()\n";
}

foo();
