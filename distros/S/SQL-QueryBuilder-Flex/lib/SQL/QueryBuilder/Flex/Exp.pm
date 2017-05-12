package SQL::QueryBuilder::Flex::Exp;

use strict;
use warnings;
use base 'SQL::QueryBuilder::Flex::Statement';

sub new {
    my ($class, @options) = @_;
    my $self = $class->SUPER::new(
        _childs => [],
        @options,
    );
    return $self;
}

sub is_empty {
    my ($self) = @_;
    return scalar(@{ $self->{_childs} }) ? 0 : 1;
}

sub or {
    my ($self, $exp, @params) = @_;

    # Create instance if this method has been called directly
    if (!ref $self) {
        $self = __PACKAGE__->new;
    }

    push @{ $self->{_childs} }, [ 'OR', $exp, @params ];
    return $self;
}

sub or_exp {
    my ($self) = @_;
    my $new_exp = __PACKAGE__->new(parent => $self);
    push @{ $self->{_childs} }, [ 'OR', $new_exp ];
    return $new_exp;
}

sub or_in {
    my ($self, $name, @params) = @_;

    unless (scalar @params) {
        return $self->or('0');
    }

    my $exp = $name .' IN('. join(',', ('?') x @params) .')';

    return $self->or($exp, @params);
}

sub or_not_in {
    my ($self, $name, @params) = @_;

    unless (scalar @params) {
        return $self->or('1');
    }

    my $exp = $name .' NOT IN('. join(',', ('?') x @params) .')';

    return $self->or($exp, @params);
}

sub and {
    my ($self, $exp, @params) = @_;

    # Create instance if this method has been called directly
    if (!ref $self) {
        $self = __PACKAGE__->new;
    }

    push @{ $self->{_childs} }, [ 'AND', $exp, @params ];
    return $self;
}

sub and_exp {
    my ($self) = @_;
    my $new_exp = __PACKAGE__->new(parent => $self);
    push @{ $self->{_childs} }, [ 'AND', $new_exp ];
    return $new_exp;
}

sub and_in {
    my ($self, $name, @params) = @_;

    unless (scalar @params) {
        return $self->and('0');
    }

    my $exp = $name .' IN('. join(',', ('?') x @params) .')';

    return $self->and($exp, @params);
}

sub and_not_in {
    my ($self, $name, @params) = @_;

    unless (scalar @params) {
        return $self->and('1');
    }

    my $exp = $name .' NOT IN('. join(',', ('?') x @params) .')';

    return $self->and($exp, @params);
}

sub do_build {
    my ($self, $writer, $indent) = @_;

    $indent ||= 0;

    my $is_first = 1;
    foreach my $child (@{ $self->{_childs} }) {
        my ($op, $exp, @params) = @$child;
        if (ref $exp) {
            next if $exp->is_empty();
            my $str = $is_first ? '(' : join(' ', $op, '(');
            $writer->write($str, $indent);
            $exp->build($writer, $indent + 1);
            $writer->write(')', $indent);
        }
        else {
            my $str = $is_first ? $exp : join(' ', $op, $exp);
            $writer->write($str, $indent);
            $writer->add_params(@params);
        }
        undef $is_first;
    }

    return;
}

1;
