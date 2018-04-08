package QBit::QueryData::Function::CONCAT;
$QBit::QueryData::Function::CONCAT::VERSION = '0.010';
use qbit;

use base qw(QBit::QueryData::Function);

sub one_argument {FALSE}

sub process {
    my ($self, $row) = @_;

    return join(
        '',
        map {
            ref($_) eq 'SCALAR'
              ? $$_
              : $self->qd->get_field_value_by_path($row, $row, undef, @{$self->qd->_get_path($_)})
              // ''
          } @{$self->args}
    );
}

TRUE;
