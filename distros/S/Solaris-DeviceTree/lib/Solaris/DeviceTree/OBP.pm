#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/OBP.pm,v 1.8 2003/12/10 12:46:06 honkbude Exp $
#

package Solaris::DeviceTree::OBP;

use strict;
use warnings;

require Exporter;
my @boot_functions = qw( obp_chosen_boot_device obp_boot_devices obp_diag_devices );
my @alias_functions = qw( obp_aliases );
my @path_functions = qw( obp_resolve_path );
our %EXPORT_TAGS = (
  'all' => [ @boot_functions, @alias_functions, @path_functions ],
  'boot' => \@boot_functions,
  'aliases' => \@alias_functions,
  'path' => \@path_functions,
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @ISA = qw( Exporter );
our $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

use Carp;

=pod

=head1 NAME

Solaris::DeviceTree::OBP - Utility functions for OBP access

=head1 SYNOPSIS

Value access:

  $tree = Solaris::DeviceTree::Libdevinfo->new;

  $aliases = obp_aliases($tree);
  my $disk = $aliases->{'disk'};
  $chosen_boot_device = obp_chosen_boot_device($tree);
  @boot_devices = obp_boot_devices($tree);
  @diag_devices = obp_diag_devices($tree);

Path transformation:

  $resolved_path = obp_resolve_path( aliases => $aliases, path => "disk:c" );

=head1 DESCRIPTION

The C<Solaris::DeviceTree::OBP> module implements functions for manipulating OBP pathes according to IEEE 1275.
For most of the functions you need to specify a devicetree containing PROM property nodes,
which are most likely to find in an L<Solaris::DeviceTree::Libdevinfo> tree.

=head1 EXPORT

The following functions are exported on demand:

=cut

# SplitComponent - Split OBP path component into parts
sub _split_component {
  my $component = shift;
  my $hex = '[0-9a-f]';
  my ($node_name, $unit_addr1, $unit_addr2, $arg) =
    ( $component =~ /
          ([^@]+)		# the part before '@' or all if no '@'
          (?:@(${hex}+)		# address part before ','
          (?:,(${hex}+)?)?)?	# address part after ','
          (?::(.*))*		# everything after ':'
        /xo);
  return [ node_name => $node_name,
           unit_addr1 => $unit_addr1,
           unit_addr2 => $unit_addr2,
           arg => $arg ];
}

# Main functions

sub _left_split {
  my ($string, $char) = @_;

  my ($initial, $remainder) = ($string =~ /^([^${char}]*)${char}?(.*)$/);
  return ($initial, $remainder);
}

sub _right_split {
  my ($string, $char) = @_;

  my ($initial, $remainder);
  if( $string =~ /$char/ ) {
    ($initial, $remainder) = ($string =~ /^(.*)${char}([^${char}]*)$/);
  } else {
    $initial = $string;
    $remainder = "";
  }
  return ($initial, $remainder);
}

=pod

=head2 obp_resolve_path

This functions transforms the specified path in an alias-free
path using the path resolution procedure described in
C<1275.pdf - 4.3.1 Path resolution procedure> according to the specified
reference to an alias mapping.


=cut

# 1275.pdf - 4.3.1 Path resolution procedure (top level procedure)
sub obp_resolve_path {
  my %options = @_;

  if( !exists $options{path} || !exists $options{aliases} ) {
    carp "The options 'path' and 'aliases' must be specified";
  }
  my $path_name = $options{path};
  my $aliases = $options{aliases};

  # If the pathname does not begin with "/", and its first node name
  # component is an alias, replace the alias with its expansion.
  if( $path_name !~ m[^/] ) {
    my ($head, $tail) = _left_split( $path_name, '/' );
    my ($alias_name, $alias_args) = _left_split( $head, ':' );
    if( exists $aliases->{ $alias_name } ) {
      $alias_name = $aliases->{ $alias_name };
      if( $alias_args ne '' ) {
        my ($alias_head, $alias_tail) = _right_split( $alias_name, '/' );
        my $dead_args;
        ($alias_tail, $dead_args) = _right_split( $alias_tail, ':' );
        if( $alias_head ne '' ) {
          $alias_tail = $alias_head . '/' . $alias_tail;
        }
        $alias_name = $alias_tail . ':' . $alias_args;
      }
      if( $tail eq '' ) {
        $path_name = $alias_name;
      } else {
        $path_name = $alias_name . '/' . $tail;
      }
    }
  }
  $path_name;
}

=pod

=head2 aliases

This method returns a reference to a hash which maps all aliases to their
corresponding values.

=cut

sub obp_aliases {
  my $this = shift;

  my $alias_node = $this->find_nodes( devfs_path => '/aliases' );
  my %aliases;
  if( defined $alias_node ) {
    my $props = $alias_node->prom_props;
    foreach my $prop (keys %$props) {
      # The 'name' property is always present, but it is not an alias.
      # Skip it.
      next if( $prop eq 'name' );
      $aliases{$prop} = $props->{$prop}->string;
    }
  } else {
    die "The '/aliases'-node in the devicetree could not be found.";
  }
  return \%aliases;
}

=pod

=head2 obp_chosen_boot_device

This method returns the device from which the system has most recently booted.

=cut

sub obp_chosen_boot_device {
  my $this = shift;
  return $this->find_prop( devfs_path => '/chosen', prom_prop_name => 'bootpath' );
}

=pod

=head2 obp_boot_devices

This method returns a list with all boot devices entered in the OBP.

=cut

sub obp_boot_devices {
  my $this = shift;
  my $prop = $this->find_prop( devfs_path => '/options', prom_prop_name => 'boot-device' );
  my @boot_devices = split /\s+/, $prop->string;
  return @boot_devices;
}

=pod

=head2 obp_diag_devices

This method returns a list with all diag devices entered in the OBP.

=cut

sub obp_diag_devices {
  my $this = shift;
  my $prop = $this->find_prop( devfs_path => '/options', prom_prop_name => 'diag-device' );
  my @diag_devices = split /\s+/, $prop->string;
  return @diag_devices;
}

=pod

The following export tags are defined:

=over 4

=item boot

  L</obp_chosen_boot_device>, L</obp_boot_devices>, L</obp_diag_devices>.

=item alias

  L</obp_aliases>.

=item path

  L</obp_resolve_path>.

=back 4

=head1 EXAMPLES

In the following example the resolved physical pathname of the
device last booted from is printed:

  use Solaris::DeviceTree::OBP;
  use Solaris::DeviceTree::Libdevinfo;
  my $tree = Solaris::DeviceTree::Libdevinfo->new;
  $bootpath = $tree->find_prop( devfs_path => "/chosen", prom_prop_name => "bootpath" );
  $resolved_path = obp_resolve_path( aliases => $tree->aliases, path => $bootpath->string );
  print "Last boot from $resolved_path\n";


=head1 AUTHOR

Dagobert Michelsen, E<lt>dam@baltic-online.deE<gt>

=head1 SEE ALSO

Open Firmware Homepage L<http://playground.sun.com/1275/home.html>,
L<eeprom(1m)>.

=cut

1;
