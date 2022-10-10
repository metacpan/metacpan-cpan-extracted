package Sub::Call::Tail; # git description: v0.07-8-g55f94e4
# ABSTRACT: Tail calls for subroutines and methods

use strict;
use warnings;

use 5.008001;
use parent qw(Exporter);
use XSLoader ();
use B::Hooks::OP::Check::EntersubForCV;

our $VERSION = '0.08';

our @EXPORT = our @EXPORT_OK = qw(tail);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

XSLoader::load(__PACKAGE__, $VERSION);

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Call::Tail - Tail calls for subroutines and methods

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Sub::Call::Tail;

    # instead of @_ = ( $object, @args ); goto $object->can("method")
    tail $object->method(@args);

    # instead of @_ = @blah; goto &foo
    tail foo(@blah);

=head1 DESCRIPTION

This module provides a C<tail> modifier for subroutine and method calls that
will cause the invocation to have the same semantics as C<goto &sub>.

When the C<tail> modifier is compiled the inner subroutine call is transformed
at compile time into a goto.

=head1 USAGE WARNING

B<WARNING>! The author does not endorse using this module for anything real.
It was written primarily to demonstrate that such quackery can be achieved.
Use at your own risk!

=head1 SEE ALSO

L<B::Hooks::OP::Check::EntersubForCV>

L<CPS>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Call-Tail>
(or L<bug-Sub-Call-Tail@rt.cpan.org|mailto:bug-Sub-Call-Tail@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Graham Knop Florian Ragwitz Andrew Main (Zefram) Ollis

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Andrew Main (Zefram) <zefram@fysh.org>

=item *

Graham Ollis <plicease@cpan.org>

=item *

Karen Etheridge <github@froods.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
