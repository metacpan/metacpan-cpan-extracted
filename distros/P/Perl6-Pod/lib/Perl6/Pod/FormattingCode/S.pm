#===============================================================================
#
#  DESCRIPTION:  Space-preserving text
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::S;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::S - Space-preserving text

=head1 SYNOPSIS

    The emergency signal is: S<
    dot dot dot   dash dash dash   dot dot dot>.

=head1 DESCRIPTION

Any text enclosed in an C<SE<lt>E<gt>> code is formatted normally, except that
every whitespace character in itE<mdash>including any newlineE<mdash>is
preserved. These characters are also treated as being non-breaking
(except for the newlines, of course). For example:

    The emergency signal is: S<
    dot dot dot   dash dash dash   dot dot dot>.

would be formatted like so:

    The emergency signal is: 
    dot dot dot   dash dash dash   dot dot dot.

rather than:

    The emergency signal is: dot dot dot dash dash dash dot dot dot.

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
    my ( $self, $parser, @in ) = @_;
    my @elements = $parser->_make_events(@in);

    #  $VAR1 = {
    #          'data' => \'
    #          dot dots dot   dash dash dash   dot dot dot',
    #                    'type' => 'CHARACTERS
    #    }
    # process only 'type' => 'CHARACTERS
    for (@elements) {
        next unless exists $_->{type};
        next unless $_->{type} eq 'CHARACTERS';

        #replase spaces -> &nbsp;  and new lines -> <br /> )
        ${ $_->{data} } =~ s% %&nbsp;%gs;
        ${ $_->{data} } =~ s%\n%<br />%gs;
    }
    \@elements;
}

=head2 to_docbook

    S<test>

Render to

    <literallayout>test</literallayout>


L<http://www.docbook.org/tdg/en/html/literallayout.html>

=cut

sub to_docbook {
    my ( $self, $parser, @in ) = @_;
    $parser->mk_element('literallayout')
      ->add_content( $parser->_make_events(@in) );
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



