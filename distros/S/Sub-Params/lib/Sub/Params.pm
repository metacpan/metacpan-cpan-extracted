# © 2017-2018 GoodData Corporation

use 5.006;
use strict;
use warnings;

package Sub::Params;

our $VERSION = '1.0.0';

use parent 'Exporter';

use Hash::Util qw[];
use Ref::Util qw[ is_plain_hashref ];

our @EXPORT_OK = (
    'named_or_positional_arguments'
);

sub named_or_positional_arguments {
    my (%args) = @_;
    my $args = $args{args};
    my $names = $args{names};

    return unless $args;
    return unless @$args;
    return @$args unless @$names;

    # Use restricted hashes to detects how function was called
    my %params;
    Hash::Util::lock_keys %params, @$names;

    local $@;
    local $SIG{__DIE__};

    # single argument, hashref => can be named argument hashref
    return %params
        if @$args == 1
        and is_plain_hashref( $args->[0] )
        and eval { %params = %{ $args->[0] }; 1 }
	;

    # with even number of argument => looks like named arguments
    return %params
        if @$args % 2 == 0
        and eval { %params = @$args; 1 }
	;

    # with more arguments than names should be named arguments
    return %params
        if @$args <= @$names
        and do { @params{@$names} = @$args; 1 }
	;

    return @$args;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sub::Params - Handle function arguments

=head1 SYNOPSIS

   use Sub::Params qw[ named_or_positional_arguments ];

   sub foo {
      my ($self, @args) = @_;
	  my %args = named_or_positional_arguments(
         args => \@args,
         names => [qw[ foo bar baz]],
      )
   }

   # following calls are equivalent in behavior
   foo( 1, 2, 3 );
   foo( foo => 1, bar => 2, baz => 3 );
   foo( { foo => 1, bar => 2, baz => 3 });

=head1 DESCRIPTION

Module contains functions helping dealing with parameters.

=head2 named_or_positional_arguments( args => [], names => [] )

Helps coversion from positional to named arguments.

Use it only for minimal transition period, it is not intended for permanent usage.

Takes reference to actual function arguments and names in order of positional interface.

Parameters:

=over

=item args

Reference to argument array

=item names

Positional argument names in form used in named arguments call

=back

Function recognizes named arguments when:

=over

=item every odd parameter is name from names list

=item first and only argument is hashref with keys from names list

=back

Uses Hash::Util::lock_keys to detect valid names.

=head1 ACKNOWLEDGMENTS

Thanks L<< GoodData|https://gooddata.com >> for supporting open-source contribution

=head1 SUPPORT

This module comes with no warranty and is distributed as is.

To participate please use discussions using project's github issues.

=head1 REPOSITORY

https://github.com/gooddata/perl-sub-params

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


