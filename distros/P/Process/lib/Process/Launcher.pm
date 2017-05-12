package Process::Launcher;

use 5.00503;
use strict;
use Exporter              ();
use Params::Util          ();
use Process               ();
use Process::Serializable ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.30';
	@ISA     = qw{Exporter};
	@EXPORT  = qw{run run3 serialized};

	# Preload the heavyish Process::Storable module
	# (if prefork is available)
	eval "use prefork 'Process::Storable';";
}





#####################################################################
# Interface Functions

sub run() {
	my $class  = load(shift @ARGV);

	# Create the object
	my $object = $class->new( @ARGV );
	unless ( $object ) {
		fail("$class->new returned false");
	}

	# Run it
	execute($object);

	exit(0);
}

sub run3() {
	my $class = load(shift @ARGV);

	# Load the params from STDIN
	my @params = ();
	SCOPE: {
		# Implementation recycled from Config::Tiny
		local $/;
		my $input = <STDIN>;
		foreach ( split /(?:\015{1,2}\012|\015|\012)/, $input ) {
			if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
				push @params, $1, $2;
				next;
			}
			fail("Input did not match the correct format");
		}
	}

	# Create the process
	my $object = $class->new( @params );
	unless ( $object ) {
		fail("$class->new returned false");
	}

	# Run it
	execute($object);

	exit(0);
}

sub serialized() {
	my $class = load(shift @ARGV);
	unless ( $class->isa('Process::Serializable') ) {
		fail("$class is not a Process::Serializable subclass");
	}

	# Deserialize the object
	my $input  = shift @ARGV;
	my $object = $class->deserialize( $input or \*STDIN );
	unless ( $object ) {
		fail("Failed to deserialize STDIN to a $class");
	}

	# Run it
	execute($object);

	# Return the object after execution
	$object->serialize(\*STDOUT);

	exit(0);
}





#####################################################################
# Support Functions

sub execute($) {
	my $object = shift;
	my $class  = ref($object);
	if ( $object->isa('Process::Backgroundable') ) {
		close STDIN;
		my $pid = fork();
		exit(0) if $pid;
	}

	# Prepare the Process
	my $rv = eval { $object->prepare };
	fail("$class->prepare died: $@")       if $@;
	fail("$class->prepare returned false") unless $rv;

	# Run the process
	$rv = eval { $object->run };
	fail("$class->run died: $@")       if $@;
	fail("$class->run returned false") unless $rv;

	print "OK\n";
}

sub load($) {
	my $class = shift;
	unless ( Params::Util::_CLASS($class) ) {
		fail("Did not provide a valid class as first argument");
	}
	eval "require $class";
	fail("Error loading $class: $@") if $@;
	unless ( $class->isa('Process') ) {
		fail("$class is not a Process class");
	}
	$class;
}

sub fail($) {
	my $message = shift;
	$message =~ s/\n$//;
	print "FAIL - $message\n";
	exit(0);
}

1;

__END__

=pod

=head1 NAME

Process::Launcher - Execute Process objects from the command line

=head1 SYNOPSIS

  # Create from passed params and run
  perl -MProcess::Launcher -e run MyProcessClass param value
  
  # Create from STDIN params and run
  perl -MProcess::Launcher -e run3 MyProcessClass
  
  # Thaw via Storable from STDIN, and freeze back after to STDOUT
  perl -MProcess::Launcher -e storable MyProcessClass
  
  # Requires Process::YAML to be installed:
  # Thaw via YAML::Syck from STDIN, and freeze back after to STDOUT
  perl -MProcess::Launcher -e yaml MyProcessClass

=head1 DESCRIPTION

The C<Process::Launcher> module provides a mechanism for launching
and running a L<Process>-compatible object from the command line,
and returning the results.

=head2 Example Use Cases

Most use cases involve isolation. By having a C<Process> object run
inside its own interpreter, it is then free do things such as loading
in vast amounts of data and modules without bloating out the main
process.

It could provide a novel way of giving Out Of Memory (OOM) protection
to your Perl process, because when the operating system's OOM-killer
takes out the large (or runaway) process, the main program is left
intact.

It provides a way to run some piece of code in a different Perl
environment than your own. This could mean a different Perl version,
or running something with tainting on without needing the main process
to have tainting.

=head1 FUNCTIONS

All functions are imported into the callers by default.

=head2 run

The C<run> function creates an object based on the arguments passed
to the program on the command line.

The first param is take as the L<Process> class and loaded, and the
rest of the params are passed directly to the constructor.

Note that this does mean you can't pass anything more complex than
simple string pairs. If you need something more complex, try the
C<storable> function below.

Prints one line of output at the end of the process run.

  # Prints the following if the process completed correctly
  OK
  
  # Prints the following if the process does not complete
  FAIL - reason

=head2 run3

The C<run3> function is similar to the C<run> function but assumes
you are launching the process via something that makes it easy to
pass in params via C<STDIN>, such as L<IPC::Run3> (recommended)

It takes a single param of the L<Process> class.

It then readsa series of key-value pairs from C<STDIN> in the form

  param1=value
  param2=value

At the end of the input, the key/value pairs are passed to the
constructor, and from there the function behaves identically to
C<run> above, including output.

=head2 serialized

The C<serialized> function is more robust and thorough again.

It takes the name of a L<Process::Serializable> subclass as its
parameter, reads data in from C<STDIN>, then calls the
C<deserialize> method for the class to get the L<Process> object.

This object has C<prepare> and then C<run> called on it.

The same C<OK> or C<FAIL> line will be written as above, but after
that first line, the completed object will be frozen back out
via C<serialize> and written to C<STDOUT> as well.

The intent is that you create your object of the C<Process::Serializable>
subcless in your main interpreter thread, then hand it off to another
Perl instance for execution, and then optionally return it to handle
the results.

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
