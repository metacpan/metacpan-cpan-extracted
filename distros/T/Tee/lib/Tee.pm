#
# This file is part of Tee
#
# This software is Copyright (c) 2006 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
use strict;
use warnings;
package Tee;
BEGIN {
  $Tee::VERSION = '0.14';
}
# ABSTRACT: Pure Perl emulation of GNU tee

use Exporter ();
use Probe::Perl;

our @ISA         = qw (Exporter);
our @EXPORT      = qw (tee);

#--------------------------------------------------------------------------#
# Platform independent ptee invocation
#--------------------------------------------------------------------------#

my $perl = Probe::Perl->find_perl_interpreter;
my $ptee_cmd = "$perl -MTee::App -e run --";

#--------------------------------------------------------------------------#
# Functions
#--------------------------------------------------------------------------#

sub tee {
    my $command = shift;
    my $options;
    $options = shift if (ref $_[0] eq 'HASH');
    my $files = join(" ", @_);
    my $redirect = $options->{stderr} ? " 2>&1 " : q{};
    my $append = $options->{append} ? " -a " : q{};
    system( "$command $redirect | $ptee_cmd $append $files" );
}

1; # modules must be true



=pod

=head1 NAME

Tee - Pure Perl emulation of GNU tee

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  # from Perl
  use Tee;
  tee( $command, @files );
 
  # from the command line
  $ cat README.txt | ptee COPY.txt

=head1 DESCRIPTION

The C<<< Tee >>> distribution provides the L<ptee> program, a pure Perl emulation of
the standard GNU tool C<<< tee >>>.  It is designed to be a platform-independent
replacement for operating systems without a native C<<< tee >>> program.  As with
C<<< tee >>>, it passes input received on STDIN through to STDOUT while also writing a
copy of the input to one or more files.  By default, files will be overwritten.

Unlike C<<< tee >>>, C<<< ptee >>> does not support ignoring interrupts, as signal handling
is not sufficiently portable.

The C<<< Tee >>> module provides a convenience function that may be used in place of
C<<< system() >>> to redirect commands through C<<< ptee >>>. 

=head1 USAGE

=head2 C<<< tee() >>>

   tee( $command, @filenames );
   tee( $command, \%options, @filenames );

Executes the given command via C<<< system() >>>, but pipes it through L<ptee> to copy
output to the list of files.  Unlike with C<<< system() >>>, the command must be a
string as the command shell is used for redirection and piping.  The return
value of C<<< system() >>> is passed through, but reflects the success of 
the C<<< ptee >>> command, which isn't very useful.

The second argument may be a hash-reference of options.  Recognized options
include:

=over

=item *

stderr -- redirects STDERR to STDOUT before piping to L<ptee> (default: false)

=item *

append -- passes the C<<< -a >>> flag to L<ptee> to append instead of overwriting
(default: false)

=back

=head1 LIMITATIONS

Because of the way that C<<< Tee >>> uses pipes, it is limited to capturing a single
input stream, either STDOUT alone or both STDOUT and STDERR combined.  A good,
portable alternative for capturing these streams from a command separately is
L<IPC::Run3>, though it does not allow passing it through to a terminal at the
same time.

=head1 SEE ALSO

=over

=item *

L<ptee>

=item *

IPC::Run3

=item *

IO::Tee

=back

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Tee>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__
#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

