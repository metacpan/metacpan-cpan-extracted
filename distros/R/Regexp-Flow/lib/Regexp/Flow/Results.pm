package Regexp::Flow::Results;
use strict;
use warnings;
use Moo;

=head1 NAME

Regexp::Flow::Results - contains Regexp::Flow::Result objects

=head1 DESCRIPTION

The purpose of this class is to act as a container for
C<Regexp::Flow::Result> objects. The reason it is not a simple arrayref
is that is is convenient to be able to consider its boolean and integer
value, just like the result of C<m///>.

=head1 OVERLOADING

It can be treated as a plain arrayref, in which case it accesses its
contents.

It can be treated as a boolean or integer, in which cases it returns
the number of matches in the contents.

=cut

use overload
	'0+' => \&count,
	'@{}' => sub {shift->contents}, #~ not sure why, but \&contents dies
	nomethod => \&count
	;
=head3 METHODS

=cut

=head3 contents

An arrayref, empty by default, but which will contain information on
each successful match, as C<Regexp::Flow::Result> objects.

=cut

has contents => (
	is => 'rw',
	default => sub {[]},
);

=head3 count

A utility function which returns the number of successful matches.

To be determined: does this inspect them for success?

=cut

sub count {
	return scalar @{shift->contents};
}

=head3 succes

A utility function which returns true or false depending on whether
there were successful matches.

To be determined: does this inspect them for success?

=cut

sub success {
	return shift->count ? 1 : 0;
}

=head1 SEE ALSO

Regexp::Flow - which uses this module
(also for author and copyright information)

=cut

1;

