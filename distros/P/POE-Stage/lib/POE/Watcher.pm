# $Id: Watcher.pm 155 2007-02-15 05:09:17Z rcaputo $

package POE::Watcher;

use warnings;
use strict;

use POE::Callback;

=head1 NAME

POE::Watcher - a base class for POE::Stage's event watchers

=head1 SYNOPSIS

	This module is meant to be subclassed, not used directly.

=head1 DESCRIPTION

POE::Watcher is a base class for POE::Stage event watchers.  It is
purely virtual at this time.  Common watcher code will eventually be
hoisted into this class once patterns emerge in the subclasses.

POE::Watcher classes encapsulate POE::Kernel's event watchers.  They
allocate POE::Kernel watchers at creation time, and they release them
during destruction.  It is therefore important to keep references to
POE::Watcher objects until they are no longer needed.

The best place to store POE::Watcher objects is probably the current
stage's request closure.  Should the request be canceled for some
reason, its closure will be destroyed, and so will all the watchers
stored within it.  Use of this convention automates automatic cascaded
cleanup when a request is canceled.

=head2 new HASHREF

Create a new POE::Watcher.  Calls init() on the subclass to do the
actual constructing.

=cut

sub new {
	my ($class, %arg) = @_;
	foreach my $arg_name (keys %arg) {
		next unless $arg_name =~ /^on_(\S+)/ and ref($arg{$arg_name}) eq "CODE";
		$arg{$arg_name} = POE::Callback->new(
			{
				name => "$class $arg_name",
				code => $arg{$arg_name},
			}
		);
	}

	return $class->init(%arg);
}

sub init {
	warn "subclass without init";
}

=head1 DESIGN GOALS

Provide a simpler, extensible interface to POE::Kernel event watchers.
Watcher classes may be extended through common OO techniques.

Remove the need to memorize positional values.  Watchers and their
events use named parameters.

Watcher destruction is triggered by Perl reference counting rather
than an explicit count maintained in the library.  Watchers' lifetimes
are explicit and easily understood.

Watcher cleanup is automated.  As long as watcher objects are stored
in the current request, they will automatically be cleaned up when the
request ends.

Watchers are restartable.  A POE::Watcher object can outlive the
POE::Kernel resource it hides.  It can be restarted, using the same
parameters to create another POE::Kernel resource.

=head1 BUGS

See L<http://thirdlobe.com/projects/poe-stage/report/1> for known
issues.  See L<http://thirdlobe.com/projects/poe-stage/newticket> to
report one.

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.

=head1 SEE ALSO

POE::Watcher subclasses may have additional features and methods.
Please see their corresponding documentation.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Watcher is Copyright 2005-2006 by Rocco Caputo.  All rights are
reserved.  You may use, modify, and/or distribute this module under
the same terms as Perl itself.

=cut

1;
