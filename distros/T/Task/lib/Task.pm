package Task;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.04';
}

1;

__END__

=pod

=head1 NAME

Task - The successor to Bundle:: for installing sets of modules

=head1 SYNOPSIS

  ### In Makefile.PL
  use inc::Module::Install;
  
  name         'Task-Foo';
  abstract     'Install the most common Foo modules';
  author       'Adam Kennedy <adamk@cpan.org>';
  version_from 'lib/Task/Foo.pm';
  license      'perl';
  
  # All the things we need for Foo
  requires     'perl'           => '5.005';
  requires     'Carp'           => 0;
  requires     'File::Basename' => 0;
  requires     'Storable'       => 0;
  requires     'Params::Util'   => '0.06';
  
  WriteAll;
  
  
  
  ### In lib/Task/Foo.pm
  package Task::Foo;
  
  use strict;
  use vars qw{$VERSION};
  BEGIN {
      $VERSION = '1.00';
  }
  
  1;

=head1 DESCRIPTION

The C<Bundle::> namespace has long served as the CPAN's "expansion"
mechanism for module installation. A C<Bundle::> module contains no code
in itself, but serves as a way to specify an entire collection of
modules/version pairs to be installed.

=head2 The Problem with C<Bundle::>

Although it has done a reasonably good job, C<Bundle::> modules suffer from
some problems.

Firstly, C<Bundle::> functionality is fairly magical. The C<Bundle::> magic 
needs to be specially implemented by the CPAN client, and a C<Bundle::>
dist is treated differently to every other type of dist.

It provides only static dependencies. That is, it only provides a
specific set of dependencies, and you cannot change the list depending
on the platform (for example, installing an extra Win32:: module if
the bundle is being installed on Windows).

Finally, it exists only in CPAN. It is not possible to take a C<Bundle::>
dist and just install it, because Makefile.PL files are irrelevant
for C<Bundle::> dists.

The irony now is that an ordinary module has far more flexible and
powerful dependency capabilities than C<Bundle::> distributions. And because
the functionality is hard-coded into the CPAN clients for the entire
C<Bundle::> namespace, moving beyond the current situation is going to
mean a change of namespace.

=head2 Requirements for a C<Bundle::> Successor

The C<Task::> namespace (modeled off the Debian packages of the same
name) is used to provide similar functionality to the traditional
C<Bundle::> namespace, but without the need to magic and special
client-side support in order to have them work.

A C<Task::> module is implemented as a normal .pm module, with only a
version defined. That .pm module itself should NOT load in all the
dependencies.

This implementation as a module allows normal Perl tools to be able
to load the module and check it's version to confirm you have the
required modules, without the need for a CPAN client involved.

Instead of using a magic POD format, the dependency specification
is implemented using the Makefile.PL, as you would for any other 
module.

This also means that if the Task needs to check for the existence of
a non-Perl application, or some other dependency, it can be done as well.

And you can adapt the dependencies based on the configuration of the
system.

For example, if a module is upgraded to repair a critical bug that applies
only for Windows platform, you can use two alternate versions based on
platform detection code, rather than needing to apply the highest version
in all cases.

This "normal" implementation also means that C<Bundle::> modules can be created
privately and no longer need to be stored in CPAN, opening up the bundling
capability to companies and other non-public users.

You should also be able to do things like encode the full dependencies for
you web application as a private C<Task::> dist and send this tarball to the
hosting company.

Their admin can then use the dist to install the required modules from CPAN
and you can be far more certain that the required modules have been
installed than in the traditional case.

=head2 Implementation

At this time the preferred implementation is done using L<Module::Install>.

L<Module::Install> allows a much more simplified syntax, and bundles the
required "Do What I Mean" functionality in the distribution itself.

This bundling removes many assumptions on what may or may not be
installed on the the destination system, as the installation logic can
be included in the dist and does not have to be first fetched from CPAN.

It also provides you with the additional functionality from the family of
L<Module::Install> extension classes. See the L<Module::Install> page for
more details.

Of course, this is merely a convention. If you wish to write your
Makefile.PL/Build.PL file using another installer, you are free to do so.

Please note that this L<Task> class provides no functionality in and of
itself, and your C<Task::> distributions do not need to inherit from it.

In general, you also should not need to provide any test scripts for your
C<Task::> distribution, although you may wish to add tests to validate the
correct installation if you wish (another option not available in C<Bundle::>
distributions).

=head1 SUPPORT

Bugs (or really, spelling mistakes) should be reported via the CPAN bug
tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
