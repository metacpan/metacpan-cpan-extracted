package Quiq::Sdoc::Figure;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.135;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Figure - Bild

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Abbildung.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item file => $url

Pfad/URL der Bilddatei.

=item width => $n

Breite des Bildes.

=item height => $n

Höhe des Bildes.

=item style => $cssDef

CSS-Definition

=item title => $str

Überschrift.

=item center => $bool

Zentriere Abbildung

=item url => $url

Mache Bild zu einem Link auf $url.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent,$att);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Figure',
        file=>undef,
        width=>undef,
        height=>undef,
        style=>undef,
        title=>undef,
        number=>undef,
        center=>$parent->rootNode->{'centerTablesAndFigures'},
        url=>undef,
    );
    $self->parent($parent); # schwache Referenz
    # $self->lockKeys;
    $self->set(@$att);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 visibleTitle() - Liefere den Abbildungs-Titel, wie er ins Dokument geschrieben wird

=head4 Synopsis

    $text = $node->visibleTitle($format);

=cut

# -----------------------------------------------------------------------------

sub visibleTitle {
    my ($self,$format) = @_;

    my $root = $self->rootNode;

    # Abbildung|Figure N

    my $title;
    if ($root->{'tableAndFigureNumbers'}) {
        my $language = $root->{'language'};
        if ($language eq 'german') {
            $title = 'Abbildung';
        }
        else {
            $title = 'Figure';
        }
        $title .= " $self->{'number'}: ";
    }

    # Titel, wie er in der Quelle steht

    if (my $text = $self->{'title'}) {
        $title .= $text;
    }
    else {
        # FIXME: von Link auf Bild abhängig machen
        $title = '';
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge externe Repräsentation für Abbildung

=head4 Synopsis

    $str = $node->dump($format,@args);

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    if ($format eq 'debug') {
        return qq(FIGURE "$self->{'file'}");
    }
    elsif ($format =~ /^(e?html|pod)$/) {
        my $h = shift || Quiq::Html::Tag->new; # FIXME: Hack f. POD

        my $center = $self->{'center'};
        my $cssPrefix = $self->rootNode->get('cssPrefix');

        # my $style = 'display: block';
        my $style = '';
        if ($center) {
            # $style .= "; margin-left: auto; margin-right: auto";
            $style .= "display: block; margin-left: auto; margin-right: auto";
        }
        if (my $def = $self->{'style'}) {
            $style .= "; $def";
        }

        my $url = $self->{'url'};
        my $html = $h->tag('p',
            class=>"$cssPrefix-fig-p",
            style=>$center? 'text-align: center': undef,
            $h->tag('a',
                -ignoreTagIf=>!$url,
                href=>$url,
                $h->tag('img',
                    -nl=>0,
                    class=>"$cssPrefix-fig-img",
                    style=>$style || undef,
                    src=>$self->{'file'},
                    width=>$self->{'width'},
                    height=>$self->{'height'},
                ),
            ).
            $self->visibleTitle($format,$h)
        );
        if ($format eq 'pod') {
            return qq|=begin html\n\n$html\n=end html\n\n|;
        }
        return $html;
    }
    elsif ($format eq 'man') {
        $self->notImplemented;
    }

    $self->throw(
        q~SDOC-00001: Unbekanntes Format~,
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.135

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
