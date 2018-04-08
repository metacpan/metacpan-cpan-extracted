package QBit::QueryData::Function::MAX;
$QBit::QueryData::Function::MAX::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'TYPE'}       = $self->qd->definition->{$self->args->[0]}{'type'} // 'string';
    $self->{'AGGREGATOR'} = {};
    $self->{'MAX'}        = undef;
}

sub init_storage {
    $_[0]->{'AGGREGATOR'} = {};
    $_[0]->{'MAX'}        = undef;
}

sub process {
    my ($self, $row) = @_;

    my $val = $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($self->args->[0])});

    if (!defined($val)) {
        # it's ok
    } elsif (!defined($self->{'MAX'})) {
        $self->{'MAX'} = $val;
    } elsif ($self->{'TYPE'} eq 'string') {
        if ($val gt $self->{'MAX'}) {
            $self->{'MAX'} = $val;
        }
    } else {
        if ($val > $self->{'MAX'}) {
            $self->{'MAX'} = $val;
        }
    }

    return $self->{'MAX'};
}

sub aggregation {
    my ($self, $row, $key) = @_;

    if (!defined($self->{'MAX'})) {
        # it's ok
    } elsif (!defined($self->{'AGGREGATOR'}{$key})) {
        $self->{'AGGREGATOR'}{$key} = $self->{'MAX'};
    } elsif ($self->{'TYPE'} eq 'string') {
        if ($self->{'MAX'} gt $self->{'AGGREGATOR'}{$key}) {
            $self->{'AGGREGATOR'}{$key} = $self->{'MAX'};
        }
    } else {
        if ($self->{'MAX'} > $self->{'AGGREGATOR'}{$key}) {
            $self->{'AGGREGATOR'}{$key} = $self->{'MAX'};
        }
    }

    $self->{'MAX'} = undef;

    return $self->{'AGGREGATOR'}{$key};
}

TRUE;
