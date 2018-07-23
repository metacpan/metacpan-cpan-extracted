#
# $Id: Console.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Log::Console;
use strict;
use warnings;

use base qw(Net::SinFP3::Log);
__PACKAGE__->cgBuildIndices;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub warning {
   my $self = shift;
   my ($msg) = @_;
   my $job = defined($self->global) ? $self->global->job : 0;
   print("[!] [J:$job] $msg\n");
}

sub error {
   my $self = shift;
   my ($msg) = @_;
   my $job = defined($self->global) ? $self->global->job : 0;
   print("[-] [J:$job] $msg\n");
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;
   my ($package) = caller();
   my $job = defined($self->global) ? $self->global->job : 0;
   die("[-] [J:$job] FATAL: $package: $msg\n");
}

sub info {
   my $self = shift;
   my ($msg) = @_;
   my $job = defined($self->global) ? $self->global->job : 0;
   return unless $self->level > 0;
   print("[+] [J:$job] $msg\n");
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;
   my $job = defined($self->global) ? $self->global->job : 0;
   return unless $self->level > 1;
   print("[*] [J:$job] $msg\n");
}

sub debug {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 2;
   my ($package) = caller();
   my $job = defined($self->global) ? $self->global->job : 0;
   print("[DEBUG] [J:$job] $package: $msg\n");
}

1;

__END__

=head1 NAME

Net::SinFP3::Log::Console - logging directly on the console

=head1 SYNOPSIS

   use Net::SinFP3::Log::Console;

   my $log = Net::SinFP3::Log::Console->new(
      level => 1,
   );

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<info>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<verbose>

=item B<debug>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
