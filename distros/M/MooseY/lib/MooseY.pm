use strict;
use warnings;
package MooseY; # git description: v0.001-19-g087549a
# ABSTRACT: Document the MooseY namespace
# KEYWORDS: Moose documentation namespace nomenclature best-practices extensions ecosystem
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.002';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseY - Document the MooseY namespace

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package MyClass;
    use MooseY;

    ...

=head1 DESCRIPTION

The C<MooseY::*> namespace is I<tentatively> for modules that do not simply use L<Moose>,
but are dependent on L<Moose> in some way (i.e. it would have no meaning
outside of a Moose context).  This is to set the module apart from modules
that provide I<extensions> to L<Moose>, which belong in the C<MooseX::*>
namespace.

(This documentation is a preliminary placeholder for more information. Patches
welcome!)

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseY>
(or L<bug-MooseY@rt.cpan.org|mailto:bug-MooseY@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Moose::Manual::MooseX>

=item *

L<MooseX>

=item *

L<http://www.nntp.perl.org/group/perl.moose/2013/06/msg2644.html>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
