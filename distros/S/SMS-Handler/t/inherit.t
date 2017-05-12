# This -*- perl -*- code tests the calling protocol

# $Id: inherit.t,v 1.3 2002/12/06 15:50:31 lem Exp $

use Test::More tests => 2;
use SMS::Handler;

sub foo { 1; }			# Used to avoid warnings spoiling our test
				# output.

				# Define a funny class to work with, with no
				# ->handle method
package SMS::Handler::Crap;
@ISA = qw( SMS::Handler );
sub new { return bless {}, 'SMS::Handler::Crap'; }

package main;

				# Now fake its use...

my $crap = new SMS::Handler::Crap;

eval { local $SIG{__WARN__} = \&foo; $ret = $crap->eval('hello world'); };

				# This would be the default ->handle
				# method included in SMS::Handler...
ok($@, "Default ->handle() method");

				# Now, suppose our funny class had a
				# ->handle method. Note that the return
				# value is intentionally bogus.
*SMS::Handler::Crap::handle = sub { 'Hello World'; };

				# This is to avoid a warning from
				# showing up, about not using a variable
				# more than once.
*SMS::Handler::Crap::handle || 1;

package main;

				# The call should return SMS_OK, proving
				# it called our ->handle method.

eval { local $SIG{__WARN__} = \&foo; $ret = $crap->handle('hello world'); };
ok($ret eq 'Hello World', "Overriden ->handle() method");

