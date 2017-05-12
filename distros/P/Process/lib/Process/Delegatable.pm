package Process::Delegatable;

use 5.00503;
use strict;
use File::Temp        ();
use IPC::Run3         ();
use Probe::Perl       ();
use Storable          ();
use Process::Storable ();

use vars qw{$VERSION @ISA @PERLCMD};
BEGIN {
	$VERSION = '0.30';
	@ISA     = 'Process::Storable';

	# Contains the command to use to launch perl
	# Should be the path to the perl current running.
	# People with special needs should localise this
	# to add any flags.
	@PERLCMD = ( Probe::Perl->find_perl_interpreter );
}

sub delegate {
	my $self  = shift;
	my $class = ref($self);
	my @perl  = @_ ? @_ : @PERLCMD;

	# We always pass the object by file
	my ($stdin, $filein ) = File::Temp::tempfile();
	$self->serialize($stdin);
	close($stdin);

	# Dump the object to the input filehandle,
	# and recover it afterwards
	my ($stdout, $fileout) = File::Temp::tempfile();
	# my ($stderr, $fileerr) = File::Temp::tempfile();
	close($stdout);
	# close($stderr);

	# Generate the command
	#print STDERR "Process::Delegatable STDIN  $filein\n";
	#print STDERR "Process::Delegatable STDOUT $fileout\n";
	#print STDERR "Process::Delegatable STDERR $fileerr\n";
	my $cmd = [ @perl, '-MProcess::Launcher', '-e serialized', $class, $filein ];

	# Fire the command
	# print STDERR "# " . join(' ', @$cmd) . " < $filein > $fileout\n";
	my $ok = IPC::Run3::run3( $cmd, \undef, $fileout, \undef );
	if ( ! $ok or $? != 0 ) {
		# Failed
		$self->{errstr} = "Failed to execute delegated Process";
		# $self->{stderr} = $extras;
		return 1;
	}

	# Get the first line with content of the response, which will be an OK/FAIL
	local *STDOUT2;
	open( STDOUT2, $fileout ) or die "open($fileout): $!";
	# open( STDERR2, $fileerr ) or die "open($fileerr): $!";
	my $result;
#	my $extras;
	while ( 1 ) {
		$result = <STDOUT2>;
		$result = "FAIL No output returned\n" unless defined $result;
		next unless $result =~ /\S/;
		$result =~ s/[\012\015]+\z//;
		last;
	}
	# while ( 1 ) {
		# $extras = <STDERR2>;
		# $extras = "FAIL No output returned\n" unless defined $extras;
		# next unless $extras =~ /\S/;
		# $extras =~ s/[\012\015]+\z//;
		# last;
	# }
	if ( $result eq 'OK' ) {
		# Looks good, deserialize the data
		my $complete = $class->deserialize( \*STDOUT2 );
		%$self = %$complete;

		# Clean up and return
		close( STDOUT2 );
		close( STDERR2 );
		return 1;
	} else {
		# Just clean up
		close( STDOUT2 );
		close( STDERR2 );
	}

	# Is it an error?
	if ( $result =~ s/^FAIL// ) {
		# Failed
		$self->{errstr} = $result;
		# $self->{stderr} = $extras;
		return 1;
	}

	# err...
	die "Unknown delegate response $result";
}

1;

__END__

=pod

=head1 NAME

Process::Delegatable - Run a Process::Storable object in an isolated perl

=head1 SYNOPSIS

  # Background a finite length process
  MyBigMemoryProcess->new( ... )->delegate('/opt/perl5005/perl');

=head1 DESCRIPTION

C<Process::Delegatable> extends L<Process::Storable> for the purpose of
creating process objects that can be run inside other instances, or even
other versions, of Perl, with the results of the object ending up in the
object in the current perl instance as if it had been run here.

It adds a C<delegate> method that launches a new copy of Perl, passing the
L<Process> to it using L<Process::Launcher>, which will load and execute
the process.

Please note that C<STDERR> for the delegated process will be sent to
F</dev/null> (or your equivalent) so there is no way to recieve any error
output from the delegated process.

If you want to add logging or locks or some other feature to your
delegated process, that is your responsibility, and you set them up
in the C<prepare> method.

=head1 METHODS

This method inherits all the normal methods from L<Process> and in
addition inherits the strict seperation of responsibility described
in L<Process::Storable>. You should be aware of both of these.

=head2 delegate

  $process->delegate('/opt/perl5004/perl', '-MFoo::Bar');

The C<delegate> method is provided by default, and will start another
instance of another Perl (or if no arguments, the same Perl you are
current running), although not necesarily with the same environment.

This allows you to use C<Process::Delegatable> to run Processes that may
need to allocate a large amount of memory, or need to be rigourously
seperated from your main program.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
