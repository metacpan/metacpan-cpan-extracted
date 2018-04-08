package QBit::QueryData::Function::COUNT;
$QBit::QueryData::Function::COUNT::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $arg = $self->args->[0];

    $self->{'AGGR_FIELD'} = ref($arg) eq 'SCALAR' && $$arg eq '*' ? $$arg : $arg;
    $self->{'AGGREGATOR'} = {};
    $self->{'COUNT'}      = 0;
}

sub init_storage {
    $_[0]->{'AGGREGATOR'} = {};
    $_[0]->{'COUNT'}      = 0;
}

sub process {
    my ($self, $row) = @_;

    if ($self->{'AGGR_FIELD'} eq '*') {
        $self->{'COUNT'}++;
    } else {
        my $val = $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($self->{'AGGR_FIELD'})});

        $self->{'COUNT'}++ if defined($val);
    }

    return $self->{'COUNT'} // 0;
}

sub aggregation {
    my ($self, $row, $key) = @_;

    $self->{'AGGREGATOR'}{$key} += $self->{'COUNT'} // 0;

    $self->{'COUNT'} = 0;

    return $self->{'AGGREGATOR'}{$key} // 0;
}

TRUE;
