package Scalar::IfDefined;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw/blessed reftype/;

use Exporter 'import';
our @EXPORT_OK = qw/ifdef $ifdef lifdef/;


our $VERSION = '0.09';


sub ifdef(&$) {
    scalar &lifdef;
}


sub lifdef (&$) {
    my ($block, $scalar) = @_;
    return if not defined $scalar;
    return $block->($scalar) for $scalar;
}


our $ifdef = sub {
    my $obj = shift;
    my ($method, @args) = @_;

    return undef if not defined $obj;

    return $obj->$method(@args)   if blessed $obj or ifdef {$_ eq 'CODE'} reftype($method);
    return $obj->[$method]        if reftype $obj eq 'ARRAY';
    return $obj->{$method}        if reftype $obj eq 'HASH';
    return $obj->($method, @args) if reftype $obj eq 'CODE';

    die "Can't getdef on " . reftype $obj;
};



1; # End of Scalar::IfDefined

__END__

=pod

=encoding UTF-8

=head1 NAME

Scalar::IfDefined

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Scalar::IfDefined qw/ifdef/;

    my $hash = {
        a => 1,
        b => 2,
        c => 3,
        d => {
            E => 1,
            F => 2,
        },
    };

    ifdef { $_ + 1 } $hash->{a};   # ---> 2
    ifdef { $_ + 1 } $hash->{missing};    # ---> undef
    ifdef { $_ + 1 } ifdef { $_->{F} } $hash->{d};  # ---> 3
    ifdef { $_ + 1 } ifdef { $_->{MISSING} } $hash->{d};  # ---> undef


    # Or perhaps with Perl6::Flows

    use Perl6::Flows;
    my $result = (
        $hash->{a} 
            ==> ifdef { $_->{F} }
            ==> ifdef { $_ + 1 }
    );            # ---> 3

=head1 NAME

Scalar::IfDefined - Apply block to scalar depending on if it's defined.

=head1 EXPORT

=over 4

=item ifdef

=item $ifdef

=back

=head1 SUBROUTINES/METHODS

=head2 ifdef

Takes a block and a scalar value.

If the scalar value is undef, the block is ignored and undef is returned
straight away.

If the scalar value is defined, then the block is evaluated with $_ as
the value passed in, and the result of the block is returned.

=head2 lifdef

Like C<ifdef>, except returns the empty list. In scalar context, therefore, this
works identically to C<ifdef>, but when in a list (e.g. an argument list or
hashref constructor), it will return zero values if the argument was undef.

    # Creates { key => $some_value }, or { undef } and warnings:
    # Odd number of elements in anonymous hash
    # Use of uninitialized value in anonymous hash
    my $href = {
        ifdef { key => $_ } $some_value
    };

    # Creates { key => value }, or {}
    my $href = {
        lifdef { key => $_ } $some_value
    };

=head2 $ifdef

Used to dereference a possibly-undef scalar.

If the scalar is undef, returns undef.

If the scalar is an object, the first argument is the method to call, and the
rest of the arguments are the method arguments.

If the scalar is an array ref, the first argument is used to index into the
array.

If the scalar is a hash ref, the first argument is used to access the hash.

If the scalar is a code ref, the code ref is run with all the arguments.

As a special case, if the first argument is a code ref, it will be run with the
scalar as the first argument and the other arguments as the rest. This form
allows you to use C<$ifdef> on a simple scalar - but you might be better off
with C<ifdef> itself for that.

The following uses will all return undef if the C<$scalar> is undef, or The
Right Thing if not.

    # Run "method_name" on $obj, if $obj is defined.
    $obj->$ifdef("method_name", "argument", "argument");

    # Run $coderef with two arguments if $coderef is defined.
    $coderef->$ifdef("argument", "argument");

    # Lowercase the zeroth element of the arrayref, or undef if either of those
    # things is undef.
    $arrayref->$ifdef(0)->$ifdef(sub { lc });

    # Call "method_name" on $hashref->{object}, or return undef if either of
    # those is undef
    $hashref->$ifdef('object')->$ifdef('method_name');

=head1 AUTHOR

Nick Booker, C<< <NMBooker at gmail.com> >>

=head1 BUGS

L<https://github.com/nmbooker/p5-Scalar-IfDefined/issues>

=head1 ACKNOWLEDGEMENTS

=head2 Alastair McGowan-Douglas (ALTREUS)

For developing the C<$ifdef> (coderef) form.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Nick Booker

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Nick Booker <NMBooker@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Booker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
