use strict;
use warnings;
use lib "../../lib/", "../lib", "lib/";
use Python::Decorator debug => 1;
use Carp qw(confess);

my $st = q/
@thisisnotarealdecorator
sub foo {
   1;
}
/;

sub loginout {
    my $f = shift;
    return sub {
	print "entering sub\n";
	&$f(@_);
	print "leaving sub\n";
    };
}

@loginout
sub foo {
    print "running foo()\n";
}

foo();
