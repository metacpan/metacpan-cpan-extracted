package Quant::Framework::StorageAccessor;

=head1 NAME

Quant::Framework::StorageAccessor - This class incorporates chronicle accessors

=head1 DESCRIPTION

 my $storage_accessor = Quant::Framework::StorageAccessor->new(
  chronicle_reader => ...,
  chronicle_writer => ...,
 );

=cut

use strict;
use warnings;

use Moo;

has chronicle_reader => (
    is => 'ro',
);

has chronicle_writer => (
    is => 'ro',
);

1;
