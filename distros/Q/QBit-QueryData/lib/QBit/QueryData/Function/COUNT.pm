package QBit::QueryData::Function::COUNT;
$QBit::QueryData::Function::COUNT::VERSION = '0.011';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    return FALSE if $self->has_errors();

    my $arg = $self->args->[0];

    $self->{'AGGR_FIELD'} = ref($arg) eq 'SCALAR' && $$arg eq '*' ? $$arg : $arg;
    $self->{'PATH'} = $self->qd->_get_path($self->{'AGGR_FIELD'});
}

sub process {
    my ($self) = @_;

    my $code;
    if ($self->{'AGGR_FIELD'} eq '*') {
        $code = '        $new_row->{' . $self->qd->quote($self->field) . '} = 1;
';
    } else {
        $code =
            '        $new_row->{'
          . $self->qd->quote($self->field)
          . '} = defined('
          . $self->qd->_get_field_code_by_path('$row', $self->{'PATH'})
          . ') ? 1 : 0;
';
    }

    return $code;
}

sub aggregation {
    my ($self, $var) = @_;

    return '            ' . $var . ' += $new_row->{' . $self->qd->quote($self->field) . '};
';
}

TRUE;
