package Oz;

=pod

=head1 NAME

Oz - Perl interface for executing applications in the Oz programming language

=head2 SYNOPSIS

  use Oz;
  
  my $code = <<'END_OZ';
  {Show "Hello World!"}
  END_OZ
  
  # One line idiomatic execution of Oz code.
  # Returns the content of STDOUT after the script.
  my $stdout = Oz::Script->new( \$script )->run;
  
  # The longhand equivalent of the above.
  my $script = Oz::Script->new( \$script );
  my $ozc    = Oz::Compiler->new( script => $script );
  my $output = $ozc->run;
  
  # Generate an executable for the script.
  $ozc->make_exe or die "Failed to create executable";
  print "Created " . $ozc->main_exe . "\n";

=head1 DESCRIPTION

B<Oz> is a Perl wrapper for the Oz programming language and the Mozart Oz
compiler. It provides a convenient mechanism for taking simple Oz scripts,
compiling them, executing them, and capturing the resulting output.

=head2 About Oz and Mozart

The Mozart Programming System is an advanced development platform for
intelligent, distributed applications. The system is the result of a decade of
research in programming language design and implementation, constraint-based
inference, distributed computing, and human-computer interfaces.

Mozart is based on the Oz language, which supports declarative programming,
object-oriented programming, constraint programming, and concurrency as part
of a coherent whole. For distribution, Mozart provides a true network
transparent implementation with support for network awareness, openness, and
fault tolerance. Mozart supports multi-core programming with its network
transparent distribution and is an ideal platform for both general-purpose
distributed applications as well as for hard problems requiring sophisticated
optimization and inferencing abilities.

=head2 Why is Oz.pm needed

In an ideal world, a module wrapper for something as simple as compiling a basic
program should not really be necesary. Unfortunately, the dominent toolchain for
Oz (the Mozart Programming System) assumes that anyone writing Oz will be using
the Emacs editor to do so.

As a result, most tutorial information for beginners does not cover the creation
of pure Oz programs, or the compilation of these programs. Instead, it assumes
the use of an Emacs specific layer over the top of the language, and covers the
execution of any resulting programs exclusively from inside of Emacs.

L<Oz> is a Perl module which simplifies the tortuous and badly documented
process of taking pure Oz source code and turning it into an actual working
program that you can execute using the underlying F<ozc> compiler.

It is a fairly simple module designed for simple uses of the Oz programming
language to solve cross-domain programs that would otherwise be extremely
difficult or slow in Perl (such as logic programming or constraint-based
programming).

The two interfaces to the Oz compiler are documented below. For the time being
the code in the synopsis above should be enough to get you started working with
these modules. See the source code to L<Oz::Compiler> or L<Oz::Script> for the
full set of supported methods.

=head2 Oz::Compiler

The L<Oz::Compiler> module provides an interface directly over the F<ozc>
compiler that ships with Mozart.

It provides the basic service for taking Oz scripts in the form of L<Oz::Script>
objects and generating command line calls to the compiler to create executable
files, as well as the various intermediate C<"ozf">, C<"ozi">, C<"ozm"> forms
of the code.

It also provides the ability to execute the resulting executable in a temp
directory, returning the output of the program.

=head2 Oz::Script

The L<Oz::Script> module provides an abstraction for a single Oz script, either
from a location on disk or from an arbitrary string.

It contains a convenience C<run> method which abstracts away dealings with the
L<Oz::Compiler> method, so you can take a string of Oz code and execute it
directly, returning the output of the program.

=cut

use 5.008;
use strict;
use Oz::Compiler ();
use Oz::Script   ();

our $VERSION = '0.01';

1;

=pod

=head1 SUPPORT

Please note that this module is only a first step at an interface for the
Oz programming language and was created to solve a specific limited problem.
It is being provided to CPAN as a courtesy and by no means represents a complete
work (what function is implemented is however solid and stable).

If you are interested in taking this module beyond the current implementation,
I would love to hear from you and would be happy to let you take it over or
have commit to the repository.

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Oz>

=head1 ACKNOWLEDGEMENTS

A huge thanks to my partner in crime Jeffery Candiloro, who actually had the
patience to learn the Oz language enough to write real programs when I was
struggling with it, and who wrote all the real Oz code we executed in production
with this module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
