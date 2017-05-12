package Perl6::Pod::FormattingCode::N;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::N - inline note

=head1 SYNOPSIS

 =begin code :allow<B>
    Use a C<for> loop instead.B<N<The Perl 6 C<for> loop is far more
    powerful than its Perl 5 predecessor.>> Preferably with an explicit
    iterator variable.
 =end code

=head1 DESCRIPTION

Anything enclosed in an C<NE<lt>E<gt>> code is an inline B<note>.
For example:

    Use a C<for> loop instead.B<N<The Perl 6 C<for> loop is far more
    powerful than its Perl 5 predecessor.>> Preferably with an explicit
    iterator variable.

Renderers may render such annotations in a variety of ways: as
footnotes, as endnotes, as sidebars, as pop-ups, as tooltips, as
expandable tags, etc. They are never, however, rendered as unmarked
inline text. So the previous example might be rendered as:


  Use a for loop instead. [*] Preferably with an explicit iterator
 variable.

and later:

    Footnotes
    [*] The Perl 6 for loop is far more powerful than its Perl 5
predecessor.

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=head2 to_xhtml

A footnote reference and footnote text are output to HTML as follows:

Footnote reference:

 <sup>[<a name="id394062" href="#ftn.id394062">1</a>]</sup>

Footnote:

 <div class="footnotes"><p>NOTES</p>
 <p><a name="ftn.id394062" href="#id394062"><sup>1</sup></a>
 Text of footnote ... </p>
 <div>

You can change the formatting of the footnote paragraph using CSS. Use the div.footnote CSS selector, and apply whatever styles you want with it, as shown in the following example.

 div.footnote {
    font-size: 8pt;
 }

    
=cut

#FOR REAL processing SEE Perl6::Pod::To::*

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    my $nid = ++$to->{CODE_N_COUNT};


    #<sup><a name="id394062" href="#ftn.id394062">[1]</a></sup>
    $w->raw(qq!<sup><a name="nid${nid}" href="#ftn.nid${nid}">[$nid]</a></sup>!);
    #save this element
    push @{ $to->{CODE_N} }, $self;
}

=head2 to_docbook

This element is a wrapper around the contents of a footnote. 

 <footnote><para> Some text </para></footnote>

L<http://www.docbook.org/tdg/en/html/footnote.html>

=cut

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw('<footnote><para>');
    $to->visit_childs($self);
    $w->raw('</para></footnote>');
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

