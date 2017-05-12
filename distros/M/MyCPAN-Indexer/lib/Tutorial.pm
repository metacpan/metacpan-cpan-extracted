package MyCPAN::Indexer::Tutorial;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.28';

=head1 NAME

MyCPAN::Indexer::Tutorial - How the backpan_indexer.pl pieces fit together

=head1 DESCRIPTION

The C<MyCPAN::Indexer> system lets you plug in different components to
control major portions of the process of examining Perl distributions
and collating the results. It's up to each component to obey its
interface and do that parts the other components expect it to do. The
idea is to decouple some of these bits as much as possible.

As C<backpan_indexer.pl> does its work, it stores information about
its components in an anonymous hash called C<notes>. The different
components have access to this hash. (To Do: this is some pretty bad
design smell, but that's how it is right now).

Specific implementations will impose other requirements not listed
in this tutorial.

=head1 The Application

The application is the bit that you write when you want to do
something very specialized with a different process. The application
object controls the big picture.

See C<MyCPAN::Indexer::App::BackPAN>, the module version, and
C<backpan_indexer.pl>, the script version.

=head1 The Coordinator

The coordinator is just a way for the components to talk to each other.
The application starts up, creates a coordinator object, and stores it. The
application gives a reference to the coordinator to every component.

When the application creates components, it tells each of about the coordinator.
Each component can talk to the coordinator to get to parts of the application
it doesn't directly know about. Each component tells the coordinator about
itself so the coordinator can talk to any component.

The coordinator maintains the "notes", which are arbitrary bits of information
that components use to pass information around.

See C<MyCPAN::Indexer::Coordinator>.

=head1 The Indexer

Most of the work to examine a Perl distribution is in C<MyCPAN::Indexer>. When
it gets down to it, everything C<MyCPAN> knows about Perl distributions is in
there. It has a C<run()> method which handles the examination. It kicks off
C<examine>, which figures out what to do by getting a list of steps from
C<examine_dist_steps>.

This technique is common throughout C<MyCPAN::Indexer>. One method returns a 
list of methods to run. This way, a subclass can control the process by overriding
the method that returns the steps.

The basic class is C<MyCPAN::Indexer>, but C<MyCPAN::Indexer::TestCensus> is
an example of another indexing class.

=head1 Components

=head2 The Queue class

The Queue class is responsible for getting the list of distributions to
process.

C<backpan_indexer.pl> calls C<get_queue> and passes it a ConfigReader::Simple
object. C<get_queue> does whatever it needs to do, then returns an array
reference of file paths to process. Each path should represent a single
Perl distribution.

Implements:

	get_queue()

Creates in C<notes>:

	queue - a reference to the array reference returned by get_queue.

Expects in C<notes>:

	nothing
	
To Do: The Queue class should really be an iterator of some sort. Instead
of returning an array (which it can't change), return an iterator.

=head2 The Worker class

The Worker class returns the anonymous subroutine that the interface
class calls for each of its cycles. Inside that code reference, do the
actual indexing work, including saving the results.
C<backpan_indexer.pl> calls C<get_task> with a reference to its
C<notes> hash.

Implements:

	get_task()

Creates in C<notes>

	child_task - a reference to the code reference returned by get_task.

Expects in C<notes>

	nothing
	
To Do: There should be a storage class which the worker class hands
the results to.

=head2 The Reporter class

The Reporter class implements the bits to store the result of the
Worker class. C<backpan_indexer.pl> calls C<get_reporter> with a
reference to its C<notes> hash.

Implements:

	get_reporter( $info )

Creates in C<notes>:

	reporter - the code ref to handle storing the information

Expects in C<notes>:

	nothing

Expects in config:

	nothing
	
=head2 The Dispatcher class

The Dispatcher class implements the bits to hand out work to the
worker class. The Interface class, discussed next, repeatedly calls
the interface_callback code ref the Dispatcher class provides.

Implements:

	get_dispatcher()

Creates in C<notes>

	dispatcher - the dispatcher object, with start and finish methods
	interface_callback - a code ref to call repeatedly in the Interface class

Expects in C<notes>

	child_task - the code ref that handles indexing a single dist
	queue      - the array ref of dist paths

=head1 The Interface class

The Interface class really has two jobs. It makes the live reporting
interface  while C<backpan_indexer.pl> runs, at it repeatedly calls
the dispatcher to start new work.

Implements:

	do_interface()

Creates in C<notes>:

	nothing

Expects in C<notes>

	interface_callback - a code ref to call repeatedly in the Interface class

=head1 SEE ALSO

MyCPAN::Indexer

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
