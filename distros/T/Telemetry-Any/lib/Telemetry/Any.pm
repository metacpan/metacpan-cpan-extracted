package Telemetry::Any;
use 5.008001;
use strict;
use warnings;

use Carp;

use base 'Devel::Timer';

our $VERSION = "0.02";

my $telemetry = __PACKAGE__->new();

sub import {
    my ( $class, $var ) = @_;

    return if !defined $var;

    my $saw_var;
    if ( $var =~ /^\$(\w+)/x ) {
        $saw_var = $1;
    }
    else {
        croak('Аrgument must be a variable');
    }

    my $caller = caller();

    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my $varname = "${caller}::${saw_var}";
    *$varname = \$telemetry;

    return;
}

sub reset {              ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @_;

    %{$self} = (
        times => [],
        count => 0,
        label => {},
    );

    return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Telemetry::Any - It's new $module

=head1 SYNOPSIS

    use Telemetry::Any;

=head1 DESCRIPTION

Telemetry::Any is ...

=head1 LICENSE

Copyright (C) Mikhail Ivanov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mikhail Ivanov E<lt>m.ivanych@gmail.comE<gt>

=cut

