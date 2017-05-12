#===============================================================================
#
#  DESCRIPTION:  terminal output
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::T;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::T - Terminal output

=head1 SYNOPSIS

        =para
        Got C<uname> output : T<FreeBSD>

=head1 DESCRIPTION

The C<TE<lt>E<gt>> formatting code specifies that the contained text is
B<terminal output>; that is: something that a program might print out.
Such content would typically be rendered in a T<fixed-width font> or with
C< E<lt>sampE<gt>...E<lt>/sampE<gt> > tags. The contents of a C<TE<lt>E<gt>> code are always space-preserved (as if they had an implicit
C<SE<lt>...E<gt>> around them). The C<TE<lt>E<gt>> code is the inline equivalent of the C<=output> block.

=cut

use warnings;
use strict;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

=head2 to_xhtml

    T<FreeBSD>

Render xhtml:

    <samp>test</samp>
    
=cut
sub to_xhtml {
 my ( $self, $to ) = @_;
 $to->w->raw('<samp>');
 $to->visit( Perl6::Pod::Utl::parse_para($self->{content}->[0]) );
 $to->w->raw('</samp>');
}

=head2 to_docbook

    T<FreeBSD>

Render to

   <computeroutput>FreeBSD</computeroutput> 

L<http://www.docbook.org/tdg/en/html/computeroutput.html>
=cut

sub to_docbook {
 my ( $self, $to ) = @_;
 $to->w->raw('<computeroutput>');
 $to->visit( Perl6::Pod::Utl::parse_para($self->{content}->[0]) );
 $to->w->raw('</computeroutput>');
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


