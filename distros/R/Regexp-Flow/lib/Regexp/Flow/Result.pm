package Regexp::Flow::Result;
use strict;
use warnings;

use Moo;

=head1 NAME

Regexp::Flow::Result - container for information about a Regexp match.

=head1 DESCRIPTION

This is a subclass of C<Regexp::Result>. It adds methods and attributes
which are useful to have in the same object.

=cut

extends 'Regexp::Result';

=head1 OVERLOADING

In a boolean context, this returns true if the match was a success.

=cut

use overload
	'0+'=>sub{shift->success}; #~ for some reason \&success does not work here

=head1 METHODS

=head3 success

C<1> or C<0>; default C<undef>. Indicates if the match was a success.

=cut

has success => (
	is => 'rw',
	default => sub{ undef },
);

=head3 continue_action

C<next> or C<last>; default C<next>. Used to control if C<m//g> and
C<s///g> continue to operate. See the C<last> method.

=cut

has continue_action => (
	is => 'rw',
	default => sub{'next'},
);

=head3 last

Invoke this method to set C<continue_action> to C<"last">. This
prevents further coderefs being executed by
C<Regexp::Flow::re_matches> or C<Regexp::Flow::re_substitutions>.
Note that this does not exit the current subroutine.

=cut

sub last {
	my $self = shift;
	$self->continue_action('last');
	return $self;
}

=head3 string

The string before the regexp was executed. Note that when globally
matching, the string is the same for all results - the string is only
changed when all the matches have been found.

=cut

has string => (
	is => 'rw',
	default => sub{ undef },
);

=head3 re

The regular expression in use.

=cut

has re => (
	is => 'rw',
	default => sub{ undef },
);

=head1 SEE ALSO

Regexp::Flow - which uses this module
(also for author and copyright information)

=cut

1;
