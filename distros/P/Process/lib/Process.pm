package Process;

use 5.00503;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

sub new     { bless {}, shift }
sub prepare { 1 }
sub run     { 1 }

1;

__END__

=pod

=head1 NAME

Process - Objects that represent generic computational processes

=head1 SYNOPSIS

  # Create the process
  my $object = MyProcess->new( ... )
      or die("Invalid configuration format");
  
  # Initialize it
  $object->prepare
      or die("Configuration not supportable");
  
  # Execute the process
  $object->run
      or die("Error while trying to execute the process");

=head1 DESCRIPTION

There are a great number of situations in which you may want to
model a computational process as an object.

An implementation of this sort of object generally looks like the following
when somebody uses it.

  my $object = MyProcessThingy->new( ... );
  
  my $rv = $object->run;
  
  if ( $rv ) {
      print "Thingy ran ok";
  } else {
      print "Failed to run thingy";
  }

The C<Process> family of modules are intended to be used as base and
role classes for these types of objects. They are used to help identify
process objects, and enforce a common API on these objects.

The primary intent is to provide a common base for objects that will be
able to be used with various distributed processing systems, without
itself actually implementing any form of distributed system.

The scope of uses for Process includes solutions to address the following
scenarios.

=over 4

=item A single CPU on a single host

=item Multiple CPUs on a single host

=item Multiple hosts on a single network

=item Hosts distributed across the internet

=item Any processing resource accessible via any mechanism

=back

To put it another way, this family of classes is intended to addresses
the separation of concerns between the processing of something, and the
results of something.

The actual ways in which the processes are run, and the handling of the
results of the process are outside the scope of these classes.

The C<Process> class itself is the root of all of these classes. In fact,
it is so abstract that it contains no functionality at all, and serves
primarily to indicate that an object obeys the general rules of a
C<Process> class.

Most of the basic C<Process> modules are similar. They define how your
object should behave (an API for a particular concept) without
dictating a particular implementation.

However, by using them, you are confirming to some processing system
that your objects will obey particular rules, and thus can interact
sanely with any processing system that follows the API.

=head2 What You Can and Cannot Do

The use of C<Process> is mainly about making guarantees. Because this is
Perl, it is not necesarily about enforcing those guarantees in a strict
way. These sorts of guarantees need to be implemented at a language level
to be meaningful in any case (for example, Perl's tainting or Haskell's
monads). You may still hang yourself, but it's your own fault if you do.

=over 4

=item You may not alter the API of the three core methods

It's always tempting to say "This acts like Foo, but we added an extra
return condition for method bar". You may not do this.

C<Process> and a few other members of the family dictate all possible
return values for C<new>, C<prepare> and C<run>, and what state the
objects should be in before and after these methods are called in the
various cases. You may not break these rules, because larger systems
will be depending on them to allow your objects to work with them
flexibly and flawlessly.

=item You may not store data in the surrounding Perl environment

A C<Process> object should be entirely self-contained when you are told
to be. If your process is involved in creating or transforming
information, then your implementation should keep these results inside
the C<Process> object. Do not store data elsewhere. This means no globals
and no class-level variables. You can't leave error messages in a
global C<$errstr> variable, as some Perl modules do.

This does not mean you can't store data in files. For C<Process> objects
that generate vast quantities of data it would be unwieldy to limit you
to holding all data in memory at once. However any object data that
refers to files should use absolute paths.

=item You may not assume the timing of new and prepare.

Most uses of C<Process> will involve scheduling, transport, or
otherwise mean that once a processing system has a C<Process> object,
it won't get to it immediately.

You should not assume that C<prepare> will be run immediately after
C<new> or in the same interpretor. You B<may> however
assume that C<run> B<is> run immediately after C<prepare>, and B<is>
in the same interpreter.

=item You may not assume an object is unchanged after C<run>

A C<Process> object may be unchanged after C<run>. Then again, it may
also be completely changed, and have accumulated all sorts of data in
it.

This also means that you should not assume that a C<Process> object
can be run again after it completes. A specific class
L<Process::Repeatable> will be provided at a later date for this
case.

=item You may not interrelate with other Process objects

In the default case, all C<Process> objects are considered to be
independent and standalone. They may not have any form of dependency
on other C<Process> objects, and they should not expect to communicate
with any other C<Process> objects.

If you choose to add this type of functionality to your particular class
that is fine, but any processing system will not be aware of this and
thus will not be doing anything to help you out.

L<Process::Depends> will be provided at a later date for this case.

=back

=head1 METHODS

=head2 new

  my $object = MyClass->new( $configuration );
  if ( $object and $object->isa('Process') ) {
  	print "Object created.\n";
  } else {
  	print "Configuration not valid.\n";
  }

The C<new> constructor is required for all classes. It takes zero or more
arbitrary params, with the specifics of any params outside the scope of
this module. The specifics of any params are to be determined by each
specific class.

A default implementation which ignores any params and creates an empty
object of a C<HASH> type is provided as a convenience. However it should
not be assumed that all objects will be a C<HASH> type.

For objects that subclass only the base C<Process> class, and are not
also subclasses of things like L<Process::Storable>, the param-checking
done in C<new> should be thorough and and objects should be correct,
with problems at C<run>-time the exception rather than the rule.

Returns a new C<Process> object on success.

For blame-free "Cannot support process in this Perl interpreter" failure,
return false.

For failure with blame, may return a string or any other value that is not
itself a C<Process> object.

However, if you need to communicate failure, you should consider
putting your param-checking in a C<prepare> method and attaching the
failure messages to the object itself. You should NEVER store errors
in the class, as all C<Process> classes are forbidden to use class-level
data storage.

=head2 prepare

  unless ( $object->prepare ) {
  	# Failed
  	die "Failed to prepare process";
  }
	
The C<prepare> method is used to check object params and bind platform
resources.

The concept of object creation in C<new> is separated from the concept
of checking and binding to support storage and transportation in some
subclasses.

Because many systems that make use of C<Process> do so through the
desire to push process requests across a network and have them executed
on a remote host, C<Process> provides the C<prepare> method as
a means to separate the checking of the params for general correctness
from checking of params relative to the system and interpreter the
process is being run on. It additionally provides a good way to have
the bulk of serious errors remain attached to the object, and have them
transported back across to the requesting entity.

Execution platforms are required to call C<run> immediately or nearly
immediately after C<prepare>. Generally the only tasks done between
C<prepare> and C<run> will be things like starting timers, setting flags
and signalling to any requestor that the process is ok, and about to
start.

As a result you are encouraged to do all locking of files, socket ports,
database handles and so on in C<prepare>, as they B<will> be used
immediately. Thus the only execution errors coming from C<run> should be
due to unexpected changes, race-condition events in the short gap
between C<prepare> and C<run>, or some error that could not possibly be
detected until part way through the C<run>.

To restate, resource binding and checking should be done in C<prepare>
if at all possible.

A default null implementation is provided for you which does nothing
and returns true.

Returns true if all params check out ok, and all system resources
needed for the execution are bound correctly.

Returns false if not, with any errors to be propagated via storage in
the object itself, for example in a C<-E<gt>{errstr}> attribute.

The object should B<not> return errors via exceptions. If you expect
something within B<your> code to potentially result in an exception,
you should trap the exception and return false.

You should B<not> expect the object to be L<Storable> or in any other
way usable once the C<Process> object is C<prepare>'ed. The object
is wound up and poised ready to C<run> and that is the B<only> thing
you should do with it.

=head2 run

  my $rv = $object->run;
  if ( $rv ) {
  	print "Process completed successfully\n";
  } else {
  	print "Process interupted, or unexpected error\n";
  }

The C<run> method is used to execute the process. It should do all
appropriate processing and calculation and detach from all relevant
resources before returning.

If your process has any results, they should be stored inside the
C<Process> object itself, and retrieved via an additional method
of your choice after the C<run> call.

A default implementation which does nothing and returns true is
provided.

Returns true if the C<Process> was completed fully, regardless of any
results from the process.

Returns false if the process was interrupted, or an unexpected
error occurs. In the default case for C<Process>, no distinction is
made between the process being interrupted legitimately and any other
type of unexpected failure.

If the process returns false, it should not be assumed that the process
can be restarted or rerun. It should be discarded or returned to the
requestor to check for specific errors.

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
