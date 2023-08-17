package safenav;
use strict;
use warnings;
use PerlX::SafeNav ('$safenav', '$unsafenav', '&safenav');

use Exporter 'import';
our @EXPORT = ('&safenav');

*begin = *wrap = $safenav;
*end = *unwrap = $unsafenav;

1;

=pod

=encoding utf-8

=head1 NAME

safenav - Safe-navigation for Perl

=head1 SYNOPSIS

    use safenav;

    my $obj = Foo->new;
    my $ret;

    # block syntax
    $ret = safenav { $_->x()->y()->z() } $obj;

    # wrap + unwrap
    $ret = $obj-> safenav::wrap() ->x()->y()->z() -> safenav::unwrap();

    # begin + end
    $ret = $obj-> safenav::begin() ->x()->y()->z() -> safenav::end();

    unless (defined $ret) {
        # The car either have no wheels, or the first wheel has no tire.
        ...
    }

=head1 DESCRIPTION

The C<safenav> pragma is part of L<PerlX::SafeNav>. It provides alternative interfaces for wrapping a chain of calls and make it safe from encountering C<undef> values in the way. If any of sub-expressions yield C<undef>, instead of aborting the program with an error message, the entire chain yields C<undef> instead.

Say we have this call chain on object C<$o>, and each sub-expression right next to the C<< -> >> operators may yield C<undef>:

    $o->a()->{b}->c()->[42]->d();

To make it safe from encountering C<undef> values, we wrap the chain with C<safenav::wrap()> and C<safenav::unwrap()>:

    $o-> safenav::wrap() -> a()->{b}->c()->[42]->d() -> safenav::unwrap();

... or with C<safenav::begin()> and C<safenav::end()>:

    $o-> safenav::begin() -> a()->{b}->c()->[42]->d() -> safenav::end()

... or, with a C<safenav { ... }> block:

    safenav {
        $_->a()->{b}->c()->[42]->d()
    } $o;

... in which, C<$_> is the safenav-wrapped version of C<$o>, and the chain is automaticly un-wrapped at the end.

Whichever seems better for you.

=head1 SEE ALSO

L<PerlX::SafeNav>, L<results::wrap>

=cut
