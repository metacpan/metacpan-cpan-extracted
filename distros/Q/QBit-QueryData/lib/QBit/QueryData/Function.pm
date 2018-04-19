package QBit::QueryData::Function;
$QBit::QueryData::Function::VERSION = '0.011';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_ro_accessors(qw(name qd path fields field args));

sub one_argument {TRUE}

sub init {
    my ($self, %opts) = @_;

    weaken($self->{'qd'});

    $self->{'__MAIN_FIELD__'} = '';

    if ($self->check()) {
        $self->set_args();

        $self->check_args();
    }
}

sub set_error {push(@{$_[0]->{'__ERRORS__'}}, $_[1])}

sub has_errors {scalar(@{$_[0]->{'__ERRORS__'} // []})}

sub get_error_message {join("\n", @{$_[0]->{'__ERRORS__'}})}

sub check {
    my ($self) = @_;

    if (ref($self->fields->{$self->field}{$self->name}) ne 'ARRAY') {
        $self->set_error(gettext('You must set arguments for function "%s": {%s => [...]}', $self->name, $self->name));

        return FALSE;
    }

    return TRUE;
}

sub set_args {
    my ($self) = @_;

    $self->{'args'} = $self->fields->{$self->field}{$self->name};
}

sub check_args {
    my ($self) = @_;

    if ($self->one_argument && @{$self->args} > 1) {
        $self->set_error(gettext('Function "%s" can not take more than one arguments', $self->name));
    }

    #TODO: check that fields from args exists

    return TRUE;
}

sub get_main_field {$_[0]->{'__MAIN_FIELD__'}}

TRUE;
