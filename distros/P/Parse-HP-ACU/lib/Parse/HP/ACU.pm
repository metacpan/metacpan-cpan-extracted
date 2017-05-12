#!/usr/bin/perl -w

# Copyright 2010 Jeremy Cole.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

package Parse::HP::ACU;

use warnings;
use strict;

=head1 NAME

Parse::HP::ACU - Parse the output of HP's hpacucli utility.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Parse::HP::ACU parses the output of HP's C<hpacucli> utility to allow
programmatic access to the RAID configuration information provided by the
hpacucli utility on HP ProLiant servers.

    use Parse::HP::ACU;

    my $acu = Parse::HP::ACU->new();

Run the C<hpacucli> tool directly to query the hardware (requires root):

    my $controllers = $acu->parse_config();
    
Parse a text file created already by running C<hpacucli> tool:

    my $controllers = $acu->parse_config_file("foo.txt");

Read from a file descriptor already opened by the program:

    my $controllers = $acu->parse_config_fh(\*STDIN);

=head1 SUBROUTINES/METHODS

=head2 new

Return an instance of the HP::Parse::ACU class that can be used to parse
input in one of several ways.

=cut

sub new
{
  my ($class, $config, $plugin) = @_;
  my $self = {};

  bless($self, $class);
  return $self;
}

=head2 parse_config

Attempt to run the hpacucli utility, and parse the output.  This command
actually uses parse_config_fh() after opening a pipe to the relevant command.

The command that is actually run is approximately:

=over 4
hpacucli controller all show config detail
=back

This command requires root access, and Parse::HP::ACU makes no attempt to 
use sudo or any other method to gain root access.  It is recommended to call 
your script which uses this module as root.

The parse_config_fh() and parse_config_file() will expect output equivalent
to that from the above command.

=cut

sub parse_config
{
  my ($self) = @_;

  my $hpacucli = "/usr/sbin/hpacucli";
  my $argument = "controller all show config detail";
  my $command = sprintf("%s %s|", $hpacucli, $argument);

  my $fh;
  if(open $fh, $command)
  {
    my $c = $self->parse_config_fh($fh);
    close $fh;
    return $c;
  }
  return undef;
}

=head2 parse_config_file

Open and parse a file containing the output from hpacucli.

=cut

sub parse_config_file
{
  my ($self, $file) = @_;

  my $fh;
  if(open $fh, "<".$file)
  {
    my $c = $self->parse_config_fh($fh);
    close $fh;
    return $c;
  }
  return undef;

}

=head2 parse_config_fh

Read from the file handle and parse it, returning a hash-of-hashes.

=cut

sub parse_config_fh
{
  my ($self, $fh) = @_;

  my $controller = {};
  my $current_controller      = 0;
  my $current_array           = undef;
  my $current_logical_drive   = undef;
  my $current_mirror_group    = undef;
  my $current_physical_drive  = undef;

  LINE: while(my $line = <$fh>)
  {
    chomp $line;

    next if($line =~ /^$/);

    if($line !~ /^[ ]+/)
    {
      $current_controller     = $current_controller + 1;
      $current_array          = undef;
      $current_logical_drive  = undef;
      $current_mirror_group   = undef;
      $current_physical_drive = undef;
      $controller->{$current_controller} = {};
      $controller->{$current_controller}
        ->{'description'} = $line;
      next;
    }

    next if(!defined($current_controller));

    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    $line =~ s/[ ]+/ /g;

    if($line =~ /unassigned/)
    {
      $current_array          = "unassigned";
      $current_logical_drive  = undef;
      $current_mirror_group   = undef;
      $current_physical_drive = undef;
      $controller->{$current_controller}
        ->{'unassigned'} = {};
      $controller->{$current_controller}
        ->{'unassigned'}->{'physical_drive'} = {};
      next;
    }

    if($line =~ /Array: ([A-Z]+)/)
    {
      $current_array          = $1;
      $current_logical_drive  = undef;
      $current_mirror_group   = undef;
      $current_physical_drive = undef;
      $controller->{$current_controller}
        ->{'array'}->{$current_array} = {};
      $controller->{$current_controller}
        ->{'array'}->{$current_array}
        ->{'logical_drive'} = {};
      $controller->{$current_controller}
        ->{'array'}->{$current_array}
        ->{'physical_drive'} = {};
      next;
    }

    if($line =~ /Logical Drive: ([0-9]+)/)
    {
      $current_logical_drive  = $1;
      $current_physical_drive = undef;
      $current_mirror_group   = undef;
      $controller->{$current_controller}
        ->{'array'}->{$current_array}
        ->{'logical_drive'}->{$current_logical_drive} = {};
      $controller->{$current_controller}
        ->{'array'}->{$current_array}
        ->{'logical_drive'}->{$current_logical_drive}
        ->{'mirror_group'} = {};
      next;
    }

    if($line =~ /physicaldrive ([0-9IC:]+)/ and $line !~ /port/)
    {
      $current_logical_drive  = undef;
      $current_physical_drive = $1;
      $current_mirror_group   = undef;
      if($current_array eq 'unassigned')
      {
        $controller->{$current_controller}
          ->{'unassigned'}
          ->{'physical_drive'}->{$current_physical_drive} = {};
      } else {
        $controller->{$current_controller}
          ->{'array'}->{$current_array}
          ->{'physical_drive'}->{$current_physical_drive} = {};
      }
      next;
    }

    if($line =~ /Mirror Group ([0-9]+):/)
    {
      $current_mirror_group = $1;
      $controller->{$current_controller}
        ->{'array'}->{$current_array}
        ->{'logical_drive'}->{$current_logical_drive}
        ->{'mirror_group'}->{$current_mirror_group} = [];
      next;
    }

    if(defined($current_array) 
      and defined($current_logical_drive)
      and defined($current_mirror_group))
    {
      if($line =~ /physicaldrive ([0-9IC:]+) \(/)
      {
        my $current_mirror_group_list = $controller->{$current_controller}
          ->{'array'}->{$current_array}
          ->{'logical_drive'}->{$current_logical_drive}
          ->{'mirror_group'}->{$current_mirror_group};

        foreach my $pd (@{$current_mirror_group_list})
        {
          next LINE if($pd eq $1);
        }
        push @{$current_mirror_group_list}, $1;
      }
      next;
    }

    if(defined($current_array)
      and defined($current_logical_drive))
    {
      if(my ($k, $v) = &K_V($line))
      {
        next unless defined($k);
        $controller->{$current_controller}
          ->{'array'}->{$current_array}
          ->{'logical_drive'}->{$current_logical_drive}->{$k} = $v;
      }
      next;
    }

    if(defined($current_array)
      and defined($current_physical_drive))
    {
      if(my ($k, $v) = &K_V($line))
      {
        next unless defined($k);
        if($current_array eq 'unassigned')
        {
          $controller->{$current_controller}
            ->{'unassigned'}
            ->{'physical_drive'}->{$current_physical_drive}->{$k} = $v;
        } else {
          $controller->{$current_controller}
            ->{'array'}->{$current_array}
            ->{'physical_drive'}->{$current_physical_drive}->{$k} = $v;
        }
      }
      next;
    }
  
    if(defined($current_array))
    {
      if(my ($k, $v) = &K_V($line))
      {
        next unless defined($k);
        $controller->{$current_controller}
          ->{'array'}->{$current_array}->{$k} = $v;
      }
      next;
    }

    if(my ($k, $v) = &K_V($line))
    {
      next unless defined($k);
      $controller->{$current_controller}->{$k} = $v;
    }
    next;
  }
  
  return $controller;
}

sub K
{
  my ($k) = @_;

  $k = lc $k;  
  $k =~ s/[ \/\-]/_/g;
  $k =~ s/[\(\)]//g;

  return $k;
}

sub V
{
  my ($k, $v) = @_;

  if($k eq 'accelerator_ratio')
  {
    if($v =~ /([0-9]+)% Read \/ ([0-9]+)% Write/)
    {
      return {'read' => $1, 'write' => $2};
    }
  }

  return $v;
}

sub K_V($)
{
  my ($line) = @_;

  if($line =~ /(.+):\s+(.+)/)
  {
    my $k = &K($1);
    my $v = &V($k, $2);
    return ($k, $v);
  }

  return (undef, undef);
}

=head1 AUTHOR

Jeremy Cole, C<< <jeremy at jcole.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-hp-acu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-HP-ACU>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

This module has been tested with at least the following RAID controllers:

=over 4
=item * HP Smart Array P400i (G5 series on-board)
=item * HP Smart Array P410i (G6 series on-board)
=item * HP Smart Array P410 (add-on with internal connectors)
=item * HP Smart Array P411 (add-on with external connectors)
=back

This module has been tested with at least the following RAID configurations:

=over 4
=item * 2-disk RAID 1
=item * 2-disk RAID 1 + 6-disk RAID 1+0
=item * 4-disk RAID 1+0
=back

Other controllers or configurations may or may not work.  Your feedback is
appreciated in order to further test and refine the parsing code.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::HP::ACU


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-HP-ACU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-HP-ACU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-HP-ACU>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-HP-ACU/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jeremy Cole.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Parse::HP::ACU
