package Perl6::Pod::FormattingCode::I;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::I - Important 

=head1 SYNOPSIS

        =para
        formatting code I<specifies>

=head1 DESCRIPTION

The C<IE<lt>E<gt>> formatting code specifies that the contained text is important; that it is of major significance. Such content would typically be rendered in italics or in C<E<lt>emE<gt>>...C<E<lt>/emE<gt>> tags.

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=head2 to_xhtml

    I<test>

Render xhtml:

    <em>test</em>
    
=cut
sub to_xhtml {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw("<em>");
    $to->visit_childs($self);
    $w->raw('</em>');
}

=head2 to_docbook

    I<test>

Render to

   <emphasis role='italic'>test</emphasis> 

=cut

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw("<emphasis role='italic'>");
    $to->visit_childs($self);
    $w->raw('</emphasis>');
}

=head2 to_latex

    I<test>

Render to

   \\emph{test} 

=cut

sub to_latex {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw("\\emph{");
    $to->visit_childs($self);
    $w->raw("}");
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

