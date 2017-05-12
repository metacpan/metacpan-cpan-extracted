package Perl6::Pod::Block::nested;

=pod

=head1 NAME

Perl6::Pod::Block::nested - Nesting blocks

=head1 SYNOPSIS

    =begin nested
    We are all of us in the gutter,E<NL>
    but some of us are looking at the stars!
        =begin nested
        -- Oscar Wilde
        =end nested
    =end nested

=head1 DESCRIPTION

Any block can be nested by specifying a C<:nested> option on it:

    =begin para :nested
        We are all of us in the gutter,E<NL>
        but some of us are looking at the stars!
    =end para

However, qualifying each nested paragraph individually quickly becomes
tedious if there are many in a sequence, or if multiple levels of
nesting are required:

    =begin para
        We are all of us in the gutter,E<NL>
        but some of us are looking at the stars!
    =end para
    =begin para :nested(2)
            -- Oscar Wilde
    =end para

So Pod provides a C<=nested> block that marks all its contents as being
nested:

    =begin nested
    We are all of us in the gutter,E<NL>
    but some of us are looking at the stars!
        =begin nested
        -- Oscar Wilde
        =end nested
    =end nested

Nesting blocks can contain any other kind of block, including implicit
paragraph and code blocks. Note that the relative physical indentation
of the blocks plays no role in determining their ultimate nesting.
The preceding example could equally have been specified:

    =begin nested
    We are all of us in the gutter,E<NL>
    but some of us are looking at the stars!
    =begin nested
    -- Oscar Wilde
    =end nested
    =end nested

=head1 FORMATS

=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

=head2 to_xhtml

    =nested
    test code

Render to:

    <blockquote>
        test code
    </blockquote>
=cut

sub to_xhtml {
    my ( $self, $to ) = @_;
    $to->w->start_nesting();
    $to->visit_childs($self);
    $to->w->stop_nesting();
}

=head2 to_docbook

    =nested
    test code

Render to:

    <blockquote>
        test code
    </blockquote>
=cut

sub to_docbook {
    my ( $self, $to ) = @_;
    $to->w->start_nesting();
    $to->visit_childs($self);
    $to->w->stop_nesting();
}
1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

