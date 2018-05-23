package MyCPAN::Indexer::NullTester;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( __PACKAGE__ );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::NullTester - Do nothing components

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the class you
want to do nothing:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::NullTester

=head1 DESCRIPTION

This class implements all of the methods needed by all of the
component classes. Thes methods don't do anything, so they can be
useful to ignore parts of the system while you focus on developing
another. For instance, you might use this module as the
reporter_class, since it does nothing, which you work on the
dispatcher_class.

=head2 Methods

=over 4

=item component_type

This is a composite component, although you don't have to use all of them
at the same time.

=cut

sub component_type
	{
	$_[0]->combine_types(
		map { my $m = "${_}_type"; $_[0]->$m() }
		qw(indexer queue worker dispatcher reporter interface)
		);
	}

=item Indexer class: get_indexer( HASH_REF )

C<get_indexer> adds a C<indexer_callback> key to HASH_REF. The value of
C<indexer_callback> is a no-op subroutine.

The C<run> subroutine is a no-op too.

=cut

sub get_indexer { $_[0]->set_note( 'indexer_callback', sub { 1 } ) }
sub run         { 1 }

=item Queue class: get_queue( HASH_REF )

C<get_queue> adds a C<queue> key to HASH_REF. The value of
C<queue> is an empty

=cut

sub get_queue { $_[0]->set_note( 'queue', [] ) }

=item Worker class: get_task( HASH_REF )

C<get_task> adds a C<child_task> key to HASH_REF. The value of
C<child_task> is a code reference that returns 1 and does nothing else.

=cut

sub get_task { $_[0]->set_note( 'child_task', sub { 1 } ) }

=item Reporter class: get_reporter( HASH_REF )

C<get_reporter> adds a C<reporter> key to HASH_REF. The value of
C<reporter> is a code reference that returns 1 and does nothing else.

=cut

sub get_reporter { $_[0]->set_note( 'reporter', sub { 1 } ) }

=item Dispatcher class: get_dispatcher()

C<get_dispatcher> adds a dispatcher key to HASH_REF. The value is an
object that responds to the start and finish methods, but does
nothing. C<get_dispatcher> also sets the C<interface_callback> key to
a code reference that returns 1 and does nothing else.

=cut

BEGIN {
	package MyCPAN::Indexer::NullTester::Dispatcher;
	sub new { bless '', $_[0] }
	sub start  { 1 };
	sub finish { 1 };
	}

sub get_dispatcher
	{
	$_[0]->set_note('child_task', MyCPAN::Indexer::NullTester::Dispatcher->new );
	$_[0]->set_note('interface_callback', sub { 1 } );
	}

=item Interface class: do_interface( HASH_REF )

C<do_interface> simly returns 1.

=cut

sub do_interface { 1 }

=back

=head1 SEE ALSO

MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
