package Net::Amazon::MechanicalTurk::RowData::SubroutineRowData;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::RowData;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::RowData };

Net::Amazon::MechanicalTurk::RowData::SubroutineRowData->attributes(qw{
    sub
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->assertRequiredAttributes(qw{ sub });
}

sub each {
    my ($self, $block, @blockXArgs) = @_;
    $self->sub->(sub {
        my ($row) = @_;
        if (!$self->fieldNames) {
            if (!UNIVERSAL::isa($row, "HASH")) {
                Carp::croak("First item generated is not a hash.");
            }
            $self->fieldNames([sort keys(%$row)]);
        }
        $block->($self, $row, @blockXArgs);
    });
}

return 1;
