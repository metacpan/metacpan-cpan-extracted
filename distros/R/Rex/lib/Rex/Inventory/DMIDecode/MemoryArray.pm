#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Inventory::DMIDecode::MemoryArray;

use v5.12.5;
use warnings;

our $VERSION = '1.16.0'; # VERSION

use Rex::Inventory::DMIDecode::Section;
use base qw(Rex::Inventory::DMIDecode::Section);

__PACKAGE__->section("Physical Memory Array");

__PACKAGE__->has(
  [
    'Number Of Devices',
    'Error Correction Type',
    'Maximum Capacity',
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
