#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Retention;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my $retained;
my %retentionLevels;

sub new {
  my $proto = shift;
  my $retention = {
  };

  bless $retention, $proto;

  if (@_) {
    my $level = $retention->{LEVEL} = shift;
    $retention->{PERIOD} = shift;
    $retention->{DESCRIPTION} = shift;

    $retentionLevels{$level} = $retention;
  }
  return $retention;
}

sub populate {
  my $proto = shift;

  my @masters = NBU->masters;  my $master = $masters[0];

  die "Could not open retention pipe\n"
    unless my $pipe = NBU->cmd("bpretlevel -M ".$master->name." -l |");
  while (<$pipe>) {
    chop;  s/[\s]*$//;
    my ($level, $period, $description) = split(/[\s]+/, $_, 3);
    $proto->new($level, $period, $description);
    chop;
  }
  close($pipe);
  $retained = 1;
}

sub byLevel {
  my $proto = shift;
  my $level = shift;

  $proto->populate if (!$retained);
  return $retentionLevels{$level};
}

sub period {
  my $self = shift;

  return $self->{PERIOD};
}

sub level {
  my $self = shift;

  return $self->{LEVEL};
}

sub description {
  my $self = shift;

  return $self->{DESCRIPTION};
}

sub list {
  my $proto = shift;

  $proto->populate if (!$retained);
  return (values %retentionLevels);
}

1;

__END__

=head1 NAME

NBU::Retention - Retention Level modeling

=head1 SUPPORTED PLATFORMS

=over 4

=item * 

Solaris

=item * 

Windows/NT

=back

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This module provides support for ...

=head1 SEE ALSO

=over 4

=item L<NBU::Media|NBU::Media>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002-2007 Paul Winkeler

=cut

