package Test::Deep::Matcher::DataUtil;

use strict;
use warnings;
use Test::Deep::Cmp;
use Data::Util ();

sub init {
    my $self = shift;
    my ($name, @args) = @_;

    $self->{name}    = $name;
    $self->{matcher} = Data::Util->can($name);
    $self->{val}     = \@args;
}

sub descend {
    my ($self, $got) = @_;
    return $self->{matcher}->($got);
}

sub _expectation { join ' ' => split /_/ => shift->{name} }

sub diag_message {
    my ($self, $got) = @_;
    return sprintf 'Checking %s %s' => $got, $self->_expectation;
}

sub renderGot {
    my ($self, $val) = @_;

    if ($self->{name} =~ /_ref/) {
        return ref($val) || '(NONREF)';
    }
    else {
        return defined($val) ? $val : '(undef)';
    }
}

sub renderExp {
    my ($self, $val) = @_;

    if ($self->{name} =~ /is_(.+)_ref/) {
        return uc($1);
    }
    else {
        return sprintf '(%s)' => $self->_expectation;
    }
}

1;

__END__
