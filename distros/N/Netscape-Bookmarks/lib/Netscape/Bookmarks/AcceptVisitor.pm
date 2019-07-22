package Netscape::Bookmarks::AcceptVisitor;

use strict;
use subs qw();
use vars qw($VERSION);

$VERSION = "2.304";

sub visitor {
	my( $self, $visitor ) = @_;

	unless( ref $visitor and $visitor->can('visit') ) {
		return;
		}

	return $visitor->visit( $self );
	}

1;

__END__

=encoding utf8

=head1 NAME

Netscape::Bookmarks::AcceptVisitor - a base class to accept Visitor object

=head1 SYNOPSIS

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

Any Netscape bookmarks object can accept a visitor object.  Call
the visitor() method on the object with the Vistor object as the
argument.

	$object->visitor( $visitor );

Although all of the classes in Netscape::Bookmarks currently use
Netscape::Bookmarks::AcceptVisitor,  that may not always be the
case if I decide that a particular object needs a different
visitor() method.  Always can the visitor() method on the
object rather than something else (which I do not tell you
about so you won't do it).

=head1 DESCRIPTION

The Visitor must define a visit() method which accepts the visited
object as an argument.  The visitor() method returns undef if
the visitor object does not have a visit() method.  Inside the
visit() method you can do whatever you like.  The return value of
visitor() is the return value of visit.

=head2 Example Visitor class

This example shows the bare minimum of a Visitor for Netscape::Bookmarks.
This example increments a count for each object it encounters, which
you might want to do to measure the granularity of link categorization
(i.e. category to bookmark ratio).  The new() method does whatever has
to be done to create the Visitor object.

	package MyVisitor;

	use vars qw( %Class_count );

	sub new { ... }

	sub visit
		{
		my( $self, $object ) = @_;

		my $class = ref $object;

		$Class_count{$class}++
		}

	__END__

I use this visitor in as I traverse the Bookmarks tree:

	use MyVisitor;

	my $visitor = MyVisitor->new();

	my $netscape = Netscape::Bookmarks->new( 'bookmarks.html');

	# introduce() traverses for us
	$netscape->introduce( $visitor );

=head1 EXAMPLES

Some examples come with the Netscape::Bookmarks distribution.
See examples/Visitor.pm, for instance.

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.


=head1 SEE ALSO

L<Netscape::Bookmarks>

=cut


