package Number::Finance::Human;
use parent qw(Exporter autobox);

our @EXPORT      = qw();
our @EXPORT_OK   = qw(to_number to_human);
our %EXPORT_TAGS = (all => \@EXPORT_OK, autobox => 1);

use Scalar::Util qw(looks_like_number blessed);
use strict;

$\ = "\n"; $, = "\t";

# ABSTRACT: human-readable numbers for accounting, finance and so on


my $precision = 2;

my $suffixes = {
		"k" => 1000,
		"M" => 1000 * 1000,
		"B" => 1000 * 1000 * 1000,
		"" => 1,
		"%" => 0.01,
		"c" => 0.01,
	       };

sub import {
    my $class = shift;
    # print @_;
    autobox->import( SCALAR => 'Number::Finance::Human::autobox') if grep { /^:autobox$/ } @_;
    $class->export_to_level(1, $class, @_);
}

sub new {
    my $class = shift;
    my $s = shift();
    my $n = looks_like_number $s ?
	$s :
	to_number($s)
	;
    return bless [ $n, $s ], $class;
}

sub to_number {
    local $_ = shift;
    return $_->[0] if blessed $_;

    my ($n, $s, $e) = /(.+?)([a-zA-Z%])(.*)/;
    return $n * ($suffixes->{$s} || $suffixes->{lc $s} || $suffixes->{uc $s});
}

sub to_human {
    my $number = shift;

    return $number->[1] if blessed $number && $number->[1] =~ /\D/;

    $number = $number->[0] if blessed $number;

    my $precision = (defined $_[0]) ? shift : $precision;

    for (reverse sort { $suffixes->{$a} <=> $suffixes->{$b} } grep { /[a-z]/i || /^$/ } keys $suffixes->%*) {
	return sprintf "%0.${precision}f%s", $number / $suffixes->{$_}, $_
	    if $number >= $suffixes->{$_}
    }
}

*to_string = *to_human;

# -------------------------------------------

use overload
    '0+' => \&to_number,
    '""' => \&to_human,
    '+'  => 'op_add',
    '-'  => 'op_sub',
    '*'  => 'op_mul',
    '/'  => 'op_div',
    fallback => 1
    ;

sub op_add {
    my ($va, $vb, $swap) = @_;
    $vb = ref $vb && $vb->isa(__PACKAGE__) ? $vb : __PACKAGE__->new($vb);
    return __PACKAGE__->new($va->to_number + $vb->to_number);
}

sub op_mul {
    my ($va, $vb, $swap) = @_;
    $vb = ref $vb && $vb->isa(__PACKAGE__) ? $vb : __PACKAGE__->new($vb);
    return __PACKAGE__->new($va->to_number * $vb->to_number);
}

sub op_div {
    my ($va, $vb, $swap) = @_;
    $vb = ref $vb && $vb->isa(__PACKAGE__) ? $vb : __PACKAGE__->new($vb);

    return $swap ? 
	__PACKAGE__->new($vb->to_number / $va->to_number) :
	__PACKAGE__->new($va->to_number / $vb->to_number);
}

sub op_sub {
    my ($va, $vb, $swap) = @_;
    $vb = ref $vb && $vb->isa(__PACKAGE__) ? $vb : __PACKAGE__->new($vb);

    return $swap ? 
	__PACKAGE__->new($vb->to_number - $va->to_number) :
	__PACKAGE__->new($va->to_number - $vb->to_number);
}

package Number::Finance::Human::autobox;

sub to_nfh { Number::Finance::Human->new(shift) }

sub to_human { Number::Finance::Human->new(shift)->to_human }

sub to_number { Number::Finance::Human->new(shift)->to_number }

1;

=encoding UTF-8

=pod

=head1 NAME

Number::Finance::Human - Human-readable numbers for accounting and finance

=head1 SYNOPSIS

    use Number::Finance::Human qw(to_number to_human);

    my $n = to_number("2.5M");   # 2500000
    my $h = to_human(1500);     # "1.50k"

    my $x = Number::Finance::Human->new("3k");
    say $x + 500;               # "3.50k"

    use Number::Finance::Human ':autobox';
    say 2500000->to_human;      # "2.50M"

=head1 DESCRIPTION

This module converts between numeric values and human-readable
representations commonly used in finance and accounting.

It supports suffixes such as C<k>, C<M>, C<B>, C<%>, and C<c>, and provides
operator overloading so objects behave like numbers while stringifying to
human-readable form.

=head1 SUFFIXES

The following suffixes are recognized:

    k   1_000
    M   1_000_000
    B   1_000_000_000
    %   0.01
    c   0.01
    (empty) 1

Suffix matching is case-insensitive.

=head1 FUNCTIONS

=head2 to_number($value)

Converts a human-readable string (e.g. C<"2.5M">, C<"10%">) into a numeric
value.

If passed a C<Number::Finance::Human> object, returns its numeric value.

=head2 to_human($number [, $precision ])

Formats a numeric value as a human-readable string using the largest
applicable suffix.

An optional precision (default: 2) controls the number of decimal places.

If called on an object that was constructed from a non-numeric string, the
original string is preserved.

=head1 METHODS

=head2 new($value)

Creates a new C<Number::Finance::Human> object from either a numeric value
or a human-readable string.

=head2 to_number

Returns the numeric value of the object.

=head2 to_human

Returns the human-readable string representation.

=head2 to_string

Alias for C<to_human>.

=head1 OPERATOR OVERLOADING

Objects overload the following operators:

    0+    numeric context
    ""    string context (human-readable)
    + - * /

Arithmetic between objects or scalars returns a new
C<Number::Finance::Human> object.

=head1 AUTOBOXING

When imported with C<:autobox>, scalar values gain the following methods:

    to_nfh
    to_number
    to_human

Example:

    use Number::Finance::Human ':autobox';
    say 1200000->to_human;   # "1.20M"

=head1 EXPORTS

Nothing is exported by default.

Optional exports:

    to_number
    to_human

Tag:

    :all       exports all functions
    :autobox   enables autoboxing

=head1 SEE ALSO

L<autobox>, L<Scalar::Util>

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
