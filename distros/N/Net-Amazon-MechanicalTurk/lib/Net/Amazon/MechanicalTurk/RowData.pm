package Net::Amazon::MechanicalTurk::RowData;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::BaseObject;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

Net::Amazon::MechanicalTurk::RowData->attributes(qw{
    fieldNames
});

sub toRowData {
    my ($class, $rowdata) = @_;
    if (UNIVERSAL::isa($rowdata, "Net::Amazon::MechanicalTurk::RowData")) {
        return $rowdata;
    }
    elsif (UNIVERSAL::isa($rowdata, "ARRAY")) {
        require Net::Amazon::MechanicalTurk::RowData::ArrayHashRowData;
        return Net::Amazon::MechanicalTurk::RowData::ArrayHashRowData->new(
            array => $rowdata
        );
    }
    elsif (UNIVERSAL::isa($rowdata, "CODE")) {
        require Net::Amazon::MechanicalTurk::RowData::SubroutineRowData;
        return Net::Amazon::MechanicalTurk::RowData::SubroutineRowData->new(
            sub => $rowdata
        );     
    }
    elsif ($rowdata =~ /\.csv$/i) {
        require Net::Amazon::MechanicalTurk::RowData::DelimitedRowData;
        require Net::Amazon::MechanicalTurk::DelimitedReader;
        return Net::Amazon::MechanicalTurk::RowData::DelimitedRowData->new(
            reader => Net::Amazon::MechanicalTurk::DelimitedReader->new(
                file => $rowdata,
                fieldSeparator => ","
            )
        );
    }
    else { # Defaults to tab delimited
        require Net::Amazon::MechanicalTurk::RowData::DelimitedRowData;
        require Net::Amazon::MechanicalTurk::DelimitedReader;
        return Net::Amazon::MechanicalTurk::RowData::DelimitedRowData->new(
            reader => Net::Amazon::MechanicalTurk::DelimitedReader->new(
                file => $rowdata,
                fieldSeparator => "\t"
            )
        );
    }
}

sub each {
    my ($self, $block, @blockXArgs) = @_;
    # Subclass should implement
}

return 1;
