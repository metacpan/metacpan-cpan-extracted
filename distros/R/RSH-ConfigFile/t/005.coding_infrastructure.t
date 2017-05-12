# -*- perl -*-

# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# 05-coding_infrastructure.t - tests the stuff ConfigFile uses to work, like
# Exception and SmartHash.
# 
# @author  Matt Luker
# @version $Revision: 3249 $

# 05-coding_infrastructure.t - tests the stuff ConfigFile uses to work, like
# Exception and SmartHash.
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;

use RSH::Exception;

# Test 1

{ 
	my $ex = new RSH::Exception;
	diag("string \$ex: $ex");
	ok(($ex =~ m/Exception!/), "stringify 1");
};

# Test 2

{ 
	my $ex = new RSH::Exception message => 'Foo went boom!';
	diag("string \$ex: $ex");
	ok(($ex =~ m/Foo went boom!/), "stringify 2");
};

# Test 3

{ 
	my $ex = new RSH::Exception error_code => 'FOO199';
	diag("string \$ex: $ex");
	ok(($ex =~ m/FOO199/), "stringify 3");
};

# Test 4

{ 
	my $ex = new RSH::Exception error_code => 'FOO199', message => 'Foo went boom!';
	diag("string \$ex: $ex");
	ok(($ex =~ m/FOO199: Foo went boom!/), "stringify 4");
};

# Test 5

{ 
	eval {
		my $ex = new RSH::Exception error_code => 'FOO199', message => 'Foo went boom!';
		die $ex;
	};
	if (catch('', $@)) {
		pass('catch anything');
	} else {
		fail('catch anything');
	}
};

# Test 6

{ 
	eval {
		my $ex = new RSH::Exception error_code => 'FOO199', message => 'Foo went boom!';
		die $ex;
	};
	if (catch('RSH::Exception', $@)) {
		pass('catch specific 1');
	} else {
		fail('catch specific 1');
	}
};

# Test 7

{ 
	eval {
		die "Just a string";
	};
	if (catch('RSH::Exception', $@)) {
		fail('catch specific 2');
	} else {
		pass('catch specific 2');
	}
};

# Test 8

{ 
	eval {
		my $ex = new RSH::Exception error_code => 'FOO199', message => 'Foo went boom!';
		die $ex;
	};
	my $result = catch 'RSH::Exception', $@, sub { 
		pass('catch alternate syntax 1');
	};

	if (not $result) {
		fail('catch specific 2');
	}
};

# ******************** SmartHash Tests ********************

use RSH::SmartHash;

my %default = ( foo => 'bar' );
my %vals = ( moo => 'kar' );

tie %defhash, 'RSH::SmartHash', default => \%default, values => \%vals;

# Test 9

ok(($defhash{'moo'} eq 'kar'), 'value test');

# Test 10

ok(($defhash{'foo'} eq 'bar'), 'default value test');

# Test 11
my @keys = keys %defhash;
ok(($keys[0] eq 'moo'), 'keys test (no default keys)');

# Test 12
my $dirty = 0;
sub changed { $dirty = 1; }
(tied(%defhash))->{change_callback} = \&changed;
$defhash{foo} = 'barchanged';
ok(($dirty == 1), 'change callback');


exit 0;

# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.4  2004/04/09 06:18:26  kostya
#  Added quote escaping capabilities.
#
#  Revision 1.3  2004/01/15 01:01:24  kostya
#  Updated tests.
#
#  Revision 1.2  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
# 
# ------------------------------------------------------------------------------

__END__
