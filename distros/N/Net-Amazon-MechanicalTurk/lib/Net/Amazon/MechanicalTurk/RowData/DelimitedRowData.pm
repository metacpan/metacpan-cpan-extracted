package Net::Amazon::MechanicalTurk::RowData::DelimitedRowData;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::RowData;
use Net::Amazon::MechanicalTurk::ModuleUtil;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::RowData };

Net::Amazon::MechanicalTurk::RowData::DelimitedRowData->attributes(qw{
    reader
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->assertRequiredAttributes(qw{ reader });
}

sub each {
    my ($self, $block, @blockXArgs) = @_;
    
    my @fields;
    my $rowno = 0;
    while (my $row = $self->reader->next) {
     
        # Skip empty rows
        next if ($#{$row} < 0 or ($#{$row} == 0) and $row->[0] eq '');
        
        if ($rowno++ == 0) {
            @fields = @${row};
            $self->fieldNames(\@fields);
        }
        else {
            my %hash;
            for (my $i=0; $i<=$#fields; $i++) {
                if ($i <= $#{$row}) {
                    $hash{$fields[$i]} = $row->[$i];
                }
                else {
                    $hash{$fields[$i]} = '';
                }
            }
            $block->($self, \%hash, @blockXArgs);
        }
    }
}

return 1;
