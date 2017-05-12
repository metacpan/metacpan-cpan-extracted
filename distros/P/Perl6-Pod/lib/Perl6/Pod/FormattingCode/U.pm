package Perl6::Pod::FormattingCode::U;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::U - Unusual text

=head1 SYNOPSIS

        =para
        the contained text is U<unusual>

=head1 DESCRIPTION

The C<UE<lt>E<gt>> formatting code specifies that the contained text is
B<unusual> or distinctive; that it is of I<minor significance>. Typically
such content would be rendered in an underlined style.

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=head2 to_xhtml

    U<sample>

Render xhtml:

    <em class="unusual" >sample</em>

Use css style for underline style:

     .unusual {
     font-style: normal;
     text-decoration: underline;
     }

=cut

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw('<em class="unusual">');
    $to->visit_childs($self);
    $w->raw('</em>');
}

=head2 to_docbook

    U<sample>

Render to

   <emphasis role='underline'>test</emphasis> 

=cut
#http://old.nabble.com/docbook-with-style-info-td25857763.html

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw('<emphasis role="underline">');
    $to->visit_childs($self);
    $w->raw('</emphasis>');

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

