package QBit::QueryData::Function::MIN;
$QBit::QueryData::Function::MIN::VERSION = '0.011';
use qbit;

use base qw(QBit::QueryData::Function);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    return FALSE if $self->has_errors();

    $self->{'PATH'} = $self->qd->_get_path($self->args->[0]);
    $self->{'TYPE'} = $self->qd->definition->{$self->args->[0]}{'type'} // 'string';
}

sub process {
    my ($self) = @_;

    return
        '        $new_row->{'
      . $self->qd->quote($self->field) . '} = '
      . $self->qd->_get_field_code_by_path('$row', $self->{'PATH'}) . ';
';
}

sub aggregation {
    my ($self, $var) = @_;

    my $val = '$new_row->{' . $self->qd->quote($self->field) . '}';

    my $opr = $self->{'TYPE'} eq 'string' ? 'lt' : '<';

    return '
            if (!defined(' . $val . ')) {
                # it is ok
            } elsif (!defined(' . $var . ')) {
                ' . $var . ' = ' . $val . ';
            } else {
                if (' . $val . ' ' . $opr . ' ' . $var . ') {
                    ' . $var . ' = ' . $val . ';
                }
            }

';
}

TRUE;
