package Process::Backgroundable;

use 5.005;
use strict;
use Storable          ();
use File::Temp        ();
use IPC::Run3         ();
use Process::Storable ();

use vars qw{$VERSION @ISA @PERLCMD};
BEGIN {
	$VERSION = '0.21';
	@ISA     = 'Process::Storable';

	# Contains the command to use to launch perl
	# Should be the path to the perl current running.
	# People with special needs should localise this
	# to add any flags.
	@PERLCMD = ( $^X );
}

sub background {
	my $self = shift;

	# Dump the object to the input filehandle
	my $stdin = File::Temp::tempfile();
	$self->serialize( $stdin );
	seek( $stdin, 0, 0 );

	# Generate the command
	my $cmd = [ @PERLCMD, '-MProcess::Launcher', '-e serialized', ref($self) ];

	# Fire the command
	IPC::Run3::run3( $cmd, $stdin, \undef, \undef );

	return 1;
}

1;

__END__

=pod

=head1 NAME

Process::Backgroundable - A Process::Storable object that can be backgrounded

=head1 SYNOPSIS

  # Background a finite length process
  MyCacheCleaner->new( dir => '...', maxsize => '10 meg' )->background;
  
  # Background an infinite length process
  MyWebServer->new( dir => '...' )->background;

=head1 DESCRIPTION

C<Process::Backgroundable> extends L<Process::Storable> for the purpose of
create process objects that can be run in the background and detached
from the main process.

It adds a C<background> method that (rather than fork), launches a new
copy of Perl, passing the L<Process> to it using L<Process::Launcher>,
which will load and execute the process.

Please note that both the C<STDOUT> and C<STDERR> for the backgrounded
process will be sent to F</dev/null> (or your equivalent) so there is
no way to recieve any output from the background process, and you will
not be notified if it exits.

If you want to add logging or locks or some other feature to your
backgrounded process, that is your responsibility, and you set them up
in the C<prepare> method.

=head1 METHODS

This method inherits all the normal methods from L<Process> and in
addition inherits the strict seperation of responsibility described
in L<Process::Storable>. You should be aware of both of these.

=head2 background

The C<background> is provided by default, and will start another
instance of the same Perl you are current running, although not
necesarily with the same environment.

This allows you to use C<Process::Backgroundable> in very large applications
that may contain other data that will not be so amenable to normal
forking.

=head1 BUGS

This is implemented with L<IPC::Run3> calls for now, but we might have
to move to L<Proc::Background> for more robustness later on.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process-Backgroundable>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
