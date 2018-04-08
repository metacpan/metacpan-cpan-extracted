package QBit::QueryData::Function::MIN;
$QBit::QueryData::Function::MIN::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'TYPE'}       = $self->qd->definition->{$self->args->[0]}{'type'} // 'string';
    $self->{'AGGREGATOR'} = {};
    $self->{'MIN'}        = undef;
}

sub init_storage {
    $_[0]->{'AGGREGATOR'} = {};
    $_[0]->{'MIN'}        = undef;
}

sub process {
    my ($self, $row) = @_;

    my $val = $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($self->args->[0])});

    if (!defined($val)) {
        # it's ok
    } elsif (!defined($self->{'MIN'})) {
        $self->{'MIN'} = $val;
    } elsif ($self->{'TYPE'} eq 'string') {
        if ($val lt $self->{'MIN'}) {
            $self->{'MIN'} = $val;
        }
    } else {
        if ($val < $self->{'MIN'}) {
            $self->{'MIN'} = $val;
        }
    }

    return $self->{'MIN'};
}

sub aggregation {
    my ($self, $row, $key) = @_;

    if (!defined($self->{'MIN'})) {
        # it's ok
    } elsif (!defined($self->{'AGGREGATOR'}{$key})) {
        $self->{'AGGREGATOR'}{$key} = $self->{'MIN'};
    } elsif ($self->{'TYPE'} eq 'string') {
        if ($self->{'MIN'} lt $self->{'AGGREGATOR'}{$key}) {
            $self->{'AGGREGATOR'}{$key} = $self->{'MIN'};
        }
    } else {
        if ($self->{'MIN'} < $self->{'AGGREGATOR'}{$key}) {
            $self->{'AGGREGATOR'}{$key} = $self->{'MIN'};
        }
    }

    $self->{'MIN'} = undef;

    return $self->{'AGGREGATOR'}{$key};
}

TRUE;
