use strict;
use warnings;
package MooseX; # git description: v0.001-19-gf7c0413
# ABSTRACT: Document the MooseX namespace
# KEYWORDS: Moose documentation namespace nomenclature best-practices extensions ecosystem
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.002';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX - Document the MooseX namespace

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::SomeExtension;

    ...

=head1 DESCRIPTION

The C<MooseX::*> namespace is for I<Moose extensions>, not a general space for
any module that happens to use L<Moose>.

Usually, such modules will make use of L<Moose::Exporter> to make their
extension available to the calling class. It may define a class or attribute
trait, apply a role, or perhaps provide sugar functions.

Things that do B<not> belong in the C<MooseX::*> namespace are: classes that
use Moose for their OO, and packages that use L<Moose::Role> to provide
implementation. Instead, name those modules for what they I<do> not how they
do it.

(This documentation is a preliminary placeholder for more information. Patches
welcome!)

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX>
(or L<bug-MooseX@rt.cpan.org|mailto:bug-MooseX@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Moose::Manual::MooseX>

=item *

L<MooseY>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
