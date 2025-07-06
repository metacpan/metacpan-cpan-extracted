#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Inventory::SMBios::Bios;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Inventory::SMBios::Section;
use base qw(Rex::Inventory::SMBios::Section);

__PACKAGE__->section("BIOS information");

__PACKAGE__->has(
  [ 'Vendor', { from => 'Version String', key => 'Version' }, 'Release Date', ],
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
