
package Proc::JobQueue::FakeCanonical;

use strict;
use warnings;

sub new
{
	return bless {};
}

sub myname
{
	return 'localhost';
}

sub canonicalize
{
	return $_[1];
}

1;

