package Moose::Autobox::List;
# ABSTRACT: the List role
use Moose::Role 'with', 'requires';
use Moose::Autobox;
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Value';

requires 'head';
requires 'tail';
requires 'length';
requires 'join';
requires 'grep';
requires 'map';
requires 'sort';
requires 'reverse';

sub reduce {
    my ($array, $func) = @_;
    my $a = $array->values;
    my $acc = $a->head;
    $a->tail->map(sub { $acc = $func->($acc, $_) });
    return $acc;
}

sub zip {
    my ($array, $other) = @_;
    ($array->length < $other->length
        ? $other
        : $array)
            ->keys
            ->map(sub {
                [ $array->at($_), $other->at($_) ]
            });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::List - the List role

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is a role to describes a List interface. This is not
meant to be any specific Perl type, but instead an interface
that certain Perl types might implement. Currently only
L<Moose::Autobox::Array> implements this.

=head1 METHODS

=over 4

=item C<reduce>

=item C<zip>

=back

=over 4

=item C<meta>

=back

=head1 REQUIRED METHODS

=over 4

=item C<head>

=item C<tail>

=item C<join>

=item C<length>

=item C<map>

=item C<grep>

=item C<reverse>

=item C<sort>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
