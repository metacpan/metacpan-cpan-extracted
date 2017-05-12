package Pod::ToDocBook::DoSequences;

#$Id: DoSequences.pm 436 2009-02-03 16:53:12Z zag $

=head1 NAME

Pod::ToDocBook::DoSequences - Process Formatting Codes (a.k.a. "interior sequences")

=head1 SYNOPSIS

    use Pod::ToDocBook::Pod2xml;
    use XML::ExtOn ('create_pipe');
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe(
        $px, qw( Pod::ToDocBook::DoSequences ),
        $w
    );
    $p->parse($text);

=head1 DESCRIPTION

Pod::ToDocBook::DoSequences - Process Formatting Codes (a.k.a. "interior sequences")

=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use XML::ExtOn;
use base 'XML::ExtOn';

my %HTML_Escapes = (
    'amp'    => '&',    #   ampersand
    'lt'     => '<',    #   left chevron, less-than
    'gt'     => '>',    #   right chevron, greater-than
    'quot'   => '"',    #   double quote
    'sol'    => '/',    #   slash
    'verbar' => '|',    #   vertical bar

    "Aacute" => "\xC3\x81",    #   capital A, acute accent
    "aacute" => "\xC3\xA1",    #   small a, acute accent
    "Acirc"  => "\xC3\x82",    #   capital A, circumflex accent
    "acirc"  => "\xC3\xA2",    #   small a, circumflex accent
    "AElig"  => "\xC3\x86",    #   capital AE diphthong (ligature)
    "aelig"  => "\xC3\xA6",    #   small ae diphthong (ligature)
    "Agrave" => "\xC3\x80",    #   capital A, grave accent
    "agrave" => "\xC3\xA0",    #   small a, grave accent
    "Aring"  => "\xC3\x85",    #   capital A, ring
    "aring"  => "\xC3\xA5",    #   small a, ring
    "Atilde" => "\xC3\x83",    #   capital A, tilde
    "atilde" => "\xC3\xA3",    #   small a, tilde
    "Auml"   => "\xC3\x84",    #   capital A, dieresis or umlaut mark
    "auml"   => "\xC3\xA4",    #   small a, dieresis or umlaut mark
    "Ccedil" => "\xC3\x87",    #   capital C, cedilla
    "ccedil" => "\xC3\xA",     #   small c, cedilla
    "Eacute" => "\xC3\x89",    #   capital E, acute accent
    "eacute" => "\xC3\xA9",    #   small e, acute accent
    "Ecirc"  => "\xC3\x8A",    #   capital E, circumflex accent
    "ecirc"  => "\xC3\xAA",    #   small e, circumflex accent
    "Egrave" => "\xC3\x88",    #   capital E, grave accent
    "egrave" => "\xC3\xA8",    #   small e, grave accent
    "ETH"    => "\xC3\x90",    #   capital Eth, Icelandic
    "eth"    => "\xC3\xB0",    #   small eth, Icelandic
    "Euml"   => "\xC3\x8B",    #   capital E, dieresis or umlaut mark
    "euml"   => "\xC3\xAB",    #   small e, dieresis or umlaut mark
    "Iacute" => "\xC3\x8D",    #   capital I, acute accent
    "iacute" => "\xC3\xAD",    #   small i, acute accent
    "Icirc"  => "\xC3\x8E",    #   capital I, circumflex accent
    "icirc"  => "\xC3\xAE",    #   small i, circumflex accent
    "Igrave" => "\xC3\x8D",    #   capital I, grave accent
    "igrave" => "\xC3\xAD",    #   small i, grave accent
    "Iuml"   => "\xC3\x8F",    #   capital I, dieresis or umlaut mark
    "iuml"   => "\xC3\xAF",    #   small i, dieresis or umlaut mark
    "Ntilde" => "\xC3\x91",    #   capital N, tilde
    "ntilde" => "\xC3\xB1",    #   small n, tilde
    "Oacute" => "\xC3\x93",    #   capital O, acute accent
    "oacute" => "\xC3\xB3",    #   small o, acute accent
    "Ocirc"  => "\xC3\x94",    #   capital O, circumflex accent
    "ocirc"  => "\xC3\xB4",    #   small o, circumflex accent
    "Ograve" => "\xC3\x92",    #   capital O, grave accent
    "ograve" => "\xC3\xB2",    #   small o, grave accent
    "Oslash" => "\xC3\x98",    #   capital O, slash
    "oslash" => "\xC3\xB8",    #   small o, slash
    "Otilde" => "\xC3\x95",    #   capital O, tilde
    "otilde" => "\xC3\xB5",    #   small o, tilde
    "Ouml"   => "\xC3\x96",    #   capital O, dieresis or umlaut mark
    "ouml"   => "\xC3\xB6",    #   small o, dieresis or umlaut mark
    "szlig"  => "\xC3\x9F",    #   small sharp s, German (sz ligature)
    "THORN"  => "\xC3\x9E",    #   capital THORN, Icelandic
    "thorn"  => "\xC3\xBE",    #   small thorn, Icelandic
    "Uacute" => "\xC3\x9A",    #   capital U, acute accent
    "uacute" => "\xC3\xBA",    #   small u, acute accent
    "Ucirc"  => "\xC3\x9B",    #   capital U, circumflex accent
    "ucirc"  => "\xC3\xBB",    #   small u, circumflex accent
    "Ugrave" => "\xC3\x99",    #   capital U, grave accent
    "ugrave" => "\xC3\xB9",    #   small u, grave accent
    "Uuml"   => "\xC3\x9C",    #   capital U, dieresis or umlaut mark
    "uuml"   => "\xC3\xBC",    #   small u, dieresis or umlaut mark
    "Yacute" => "\xC3\x9D",    #   capital Y, acute accent
    "yacute" => "\xC3\xBD",    #   small y, acute accent
    "yuml"   => "\xC3\xBF",    #   small y, dieresis or umlaut mark

    "lchevron" => "\xC2\xAB",  #   left chevron (double less than)
    "rchevron" => "\xC2\xBB",  #   right chevron (double greater than)
);

sub _on_start_document {
    my ( $self, $data ) = @_;
    $self->SUPER::on_start_document($data);
}

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    return $el if $lname ne 'code';
    my $attr = $el->attrs_by_name;

    # delete <code> tag
    $el->delete_element;
    my $code = $attr->{name};

    if ( $code eq 'I' ) {
        $attr->{para} = $el->{TITLE};

        #diag Dumper $el;
    }
    $el;
}

#process conten of  code
sub on_cdata {
    my ( $self, $el, $text ) = @_;
    return $text unless $el->local_name eq 'code';

    #clean
    $text =~ s/^\w<(.*)>$/$1/;
    $el->{TITLE} = $text;

    #return $text;
    return undef;
}

sub process_L {
    my ( $self, $el ) = @_;
    my $attr  = $el->attrs_by_name;
    my $ltype = $attr->{type};

    if ( $ltype eq 'url' ) {
        my $ulink = $el->mk_element('ulink');
        $ulink->attrs_by_name->{url} = $attr->{linkto};
        $ulink->add_content( $self->mk_characters( $attr->{text} ) );
        return $ulink;
    }
    if ( $ltype eq 'pod' ) {
        my $link = $el->mk_element('link');
        $link->attrs_by_name->{linkend} = $attr->{linkto};
        $link->add_content( $el->mk_element('quote')
              ->add_content( $self->mk_characters( $attr->{text} ) ) );
        return $link;
    }

    #process man type
    my ( $title, $volnum ) = ( $attr->{text}, '' );
    if ( $title =~ /(.+?)\((.+)\)/xms ) {
        ( $title, $volnum ) = ( $1, "<manvolnum>$2</manvolnum>" );
    }
    return $self->mk_from_xml(
qq!<citerefentry><refentrytitle>$title</refentrytitle>$volnum</citerefentry>!
    );
    my $text = $el->{TITLE};
    return $el;
}

sub on_end_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;

    #skip
    return $el unless $lname eq 'code';
    my $attr = $el->attrs_by_name;
    my $code = $attr->{name};

    if ( $code =~ /^I|B$/ ) {

        #<emphasis role="italic">text</emphasis>
        ( my $emp = $el->mk_element('emphasis') )->attrs_by_name->{role} =
          $code eq 'B' ? 'bold' : 'italic';
        $emp->add_content( $self->mk_characters( $el->{TITLE} ) );
        return $emp;
    }
    elsif ( $code eq 'F' ) {
        return $el->mk_element('filename')
          ->add_content( $self->mk_characters( $el->{TITLE} ) );
    }
    elsif ( $code eq 'X' ) {
        return $el->mk_element('indexterm')
          ->add_content( $el->mk_element('primary')
              ->add_content( $self->mk_characters( $el->{TITLE} ) ) );
        return $self->mk_from_xml(
            qq!<indexterm><primary>$el->{TITLE}</primary></indexterm>!)

    }
    elsif ( $code eq 'Z' ) {
        return $self->mk_characters( $el->{TITLE} );
    }
    elsif ( $code eq 'C' ) {
        ( my $literal = $el->mk_element('literal') )->attrs_by_name->{role} =
          'code';
        $literal->add_content( $self->mk_cdata( $el->{TITLE} ) );
        return $literal;
    }
    elsif ( $code eq 'S' ) {
        my $str = $el->{TITLE};
        $str =~ s/\s(?![^<]*>)/&nbsp;/gx;
        return $self->mk_characters($str);
    }
    elsif ( $code eq 'E' ) {
        my $str = $el->{TITLE};
        if ( $str !~ /\A\w+\z/xms ) {
            die "invalide escape (E<$str>) at line: $el->{LINE_NUM}";
        }
        $str =
            exists( $HTML_Escapes{$str} ) ? $HTML_Escapes{$str}
          : $str =~ /^0x/xms   ? '&#' . hex($str) . ';'
          : $str =~ /^0/xms    ? '&#' . oct($str) . ';'
          : $str =~ /^\d+$/xms ? "&#$str;"
          : "\xC3$str;";
        return $self->mk_characters($str);
    }
    elsif ( $code eq 'L' ) {
        return $self->process_L($el);
    }
    $el;
}

1;

__END__

=head1 SEE ALSO

XML::ExtOn,  Pod::2::DocBook

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

