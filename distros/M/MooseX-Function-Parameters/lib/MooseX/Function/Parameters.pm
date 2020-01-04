package MooseX::Function::Parameters;
use strictures 2;
use Const::Fast;

require Function::Parameters;
require Moose;

our $VERSION = '0.01';

# Function::Parameters uses the Moose type system by default
const my @FP_ARGS_V1 => ({
    fun    => { defaults => 'function_strict' },
    method => { defaults => 'method_strict' },
});

# Function::Parameters v2 does not use the Moose type system by default
const my @FP_ARGS_V2 => ({
    fun    => { defaults   => 'function_strict', reify_type => 'moose' },
    method => { defaults   => 'method_strict',   reify_type => 'moose' },
});

sub import {
    my ($caller) = caller;
    Function::Parameters::import($caller, _get_args());
}

sub unimport {
    my ($caller) = caller;
    Function::Parameters::unimport($caller, _get_args());
}

sub _get_args {
    my $version = $Function::Parameters::VERSION;
    return $version >= 2 ? @FP_ARGS_V2 : @FP_ARGS_V1;
}

1;

=head1 NAME

MooseX::Function::Parameters

=head1 SYNOPSIS

    use MooseX::Function::Parameters;

    fun add (Int $a, Int $b) {
        $a + $b
    }

    package My::Class;
    use Moose;
    use MooseX::Function::Parameters;

    method compare (My::Class $with) {
        $self->value <=> $with->value
    }

=head1 DESCRIPTION

A lightweight wrapper around B<Function::Parameters> which provides B<fun> and
B<method> subroutine keywords which integrate with the Moose type system.

Designed to be compatible with Function::Parameters version 1, where newer
versions of Function::Parameters aren't

=cut
