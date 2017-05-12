package Spica::Event;
use strict;
use warnings;

use Scalar::Util ();
use if $] >= 5.009_005, 'mro';
use if $] <  5.009_005, 'MRO::Compat';

use Mouse::Role;

sub on {
    my ($context, $name, $code) = @_;

    if (ref $context) {
        push @{ $context->{_spica_event}{$name} } => $code;
    } else {
        no strict 'refs'; ## no critic
        push @{ ${"${context}::_spica_event"}{$name} } => $code;
    }

    return $context;
}

sub trigger {
    my ($context, $name, @args) = @_;
    my @code = $context->get_code($name);

    $_->($context, @args) for @code;

    return $context;
}

sub get_code {
    my ($context, $name) = @_;
    my @code;

    if (Scalar::Util::blessed($context)) {
        push @code, @{ $context->{_spica_event}->{$name} || [] };
        $context = ref $context;
    }

    no strict 'refs'; ## no critic
    my $class = ref $context || $context;
    for (@{ mro::get_linear_isa($context) }) {
        push @code, @{ ${"${_}::_spica_event"}->{$name} || [] };
    }

    return @code;
}

1;
