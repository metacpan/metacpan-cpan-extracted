#===============================================================================
#
#  DESCRIPTION:  replaceable item
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::R;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::R - Replaceable item

=head1 SYNOPSIS

    Then enter your details at the prompt:

    =for input
        Name: B<R<your surname>>
          ID: B<R<your employee number>>
        Pass: B<R<your 36-letter password>>

=head1 DESCRIPTION

The C<RE<lt>E<gt>> formatting code specifies that the contained text is a
B<replaceable item>, a placeholder, or a metasyntactic variable. It is
used to indicate a component of a syntax or specification that should
eventually be replaced by an actual value. For example:

    The basic C<ln> command is: C<ln> R<source_file> R<target_file>

or:

    Then enter your details at the prompt:

    =for input
        Name: R<your surname>
          ID: R<your employee number>
        Pass: R<your 36-letter password>

Typically replaceables would be rendered in fixed-width italics or with
C< E<lt>varE<gt>...E<lt>/varE<gt> > tags. The font used should be the same as that used for
the C<CE<lt>E<gt>> code, unless the C<RE<lt>E<gt>> is inside a C<KE<lt>E<gt>> or C<TE<lt>E<gt>> code (or
the equivalent C<=input> or C<=output> blocks), in which case their
respective fonts should be used.

=cut

use warnings;
use strict;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

=head2 to_xhtml

     Name: R<your surname>

Render xhtml:

     Name: <var>your surname</var>
    
=cut
sub to_xhtml {
 my ( $self, $to ) = @_;
 $to->w->raw('<var>');
 $to->visit( Perl6::Pod::Utl::parse_para($self->{content}->[0]) );
 $to->w->raw('</var>');
}

=head2 to_docbook

     Name: R<your surname>

Render to

    Name: <replaceable>your surname</replaceable> 

L<http://www.docbook.org/tdg/en/html/replaceable.html>
=cut

sub to_docbook {
 my ( $self, $to ) = @_;
 $to->w->raw('<replaceable>');
 $to->visit( Perl6::Pod::Utl::parse_para($self->{content}->[0]) );
 $to->w->raw('</replaceable>');
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


