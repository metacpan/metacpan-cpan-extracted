package SQL::QueryBuilder::Flex::Join;

use strict;
use warnings;
use SQL::QueryBuilder::Flex::Exp;
use base 'SQL::QueryBuilder::Flex::Statement';

sub new {
    my ($class, @options) = @_;
    my $self = $class->SUPER::new(
        type    => undef,
        table   => undef,
        alias   => undef,
        on      => undef,
        using   => [],
        @options,
    );
    return $self;
}

sub table {
    my ($self) = @_;
    return $self->{table};
}

sub alias {
    my ($self) = @_;
    return $self->{alias};
}

sub on {
    my ($self, $condition, @values) = @_;
    die "The 'USING' clause is already defined"
        if scalar(@{ $self->{using} });
    my $cond_list = $self->{on} ||= SQL::QueryBuilder::Flex::Exp->new(
        parent => $self,
    );
    return $condition
        ? $cond_list->and($condition, @values)->parent()
        : $cond_list
    ;
}

sub using {
    my ($self, @columns) = @_;
    die "The 'ON' clause is already defined"
        if $self->{on};
    push @{ $self->{using} }, @columns;
    return $self;
}

sub do_build {
    my ($self, $writer, $indent) = @_;

    $indent ||= 0;

    if (ref $self->{table}) {
        $writer->write(join(' ', $self->{type}, 'JOIN ('), $indent);
        $self->{table}->build($writer, $indent + 1);
        $writer->write(join(' AS ',')', $self->{alias}), $indent);
    }
    else {
        my $table = $self->{alias}
            ? join(' ', $self->{table}, $self->{alias})
            : $self->{table}
        ;
        $writer->write(join(' ', $self->{type}, 'JOIN', $table), $indent);
    }

    if ( $self->{on} ) {
        $writer->write('ON', $indent);
        $self->{on}->build($writer, $indent + 1);
    }
    elsif ( scalar(@{ $self->{using} }) ) {
        $writer->write('USING ('. join(', ', @{ $self->{using} }). ')', $indent);
    }

    return;
}

1;
