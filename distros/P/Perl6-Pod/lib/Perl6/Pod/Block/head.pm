#===============================================================================
#
#  DESCRIPTION:  =head
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Block::head;

=pod

=head1 NAME

Perl6::Pod::Block::head - handle B<=head> - Headings

=head1 SYNOPSIS


    =head1 A Top Level Heading
      =head2 A Second Level Heading
        =head3 A third level heading
                        =head86 A "Missed it by I<that> much!" heading

=head1 DESCRIPTION

B<=head> - Headings

Pod provides an unlimited number of levels of heading, specified by the
C<=headN> block marker.

=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
use Perl6::Pod::Utl;
use Data::Dumper;
our $VERSION = '0.01';

sub level {
    my $self = shift;
    $self->{level} || 1;    #default 1 level for head
}

sub to_xhtml {
    my ( $self, $to )= @_;
    my $w  = $to->w;
    my $level = $self->level;
    $w->raw( "<h$level>");
    $self->{content}->[0] = Perl6::Pod::Utl::parse_para($self->{content}->[0]);
    $to->visit_childs($self);
    $w->raw("</h$level>" );
}

sub to_docbook {
    my ( $self, $to )= @_;
    my $w  = $to->w;
    $w->raw( "<title>");
    $self->{content}->[0] = Perl6::Pod::Utl::parse_para($self->{content}->[0]);
    $to->visit_childs($self);
    $w->raw("</title>" );
}


sub to_latex {
    my ( $self, $to )= @_;
    my $w  = $to->w;
    my $level = $self->level;
    #http://en.wikibooks.org/wiki/LaTeX/Document_Structure
    my %level2latex = 
    ( 1 => 'section',
      2  => 'subsection',
      3 => 'subsubsection',
      4 => 'paragraph',
      5 => 'subparagraph'
    );
    unless (exists $level2latex{$level}) {
        warn "Level $level not supported by pod6latex. Set to: 5";
        $level = 5;
    };

    $w->raw('\\'.$level2latex{$level}.'{');
    $self->{content}->[0] = Perl6::Pod::Utl::parse_para($self->{content}->[0]);
    $to->visit_childs($self);
    $w->raw("}" );
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

Copyright (C) by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut



