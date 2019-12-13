# Original author: Paul Johnson
# Created:         Fri 12 Mar 1999 10:25:51 am

package System::Explain;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

=encoding utf-8

=head1 NAME

System::Explain - run a system command and explain the result

=head1 SYNOPSIS

  use System::Explain "command, verbose, errors";
  sys qw(ls -al);

The C<sys> function runs a system command, checks the result, and comments on
it to STDOUT.

=head1 DESCRIPTION

System::Explain is a standalone release of L<System>, part of L<Gedcom>
v1.20 and earlier.

=head1 FUNCTIONS

=cut

use parent 'Exporter';

our @EXPORT = qw(sys dsys);

my $Command = 0;
my $Errors  = 0;
my $Verbose = 0;

=head1 import

Say C<use System::Explain "list, of, options"> to use this module.
The options are: C<command> (to print the command before running it),
C<error> (to report on the exit status), and C<verbose> (to do both of those).

=cut

sub import
{
  my $class = shift;
  my $args  = "@_";
  $Command = $args =~ /\bcommand\b/i;
  $Errors  = $args =~ /\berror\b/i;
  $Verbose = $args =~ /\bverbose\b/i;
  $Command ||= $Verbose;
  $Errors  ||= $Verbose;
  $class->export_to_level(1, "sys")  if $args =~ /\bsys\b/i;
  $class->export_to_level(1, "dsys") if $args =~ /\bdsys\b/i;
}

=head1 sys

C<sys(@command);> runs C<@command> (by passing C<@command> to C<system()>) and
optionally prints human-readable information about the result (specifically,
about the return value of C<system()>).

Returns the return value of the C<system()> call.

=cut

sub sys
{
  my (@command) = @_;
  local $| = 1;
  print "@command" if $Command;
  my $rc = 0xffff & system @command;
  print "\n" if $Command && !$rc && !$Verbose;
  _print_explanation_of($rc);
}

=head1 dsys

As L</sys>, but dies if the C<system()> call fails.

=cut

sub dsys
{
  die "@_ failed" if sys @_;
}

# Print the explanation
sub _print_explanation_of
{
  my ($rc) = @_;
  printf "  returned %#04x: ", $rc if $Errors && $rc;
  if ($rc == 0)
  {
    print "ran with normal exit\n" if $Verbose;
  }
  elsif ($rc == 0xff00)
  {
    print "command failed: $!\n" if $Errors;
  }
  elsif ($rc > 0x80)
  {
    $rc >>= 8;
    print "ran with non-zero exit status $rc\n" if $Errors;
  }
  else
  {
    print "ran with " if $Errors;
    if ($rc & 0x80)
    {
      $rc &= ~0x80;
      print "coredump from " if $Errors;
    }
    print "signal $rc\n" if $Errors;
  }
  return $rc;
}

1;
__END__

=head1 SEE ALSO

L<IPC::System::Simple>, L<Proc::ChildError>, L<Process::Status>
(among others).

=head1 LICENSE

Copyright (C) 2012 Paul Johnson E<lt>pjcj@cpan.orgE<gt>

Also Copyright (C) 1999-2012 Paul Johnson; Copyright (C) 2019 Christopher White

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Paul Johnson E<lt>paul@pjcj.netE<gt>

=cut
