package Net::Amazon::MechanicalTurk::RowData::ArrayHashRowData;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::RowData;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::RowData };

Net::Amazon::MechanicalTurk::RowData::ArrayHashRowData->attributes(qw{
    array
});

#
# Creates a RowData from an array of hashes.
# If fieldNames are not given the sorted keys of the first
# hash become the fieldNames.
#

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->assertRequiredAttributes(qw{ array });
    if (!$self->fieldNames and $#{$self->array} >= 0) {
        my $firstHash = $self->array->[0];
        if (!UNIVERSAL::isa($firstHash, "HASH")) {
            Carp::croak("Non hash found in first element of array.");
        }
        $self->fieldNames([sort keys(%$firstHash)]);
    }
    else {
        $self->fieldNames([]);
    }
}

sub each {
    my ($self, $block, @blockXArgs) = @_;
    my $array = $self->array;
    foreach my $element (@$array) {
        $block->($self, $element, @blockXArgs);
    }
}

return 1;
