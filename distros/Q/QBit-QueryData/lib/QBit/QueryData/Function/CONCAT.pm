package QBit::QueryData::Function::CONCAT;
$QBit::QueryData::Function::CONCAT::VERSION = '0.011';
use qbit;

use base qw(QBit::QueryData::Function);

sub one_argument {FALSE}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    return FALSE if $self->has_errors();

    $self->{'PATHS'} = [map {ref($_) eq 'SCALAR' ? $_ : $self->qd->_get_path($_)} @{$self->args}];
}

sub process {
    my ($self) = @_;

    return
        '            $new_row->{' 
      . $self->qd->quote($self->field) 
      . '} = join("", '
      . join(', ',
        map {ref($_) eq 'SCALAR' ? $self->qd->quote($$_ // '') : $self->qd->_get_field_code_by_path('$row', $_) // ''}
          @{$self->{'PATHS'}})
      . ');
';
}

TRUE;
