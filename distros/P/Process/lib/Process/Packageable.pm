package Process::Packageable;

use 5.00503;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

# Sample implementation for dependencies method
sub dependencies {
	return( perl => '5.00503' );
}


1;

__END__

=pod

=head1 NAME

Process::Packageable - Process that can be packaged with its dependencies

=head1 SYNOPSIS

  # In MyPackageableProcess.pm:
  package MyPackageableProcess;
  
  use strict;
  use base qw{
           Process
           Process::Storable
           Process::Packageable
  };
  
  # Add your dependencies to your parent class's if you like
  sub dependencies {
      my $self = shift;
      return (
          $self->SUPER::dependencies(),
          'Some::Class::Name' => '1.01',
          'Another::Class'    => '0.03',
          ...
      );
  }
  
  # Now as usual for Process subclasses:
  sub new {
      ...
  }
  
  sub prepare {
      ...
  }
  
  sub run {
      ...
  }
  
  
  
  # in user code:
  my $object = MyPackageableProcess->new( foo => 'bar' );
  
  # Find out about the object's explicit class dependencies
  my @dependencies = $object->dependencies();
  # key/value pairs in @dependencies, but with duplicates

=head1 DESCRIPTION

C<Process::Packageable> provides a role (an additional interface
and set of rules) that allow for L<Process> objects to be packaged
into a L<Process::Packaged> object together with the C<Process>
object's dependencies.

Inheriting from C<Process::Packageable> in a C<Process> subclass, you
agree to implement the C<dependencies> method as documented below.
A sample C<dependencies> method which just requires a minimum perl
version (5.005) is implemented by C<Process::Packageable>.

In addition, you need to make sure that any dependencies of your
subclass can be correctly identified by the L<Module::ScanDeps>
module. In order to identify your Process's dependencies,
a run of C<Module::ScanDeps> should suffice.

Furthermore, your subclass needs to be serializable. That means it
has to be a subclass of L<Process::Serializable>. You may either
implement your own serialization code or inherit from
L<Process::Storable>, L<Process::YAML> or other
C<Process::Serializable> subclasses.

=head2 Note on Process::Packaged

C<Process::Packaged> is not part of the C<Process> distribution.

A C<Process::Packaged> object can be "frozen"
to a string, moved around, and then be "thawed" back into an object again.
(A C<Process::Packaged> object is a C<Process::Serializable> object.)

During the reconstruction of the C<Process::Packaged> object, it
extracts the dependencies of the C<Process::Packageable> object, checks
whether the dependencies are okay, and loads the class of the packaged
object.

A C<Process> must be packageable whenever it is serializable. Please refer
to L<Process::Serializable> for details on when that is the case.

=head1 METHODS

=head2 dependencies

  my @dependency_list = $object->dependencies;

The C<dependencies> method returns a list of class names and respective
version strings that describe the dependencies of your C<Process>
subclass. There are no parameters to C<dependencies()>.

The returned list has class names and respective version
strings interleaved. The classes will be mapped to distributions which
will be mapped to files by C<Process::Packaged>.

Specifying a C<'0'> as a version indicates I<any version>.

There is a special key word C<perl> which can be used to set a dependency
on a minimum perl version. (perl isn't packaged, though.)

Dependencies on modules that are not pure Perl might not be packaged
and extracted correctly.

The default implementation of C<dependencies> returns

  'perl', '5.005'

You are expected to override it. In order to make your class
subclassable, you should include the dependencies of your parent class
into the returned list of dependencies. The SYNOPSIS has an example
implementation.

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
