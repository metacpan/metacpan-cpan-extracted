#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Inventory::SMBios::SystemInformation;

use v5.12.5;
use warnings;

our $VERSION = '1.14.2'; # VERSION

use Rex::Inventory::SMBios::Section;
use base qw(Rex::Inventory::SMBios::Section);

__PACKAGE__->section("system information");

__PACKAGE__->has(
  [
    'Manufacturer', { key => 'Product Name', from => "Product" },
    'UUID', 'SKU Number', 'Family', 'Version', 'Serial Number',
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
