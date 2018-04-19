package QBit::QueryData::Function::SUM;
$QBit::QueryData::Function::SUM::VERSION = '0.011';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    return FALSE if $self->has_errors();

    $self->{'PATH'} = $self->qd->_get_path($self->args->[0]);
}

sub process {
    my ($self) = @_;

    return
        '        $new_row->{'
      . $self->qd->quote($self->field) . '} = '
      . $self->qd->_get_field_code_by_path('$row', $self->{'PATH'}) . ' // 0;
';
}

sub aggregation {
    my ($self, $var) = @_;

    return '            ' . $var . ' += $new_row->{' . $self->qd->quote($self->field) . '};
';
}

TRUE;
