package Syntax::Infix::OptionalChain;

use 5.038;
use strict;
use warnings;

use Infix::Custom ();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Syntax::Infix::OptionalChain', $VERSION);

sub import {
    Infix::Custom->import(
        op     => '?->',
        call   => \&_nav,
        method => 1,
        prec   => 'mul',     # binds tightly and left-associatively, so it chains
    );
}

sub unimport {
    Infix::Custom->unimport('?->');
}

1;

__END__

=head1 NAME

Syntax::Infix::OptionalChain - a safe-navigation C<< ?-> >> operator for objects, hashes and arrays

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Syntax::Infix::OptionalChain;

    my $name = $maybe?->profile?->name // 'anonymous';

    # one operator, three kinds of right-hand side, chosen at run time:
    $object?->method  # $object->method     (blessed -> can -> method call)
    $hashref?->key    # $hashref->{key}     (HASH ref -> element)
    $arrayref?->0     # $arrayref->[0]      (ARRAY ref -> element)

    # mixed chains short-circuit at the first undef, with no autovivification
    # and no "Can't use an undefined value" deaths:
    my $port = $config?->servers?->0?->port // 8080;

=head1 DESCRIPTION

Installs a lexically-scoped infix operator C<< ?-> >> that walks one step into
its left operand and B<short-circuits to C<undef>> the moment that operand is
undefined. The right-hand side is a bareword, and how it is used depends on what
the left operand is at run time:

=over 4

=item * a B<blessed object> with that method -> a method call, C<< $obj->name >>;

=item * a B<HASH> reference -> a hash element, C<< $h->{name} >>;

=item * an B<ARRAY> reference -> an array element, C<< $a->[name] >>
(the bareword is used as the index, so write a number: C<< $a ?-> 0 >>);

=item * C<undef> -> C<undef>, ending the chain harmlessly.

=back

A blessed object is tried as a method call first; if it has no such method it
B<falls through> to structural access, so a blessed hashref or arrayref is
indexed by the bareword just like a plain one. (A consequence: an unknown name
on a blessed hashref is a key lookup, typically C<undef>, not a fatal
unknown-method error.)

Because C<< ?-> >> is left-associative and binds tightly (like C<*>), chains
read left to right and combine naturally with C<//> for defaults. A I<defined>
value that can be navigated no further -- a plain string, or a blessed/plain
ref that is neither a hash nor an array -- is a genuine error and croaks, rather
than being silently swallowed.

The operator is lexically scoped: it exists only in the file or block that
C<use>d the module, and C<no Syntax::Infix::OptionalChain;> removes it early.

=head2 Limitations

The right-hand side is a bareword captured at compile time, so it is a literal
method name / key / non-negative integer index. Argument lists
(C<< $o ?-> meth(@args) >>), negative indices and computed keys are not
supported; reach for an explicit C<< ->{...} >> / C<< ->[...] >> there.

=head2 Perl version

Requires perl 5.38 or newer -- the version that added the C<PL_infix_plugin>
hook L<Infix::Custom> builds on. As the operator is the module's entire reason
to exist, the distribution does not install on older perls.

=head1 SEE ALSO

L<Infix::Custom> -- the general custom-infix-operator mechanism this is built on.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
