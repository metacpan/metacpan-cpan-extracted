package Prty::Css;

use strict;
use warnings;

our $VERSION = 1.124;

use Prty::Html::Tag;
use Prty::Path;
use Prty::String;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Css - Generierung von CSS Code

=head1 METHODS

=head2 Klassenmethoden

=head3 rule() - Generiere CSS Style Rule

=head4 Synopsis

    $rule = Prty::Css->rule($selector,@propVal);

=head4 Description

Generiere eine CSS Style Rule, bestehend aus Selector $selector
und den Property/Value-Paaren @propVal und liefere
diese als Zeichenkette zurück.

=head4 Example

Erzeuge eine einfache Style Rule:

    $rule = Prty::Css->rule('p.abstract',
        fontStyle=>'italic',
        marginLeft=>'0.5cm',
        marginRight=>'0.5cm',
    );

liefert

    p.abstract {
        font-style: italic;
        margin-left: 0.5cm;
        margin-right: 0.5cm;
    }

=cut

# -----------------------------------------------------------------------------

sub rule {
    my $class = shift;
    my $selector = shift;
    # @_: @propVal

    my $str = "$selector {\n";
    while (@_) {
        my $prop = shift; 
        my $val = shift;

        $prop =~ s/([a-z])([A-Z])/$1-\L$2/g;

        if (defined $val && $val ne '') {
            $str .= "    $prop: $val;\n";
        }
    }
    $str .= "}\n";

    return $str;
}

# -----------------------------------------------------------------------------

=head3 style() - Generiere StyleSheet-Tags

=head4 Synopsis

    $styleTags = Prty::Css->style($h,@specs);

=head4 Arguments

=over 4

=item @specs

Liste von Style-Spezifikationen.

=back

=head4 Description

Übersetze die Style-Spezifikationen @specs in eine Folge von
<link>- und/oder <style>-Tags.

Mögliche Style-Spezifikationen:

=over 4

=item "inline:$file":

Datei $file wird geladen und ihr Inhalt wird hinzugefügt.

=item $string (Zeichenkette mit enthaltenen '{')

Zeichenkette $string wird hinzugefügt.

=item $url (Zeichenkette ohne '{'):

Zeichenkette wird als URL interpretiert und ein <link>-Tag

    <link rel="stylesheet" type="text/css" href="$url" />

hinzugefügt.

=item \@specs (Arrayreferenz):

Wird zu @specs expandiert.

=back

=head4 Example

B<Code zum Laden eines externen Stylesheet:>

    $style = Prty::Css->style('/css/stylesheet.css');
    =>
    <link rel="stylesheet" type="text/css" href="/css/stylesheet.css" />

B<Stylesheet aus Datei einfügen:>

    $style = Prty::Css->style('inline:/css/stylesheet.css');
    =>
    <Inhalt der Datei /css/stylesheet.css>

B<Mehrere Stylesheet-Spezifikationen:>

    $style = Prty::Css->style(
        '/css/stylesheet1.css'
        '/css/stylesheet2.css'
    );
    =>
    <link rel="stylesheet" type="text/css" href="/css/stylesheet1.css" />
    <link rel="stylesheet" type="text/css" href="/css/stylesheet2.css" />

B<Mehrere Stylesheet-Spezifikationen via Arrayreferenz:>

    $style = Prty::Css->style(
        ['/css/stylesheet1.css','/css/stylesheet2.css']
    );

Dies ist nützlich, wenn die Spezifikation von einem Parameter
einer umgebenden Methode kommt.

=cut

# -----------------------------------------------------------------------------

sub style {
    my $class = shift;
    my $h = shift;
    # @_: @spec

    my $linkTags = '';
    my $style = '';

    while (@_) {
        my $spec = shift;

        if (ref $spec) {
            unshift @_,@$spec;
            next;
        }
        elsif (!defined $spec || $spec eq '') {
            next;
        }
        elsif ($spec =~ s/^inline://) {
            my $data = Prty::Path->read($spec);
            # FIXME: Optional Kommentare entfernen

            # Leerzeilen entfernen
            $data =~ s|\n\s*\n+|\n|g;

            # /* eof */ und Leerzeichen am Ende entfernen

            $data =~ s|\s+$||;
            $data =~ s|\s*/\* eof \*/$||;

            $style .= "$data\n";
        }
        elsif ($spec =~ /\{/) {
            # Stylesheet-Definitionen, wenn { enthalten
            Prty::String->removeIndentation(\$spec);
            $style .= "$spec\n";
        }
        else {
            $linkTags .= $h->tag('link',
                rel=>'stylesheet',
                type=>'text/css',
                href=>$spec,
            );
        }
    }
    
    return $h->cat(
        $linkTags,
        $h->tag('style',
            -ignoreIfNull=>1,
            $style
        ),
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.124

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
