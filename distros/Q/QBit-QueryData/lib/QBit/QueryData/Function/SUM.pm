package QBit::QueryData::Function::SUM;
$QBit::QueryData::Function::SUM::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'AGGREGATOR'} = {};
    $self->{'SUM'}        = 0;
}

sub init_storage {
    $_[0]->{'AGGREGATOR'} = {};
    $_[0]->{'SUM'}        = 0;
}

sub process {
    my ($self, $row) = @_;

    my $val = $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($self->args->[0])});

    return $self->{'SUM'} += $val // 0;
}

sub aggregation {
    my ($self, $row, $key) = @_;

    $self->{'AGGREGATOR'}{$key} += $self->{'SUM'} // 0;

    $self->{'SUM'} = 0;

    return $self->{'AGGREGATOR'}{$key} // 0;
}

TRUE;
