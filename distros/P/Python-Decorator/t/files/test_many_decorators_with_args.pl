use strict;
use warnings;
use lib "../../lib/", "../lib", "lib/";
use Python::Decorator debug => 1;
use Carp qw(confess);

sub loginout {
    my $name = shift;
    return sub {
	my $f = shift;
	return sub {
	    print "entering sub $name\n";
	    &$f(@_);
	    print "leaving sub $name\n";
	};
    };
}

sub debug {
    my ($a,$b) = @_;
    return sub {
	my $f = shift;
	return sub {
	    print "debug says $a $b before call\n";
	    &$f();
	    print "debug says $a $b after call\n";
	}
    };
}

sub memoize {
    my $f = shift;
    return sub {
	print "well, this is where we could return memoized results\n";
	&$f();
	print "and this is where we could memoize results\n";
    };
}

@memoize
@debug("just another","perl hacker")
@loginout('foo')
sub foo {
    print "running foo()\n";
}

foo();
