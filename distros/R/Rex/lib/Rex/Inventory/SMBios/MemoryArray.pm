#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Inventory::SMBios::MemoryArray;

use v5.12.5;
use warnings;

our $VERSION = '1.14.2'; # VERSION

use Rex::Inventory::SMBios::Section;
use base qw(Rex::Inventory::SMBios::Section);

__PACKAGE__->section("physical memory array");

__PACKAGE__->has(
  [
    { key => 'Number Of Devices',     from => "Number of Slots/Sockets" },
    { key => 'Error Correction Type', from => "ECC" },
    { key => 'Maximum Capacity',      from => "Max Capacity" },
    'Location',
  ],
  1
);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $that->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

1;
