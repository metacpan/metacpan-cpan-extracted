#!/usr/bin/perl -w

# Copyright 2012 Mathieu Alorent.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

package Parse::cfggen;

use warnings;
use strict;

=head1 NAME

Parse::cfggen - Parse the output of cfggen utility.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Parse::cfggen parses the output of C<cfggen> utility to allow
programmatic access to the RAID configuration information provided by the
cfggen utility on LSI RAID cards.

    use Parse::cfggen;

    my $cfggen = Parse::cfggen->new();

Run the C<cfggen> tool directly to query the hardware (requires root):

    my $controllers = $cfggen->parse_config();
    
Parse a text file created already by running C<cfggen> tool:

    my $controllers = $cfggen->parse_config_file("foo.txt");

Read from a file descriptor already opened by the program:

    my $controllers = $cfggen->parse_config_fh(\*STDIN);

=head1 SUBROUTINES/METHODS

=head2 new

Return an instance of the Parse::cfggen class that can be used to parse
input in one of several ways.

=cut

sub new
{
  my ($class, $config, $plugin) = @_;
  my $self = {};
  $self->{_controllers} = {};

  bless($self, $class);
  return $self;
}

=head2 parse_config

Attempt to run the cfggen utility, and parse the output.  This command
actually uses parse_config_fh() after opening a pipe to the relevant command.

The commands that are actually run are approximately:

=over 4

cfggen LIST
cfggen 0 DISPLAY
cfggen 1 DISPLAY
cfggen ... DISPLAY

=back

This command requires root access, and Parse::cfggen makes no attempt to 
use sudo or any other method to gain root access.  It is recommended to call 
your script which uses this module as root.

The parse_config_fh() and parse_config_file() will expect output equivalent
to that from the above command.

=cut

sub parse_config
{
  my ($self) = @_;

  my $cfggen  = "/usr/sbin/cfggen";
  my $command = sprintf("%s %s|", $cfggen, 'LIST');
  my @ctrls = ();

  # list controllers
  if(open LIST, $command) {
    while (<LIST>) {
      next unless $_ =~ /^\s+(\d+)\s+\W/;
      push @ctrls, $1;
    }
    close LIST;
  }

  # parse controlers
  my $c = undef;
  foreach my $ctrl (@ctrls) {
    $command = sprintf("%s %s|", $cfggen, "$ctrl DISPLAY");
    my $fh;
    if(open $fh, $command)
    {
      $c = $self->parse_config_fh($fh);
      close $fh;
    }
  }
  return $c;
}

=head2 parse_config_file

Open and parse a file containing the output from cfggen.

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

  my $current_controller      = 0;
  my $current_logical_drive   = undef;
  my $current_physical_drive  = undef;
  my $ctrl                    = undef;
  my $line                    = undef;
  my $controller              = $self->{_controller};

  LEVEL1: while($line = <$fh>)
  {
    chomp $line;

    next if($line =~ /^$/);
    next if($line =~ /^-+$/);

    if($line =~ /^Read configuration has been initiated for controller (\d+)$/) {
      $current_controller = $1;
    }

    if($line =~ /^Controller information/) {
      $controller->{$current_controller} = {};
      $ctrl = $controller->{$current_controller};

      $line = <$fh>;

      while($line = <$fh>) {
        chomp $line;

        if ($line =~ /^\s+(.*\w\)?)\s+:\s+(.*)$/) {
          my $key = $1;
          $key =~ tr/\#//;
          $ctrl->{$key} = $2;
        } elsif ($line =~ /^-+$/) {
          last;
        }
      }
    } elsif($line =~ /^IR Volume information/) {
      $current_logical_drive  = undef;

      $line = <$fh>;

      while($line = <$fh>) {
        chomp $line;

        if ( $line =~ /^IR volume (\d+)$/ ) {
          $current_logical_drive = $1;
        } elsif ($line =~ /^\s+(.*\w\)?)\s+:\s+(.*)$/) {
          my $key = $1;
          $key =~ tr/\#//;
          #$key =~ tr#+.:/'&()-##;
          $ctrl->{logical_drive}{$current_logical_drive}{$key} = $2;
        } elsif ($line =~ /^-+$/) {
          last;
        }
      }
    } elsif($line =~ /^Physical device information/) {
      $current_physical_drive  = undef;

      $line = <$fh>;

      while($line = <$fh>) {
        chomp $line;

        if ( $line =~ /^Target on ID #(\d+)$/ ) {
          $current_physical_drive = $1;
        } elsif ($line =~ /^\s+(.*\w\)?( \#)?)\s+:\s+(.*)$/) {
          my $key = $1;
          $key =~ tr/\#//;
          #$key =~ tr#+.:/'&()-##;
          $ctrl->{physical_drive}{$current_physical_drive}{$key} = $3;
          $ctrl->{physical_drive}{$current_physical_drive}{$key} =~ s/\s*(\w*\s*\w)\s*/$1/;
        } elsif ($line =~ /^-+$/) {
          last;
        }
      }
    }
  }
  
  return $controller;
}

=head1 AUTHOR

Mathieu Alorent, C<< <kumy at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-cfggen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-cfggen>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::cfggen


You can also look for information at:

=over 4

=item * Source code

L<https://github.com/kumy/Parse-cfggen>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-cfggen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-cfggen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-cfggen>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-cfggen/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mathieu Alorent.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

This program is based on Parse::HP::ACU a work of Jeremy Cole.


=cut

1; # End of Parse::cfggen
