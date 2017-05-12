# $Id: App.pm 146 2007-01-07 06:51:22Z rcaputo $

=head1 NAME

POE::Stage::App - a base class for POE::Stage applications

=head1 SYNOPSIS

	#!/usr/bin/env perl
	{
		package App;
		use POE::Stage::App qw(:base);
		sub on_run {
			print "hello, ", my $arg_whom, "!\n";
		}
	}
	App->new->run( whom => "world" );
	exit;

=head1 DESCRIPTION

POE::Stage::App is a base class for a POE::Stage-based program's main
code.  It's used to bootstrap the initial stage from which messages
can be sent, and it provides an abstract run() method that kicks off
the program's main message dispatch loop.

=cut

package POE::Stage::App;

use POE::Stage qw(:base);

=head1 PUBLIC METHODS

POE::Stage::App exists to provide a single method: run().

=head2 run ARGUMENT_PAIRS

run() instantiates the application, sends a message to its "on_run"
method, and starts the framework's main dispatch loop.  The
ARGUMENT_PAIRS given to App->run(...) are passed as parameters to the
application's on_run() method.

run() will not return until the application is finished.  Most
examples follow run() with C<exit> as a reminder of this fact.

=cut

sub run {
	my ($self, @args) = @_;
	my $main_request = POE::Request->new(
		stage => $self,
		method => "on_run",
		args => { @args },
	);
	POE::Kernel->run();
}

=head1 BUGS

See L<http://thirdlobe.com/projects/poe-stage/report/1> for known
issues.  See L<http://thirdlobe.com/projects/poe-stage/newticket> to
report a problem.

=head1 SEE ALSO

POE::Stage is the base class for message-driven objects.
POE::Request is the base class for POE::Stage messages.
POE::Watcher is the base class for event watchers.

L<http://thirdlobe.com/projects/poe-stage/> - POE::Stage is hosted
here.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Stage is Copyright 2005-2006 by Rocco Caputo.  All rights are
reserved.  You may use, modify, and/or distribute this module under
the same terms as Perl itself.

=cut

1;
