package Power::Outlet::Virtual;
use strict;
use warnings;
use File::Spec qw{};
use Path::Class qw{};
use base qw{Power::Outlet::Common};

our $VERSION = '0.50';

=head1 NAME

Power::Outlet::Virtual - Control and query a Virtual Outlet

=head1 SYNOPSIS

  my $outlet = Power::Outlet::iBootBar->new(id => 1);
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION
 
Power::Outlet::Virtual is a package for controlling and querying a virtual outlet where the state is stored in a temp file.

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Virtual", id=>1);
  my $outlet = Power::Outlet::Virtual->new;

=head1 PROPERTIES

=head2 id

Sets and returns the outlet unique id.

Default: 1

=cut

sub id {
  my $self      = shift;
  $self->{"id"} = shift if @_;
  $self->{"id"} = $self->_id_default unless defined $self->{"id"};
  return $self->{"id"};
}

sub _id_default {1};

=head1 METHODS

=cut

sub _folder {
  my $self           = shift;
  $self->{'_folder'} = shift if @_;
  $self->{'_folder'} = File::Spec->tmpdir() unless defined $self->{'_folder'};
  die(sprintf('Error: Directory "%s" is not writable', $self->{'_folder'})) unless -w $self->{'_folder'};
  return $self->{'_folder'};
}

sub _file {
  my $self = shift;
  return Path::Class::file($self->_folder, sprintf("power-outlet.%s.outlet", $self->id));
}

=head2 query

Returns current state of the virtual outlet

=cut

sub query {
  my $self = shift;
  if (defined wantarray) { #scalar and list context
    my $file = $self->_file;
    return -f $file ? $file->slurp(chomp=>1) : 'OFF';
  } else { #void context
    return;
  }
}

=head2 on

Sends a TCP/IP message to the iBoot device to Turn Power ON

=cut

sub on {
  my $self = shift;
  $self->_file->spew("ON$/");
  return $self->query;
}

=head2 off

Sends a TCP/IP message to the iBoot device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  $self->_file->spew("OFF$/");
  return $self->query;
}

=head2 switch

Queries the device for the current status and then requests the opposite.  

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
