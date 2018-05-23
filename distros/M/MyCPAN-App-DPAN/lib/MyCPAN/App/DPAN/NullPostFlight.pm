package MyCPAN::App::DPAN::NullPostFlight;
use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

MyCPAN::App::DPAN::SVNPostFlight - A No-op postflight class

=head1 SYNOPSIS

Use this from C<dpan> by specifying it as the C<postflight_class> class:

	# in dpan.conf
	postflight_class  MyCPAN::App::DPAN::NullPostFlight

=head1 DESCRIPTION

This class is an example for a user-defined class to run at the end of
C<dpan>'s normal processing. The class only needs to provide a C<run>
method, which is automatically called by C<dpan>. Be careful that you
don't import anything called C<run> (looking at you, C<IPC::Run>)!

This example merely prints a message to show you that it ran. You might
want to use this class while you're trying to work out your process
but you don't want to do any post flight processing just yet.

=head2 Logging

This module has no logging.

=head2 Writing your own

If you want to maek your own class, check out the source for C<run>. The
code comments explain what you should be doing. After that it's up to you
to figure out what to do.

=head2 Methods

=over 4

=item run

C<dpan> calls this method automtically.

=cut

sub run
	{
	# dpan calls this as a class method after it runs
	# $application->cleanup. All of dpan's work is done and it's removed
	# most of its mess. You're picking up control just before it would
	# normally exit.
	#
	# The only argument is the $application object.
	my( $class, $application ) = @_;

	# The coordinator object has references to all of the other components
	# and the application notes. See MyCPAN::Indexer::Tutorial and
	# MyCPAN::Indexer::Coordinator for more information
	my $coordinator = $application->get_coordinator;

	# The Coordinator knows how to get the configuration object
	my $config      = $coordinator->get_config;

	print "I'm the null postflight class and I'm done before I start!\n";

	return 1;
	}

=back

=head1 SEE ALSO

MyCPAN::App::DPAN, dpan

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
