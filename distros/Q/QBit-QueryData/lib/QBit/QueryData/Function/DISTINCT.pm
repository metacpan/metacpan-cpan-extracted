package QBit::QueryData::Function::DISTINCT;
$QBit::QueryData::Function::DISTINCT::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

my $COUNT_THIS_OBJECT = 0;

sub init {
    my ($self) = @_;

    $self->set_error(gettext('You can use in request not more than one function "DISTINCT"'))
      if ++$COUNT_THIS_OBJECT > 1;

    $self->SUPER::init();

    $self->{'__MAIN_FIELD__'} = $self->args->[0];
}

sub process {
    my ($self, $row) = @_;

    return $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($self->{'__MAIN_FIELD__'})});
}

sub DESTROY {$COUNT_THIS_OBJECT--}

TRUE;
