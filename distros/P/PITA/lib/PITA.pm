package PITA;

use 5.008;
use strict;
use PITA::XML           ();
use PITA::Guest         ();
use PITA::Guest::Driver ();

our $VERSION = '0.60';

1;

__END__

=pod

=head1 NAME

PITA - The Practical Image Testing Architecture

=head1 DESCRIPTION

The Practical Image Testing Architecture (PITA) is a collection of software
for doing Big Testing.

PITA is being created to allow the testing of any software package
in any language on any configuration of any operating system on any
hardware.

The primary focus are the various types of problems that go beyond your
individual system and setup. Problems that have typically been a
Pain In The Arse to do right.

=over 4

=item Nightly Testing

Alternatively known as Periodic Testing, this involves running the
same tests on the same code periodically (for example, nightly) to
very that code involving an external or unstable system is still
working.

=item Smoke Testing

Continuous testing of the head of a rapidly evolving software project
directly from the software repository.

=item Platform-Neutrality Testing

Testing software packages on a variety of operating systems and
configurations to ensure software works across all of them.

=item Hardware Compatibility Testing

Testing of software packages involving compiled languages on
many different processor architectures to ensure software works
on all of them.

=item Dependency Testing

Verifying that software works with the language versions it claims
to, and that there are no undeclared dependencies, or other problems
occuring during recursive dependency installs.

=item Rot Testing

"Bit rot" is a phenomenon where software gets new bugs or breaks
entirely because of changes to the modules or operating system
that the software runs on top of.

Rot Testing involves automatically retesting the same software
package whenever a new version of one of it's dependencies is
released, so that failure due to other people's changes can be
detected quickly.

=item Fallout Testing

When a software package like L<perl> releases a new version that
adds or changes features (or even fixes bugs) there can be thousands
of packages and millions of lines of code that will be impacted by
the changes. And the more code impacted, more higher chance of
causing bugs.

Fallout Testing involves testing hundreds or thousands of software
packages with a new version of a dependency to verify that changes
will not cause damage down-stream.

=back

=head2 How Does It Work

Packages such as L<Test::More> and L<Test::Builder> have worked
from the inside out, starting with a single test and working towards
more and more-varied types of testing.

PITA works from the outside-in. B<Way> outside.

The fundamental unit in PITA is an I<"Image">, a virtual hard drive
that PITA puts inside a virtual computer with a virtual CPU (of
various types) with virtual hardware (of various types).

On the Image you can install any operating system you like, just
like on real hardware, and set the operating system up with any
packages and any languages in any configuration you like, and at the
end, install a small piece of software onto the Image that is setup
to run at startup time.

And then you save the Image.

You can create a few or as many of these PITA Images as you like,
trade them with other developers or distribute them within your
company (licenses permitting).

With a set of Images in place, PITA can take a software package
and inject it an Image where the image manager executes a
testing scheme on the package, captures the results, and spits it
out for collection as an XML file.

And this process can be repeated over, and over, and over again. It
gets repeated as many times as is needed, as often as is needed, on
as many packages is necesary, across a set of Images that provide
a particular testing solution.

This method can distributed or clustered extremely easily, and by
introducing flexbility through the use of plugins, PITA can be made
to work with B<multiple> emulators (such as VMWare or Qemu) and allow
the testing of B<multiple> types of packages (Perl 5, Python, Java,
C) or even allow you to define B<your own> specialised testing schemes.

And further, it lets you seperate the collection of the results from
the analysis of the results. With only enough analysis embedded inside
the testing scheme for it to know if and when to abort the testing
sequence, a PITA installation will primarily just spit out a whole
pile of XML reports.

These reports can then be stored and run through analysis routines
seperately. And if the analysis code is improved, you can rerun the
analysis over old results with minimal effort.

=head2 How Do I Get Started

PITA is currently in development, and not ready for general use.

That said, the XML format and object code is completed, the Image
Driver API and the Test Scheme Driver API are working, and a proof
of concept has been completed.

So it works now. It just isn't friendly enough yet.

Work is currently underway on the components for managing sets of images,
for scheduling and managing the tests to be done, and for implementing
basic clustering.

PITA is expected to debut with very specific custom solutions for
implementing smoke testing for groups like pugs, Parrot, and CPAN.

So stay tuned for further news.

And if you would like to experiment or play with PITA in the mean
time, go ahead. That's why it's on CPAN.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Practical Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA::XML>, L<PITA::Scheme>, L<PITA::Guest::Driver::Qemu>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
