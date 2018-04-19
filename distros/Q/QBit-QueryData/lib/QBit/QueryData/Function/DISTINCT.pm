package QBit::QueryData::Function::DISTINCT;
$QBit::QueryData::Function::DISTINCT::VERSION = '0.011';
use qbit;

use base qw(QBit::QueryData::Function);

my $COUNT_THIS_OBJECT = 0;

sub init {
    my ($self) = @_;

    $self->set_error(gettext('You can use in request not more than one function "DISTINCT"'))
      if ++$COUNT_THIS_OBJECT > 1;

    $self->SUPER::init();

    return FALSE if $self->has_errors();

    $self->{'PATH'}           = $self->qd->_get_path($self->args->[0]);
    $self->{'__MAIN_FIELD__'} = $self->args->[0];
}

sub process {
    my ($self, $row) = @_;

    return
        '        $new_row->{'
      . $self->qd->quote($self->field) . '} = '
      . $self->qd->_get_field_code_by_path('$row', $self->{'PATH'}) . ';
';
}

sub DESTROY {$COUNT_THIS_OBJECT--}

TRUE;
