package Sys::Apm;

use strict;
use warnings;

our $VERSION = 0.05;

sub new {
    my $cls = shift;
    my $self = {proc=>'/proc/apm'};
    unless (-f $self->{proc}) { return }
    bless $self => $cls;
    $self->fetch;
    $self;
}

sub fetch {
    my $self = shift;
    open(APM,$self->{proc})or return;
    my $a = <APM>;
    chomp($a);
    close APM;
    unless ($a) { return }
    $self->parse($a);
}

sub parse {
    my $self = shift;
    my $str = shift;
    $self->{data}=[split / /, $str];
}

sub driver_version {
    my $self = shift;
    $self->{data}[0];
}

sub bios_version {
    my $self = shift;
    $self->{data}[1];
}

sub ac_status {
    my $self = shift;
    hex($self->{data}[3]);
}

sub battery_status {
    my $self = shift;
    hex($self->{data}[4]);
}

sub charge {
    my $self = shift;
    $self->{data}[6];
}

sub remaining {
    my $self = shift;
    $self->{data}[7];
}

sub units {
    my $self = shift;
    $self->{data}[8];
}

1;
__END__

=head1 NAME

Sys::Apm - Perl extension for APM

=head1 SYNOPSIS

  use Sys::Apm;
  my $apm = Sys::Apm->new or die "no apm nupport in kernel";
  print $apm->charge

=head1 DESCRIPTION

  This module allows you to query your battery status and such through /proc/apm

=head1 METHODS

=head2 fetch

  Fetches the data from /proc/apm
  This method is called once in the constructor

=head2 driver_version
  
  Linux APM driver version
  
=head2 bios_version
  
  APM BIOS Version.  Usually 1.0, 1.1 or 1.2.

=head2 ac_status

  AC line status
  0x00: offline
  0x01: online
  0x02: on backup power
  0xff: unknown

=head2 battery_status

  Battery status
  0x00: High
  0x01: Low
  0x02: Critical
  0x03: Charging
  0x04: No battery

=head2 charge

  Remaining battery life (percentage of charge)
  0-100: valid
  -1: Unknown

=head2 remaining

  Remaining battery life (time units):
  Number of remaining minutes or seconds
  -1: Unknown

=head2 units

  min: minutes
  sec: seconds
  
=head1 SEE ALSO

  apm(1)
  arch/i386/kernel/apm.c

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
