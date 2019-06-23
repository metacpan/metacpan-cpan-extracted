package Quiq::Template;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use Quiq::Path;
use Quiq::Option;
use Scalar::Util ();
use Quiq::Reference;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Template - Klasse für HTML/XML/Text-Generierung

=head1 BASE CLASS

L<Quiq::Hash>

=head1 EXAMPLE

Template-Datei C<test.html> oder Template-String C<$str>:

    <html>
    <head>
      <title>__TITLE__</title>
    </head>
    <body>
      __BODY__
    </body>

Code:

    $tpl = Quiq::Template->new('html','test.html');
    -oder-
    $tpl = Quiq::Template->new('html',\$str);
    
    $tpl->replace(
        __TITLE__ => 'Testseite',
        __BODY__ => 'Hello World!',
    );
    $str = $tpl->asString;

Resultat C<$str>:

    <html>
    <head>
      <title>Testseite</title>
    </head>
    <body>
      Hello World!
    </body>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Template-Objekt

=head4 Synopsis

    $tpl = Quiq::Template->new($type,$file,@opt);
    $tpl = Quiq::Template->new($type,\$str,@opt);

=head4 Options

=over 4

=item --lineContinuation => $type (Default: undef)

Art der Zeilenfortsetzung. Mögliche Werte:

=over 4

=item undef

Keine Zeilenfortsetzung.

=item 'backslash'

Endet eine Zeile mit einem Backslash, entferne Whitespace am
Anfang der Folgezeile und füge den Rest zur Zeile hinzu.

Dies kann für eine Zeile unterdrückt werden, indem der Backslash am
Ende der Zeile durch einen davorgestellten Backslash maskiert wird.
In dem Fall wird statt einer Fortsetzung der Zeile der maskierende
Backslash entfernt.

Diese Option ist nützlich, wenn ein Template-Text im Editor auf
eine bestimmte Breite (z.B. 80 Zeichen/Zeile) begrenzt sein soll,
aber der generierte Text breiter sein darf.

=back

=item -singleReplace => $bool (Default: 0)

Ersetze bei replace() immer nur den ersten von mehreren identischen
Platzhaltern. Dies ist z.B. in HTML bei Ersetzung von mehreren
Checkboxen mit gleichem Namen nützlich.

=back

=head4 Description

Instantiiere ein Template vom Typ $type aus Datei $file oder String $str
und liefere eine Referenz auf dieses Objekt zurück.

Template-Typen:

=over 4

=item 'xml'

XML-Template. Metazeichen &, < und > in Werten werden durch
Entities ersetzt.

=item 'html'

HTML-Template. Metazeichen &, < und > in Werten werden durch
Entities ersetzt.

=item 'text'

Text-Template. Werte werden unverändert eingesetzt.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $type = shift;
    my $arg = shift;
    # @_: @opt

    # Optionen

    my $lineContinuation = undef;
    my $singleReplace = 0;

    Quiq::Option->extract(\@_,
        -lineContinuation => \$lineContinuation,
        -singleReplace => \$singleReplace,
    );

    # Operation ausführen

    my $str = ref $arg? $$arg: Quiq::Path->read($arg);
    $str =~ s/\s+$//; # WS am Ende entfernen

    if ($lineContinuation) {
        if ($lineContinuation eq 'backslash') {
            $str =~ s/(?<!\\)\\\n[ \t]*//g;
        }
        else {
            $class->throw(
                'TEMPLATE-00001: Ungüliger Wert für Option -lineContinuation',
                Value => $lineContinuation,
            );
        }
    }

    my $self = $class->SUPER::new(
        type => $type,
        string => $str,
        protect => 1,
        singleReplace => $singleReplace,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 placeholders() - Liefere Liste der Platzhalter

=head4 Synopsis

    @arr | $arr = $tpl->placeholders;

=cut

# -----------------------------------------------------------------------------

sub placeholders {
    my $self = shift;
    my @arr = $self->{'string'} =~ /(__\w+?__)/g;
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 replace() - Ersetze Platzhalter

=head4 Synopsis

    $tpl = $tpl->replace(@keyVal);

=head4 Returns

Referenz auf das Template-Objekt (für Method-Chaining)

=head4 Description

Ersetze alle Platzhalter durch ihre Werte. Platzhalter und
Werte werden als Paare @keyVal übergeben.

Der Wert kann ein String, eine Arrayrefernz, eine Codereferenz oder
ein Template-Objekt sein. Siehe Methode L<value|"value() - Liefere Platzhalter-Wert als Zeichenkette">().

Es wird für jeden Platzhalter mit einem Wert ungleich C<undef> geprüft,
ob dieser im Template vorkommt. Wenn nicht, wird eine Exception geworfen.

=head4 Example

Subroutine liefert Platzhalter-Wert:

    my $tpl = Quiq::Template->new('xml',\$Order);
    $tpl->replace(
        __CUSTNR__ => $kundenNr,
        __LIEFERNAME__ => $vor->{'liefername'},
        __LIEFERSTRASSE__ => $lieferstrasse,
        __LIEFERHAUSNR__ => $lieferhausnr,
        __LIEFERPLZ__ => $vor->{'lieferplz'},
        __LIEFERORT__ => $vor->{'lieferort'},
        __LIEFERLAND_ISO__ => $vor->{'lieferland_iso'},
        __BESTELLDATUM__ => POSIX::strftime('%Y-%m',localtime),
        __BESTELLNUMMER__ => $vor->{'vorgang_bestellnummer'},
        __WAEHRUNG__ => $waehrung,
        __ENVIRONMENT__ => $test? 'T': 'L',
        __ORDERLINES__ => sub {
            my @arr;
            my $i = 0;
            for my $pos (@$posA) {
                my $tpl = Quiq::Template->new('xml',\$OrderLine);
                $tpl->replace(
                    __I__ => $i++,
                    __LIEFERNR__ => $pos->{'posten_liefernr'},
                    __ARTBE__ => $pos->{'posten_artbe'},
                    __ANZAHL__ => $pos->{'posten_anzahl'},
                    __EPREIS__ => $pos->{'posten_epreis'},
                );
                push @arr,$tpl;
            }
            return \@arr;
        },
    );

Die Subroutine, die den Wert des Platzhalters __ORDERLINES__ berechnet,
liefert keinen String, sondern eine Referenz auf ein Array von
Template-Objekten. Wie jeder Platzhalterwert wird dieser von der
Methode $tpl->L<value|"value() - Liefere Platzhalter-Wert als Zeichenkette">() in einen String (oder C<undef>) umgesetzt.

=cut

# -----------------------------------------------------------------------------

sub replace {
    my $self = shift;
    # @_: @keyVal

    my $sloppy = 0;
    my $singleReplace = $self->{'singleReplace'};

    while (@_) {
        my $key = $self->key(shift);
        my $val = $self->value(shift); # MEMO: $val ist undef oder ein String

        if (!defined $val) {
            # Wenn undef, keine Ersetzung. Die Existenz
            # des Platzhalters wird nicht geprüft.
            next;
        }
        
        # wir entfernen Newlines am Ende (evtl. Option hierfür einführen)
        $val =~ s/\n+$//;
        
        my $exists = 0; # Zeigt an, ob Platzhalter im Template vorkommt

        if ($val =~ tr/\n//) {
            # Ist der Wert mehrzeilig, gehen wir jede einzelne Fundstelle
            # durch und rücken jede Zeile des Werts so weit ein wie der
            # Platzhalter eingerückt ist.

            while (1) {
                if ($self->{'string'} !~ /(^[ \t]*)?\Q$key/m) {
                    # Ende: Key kommt nicht mehr vor
                    last;
                }
                $exists++;

                # Wert einrücken

                my $indVal = $val;
                if ($1) {
                    my $ind = $1;
                    $indVal =~ s/^/$ind/mg;
                    $indVal =~ s/^$ind//; # Einrückung erste Zeile entfernen
                }

                # Platzhalter durch eingerückten Wert ersetzen

                $self->{'string'} =~ s/\Q$key/$indVal/;

                if ($singleReplace) {
                    # wir führen nur eine Ersetzung durch
                    last;
                }
            }
        }
        else {
            # Wert ist einzeilig. Wir ersetzen den Platzhalter global,
            # egal wo er steht.

            if ($val eq '') {
                # Steht der Platzhalter allein auf einer Zeile mit
                # Leerzeilen davor und dahinter, entfernen wir zusätzlich
                # zum Platzghalter alle folgenden Leerzeilen

                if ($singleReplace) {
                    # wir führen nur eine Ersetzung durch
                    $exists += $self->{'string'} =~
                        s/(\n{2,})\Q$key\E\n{2,}/$1/m;
                }
                else {
                    $exists += $self->{'string'} =~
                        s/(\n{2,})\Q$key\E\n{2,}/$1/mg;
                }
            }

            if ($singleReplace) {
                # wir führen nur eine Ersetzung durch
                $exists += $self->{'string'} =~ s/\Q$key/$val/;
            }
            else {
                $exists += $self->{'string'} =~ s/\Q$key/$val/g;
            }
        }

        # Exception, wenn Platzhalter (mit gesetztem Wert) nicht existiert

        if (!$exists && !$sloppy) {
            #my $str = $self->{'string'};
 
            #if ($self->{'type'} eq 'html') {
            #    $str =~ s/&/&amp;/g;
            #    $str =~ s/</&lt;/g;
            #    $str =~ s/>/&gt;/g;
            #}
 
            $self->throw(
                'TMPL-00001: Platzhalter existiert nicht',
                # Template => $str,
                Placeholder => $key,
            );
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 key() - Liefere Schlüssel und Ersetzungsattribut(e)

=head4 Synopsis

    $key = $tpl->key($arg);
    ($key,@attr) = $tpl->key($arg);

=head4 Description

Als Schlüssel $arg kann

=over 4

=item 1.

ein String,

=item 2.

eine Stringreferenz

=item 3.

eine Arrayreferenz

=back

angegeben sein.

MEMO: Die Methode ist so gestaltet, dass (weitere) Einsetzungsattribute
definiert werden können, wenn als Platzhalter eine Arrayreferenz
übergeben wird, z.B.

    ['__ITEMS__',call=>sub {...}]

Die Ersetzungsattribute werden im Arraykontext neben dem Schlüssel
zurückgegeben und können in replace() den Ersetzungsvorgang in
spezieller Weise steuern. Dies wird aber noch nicht genutzt.

=cut

# -----------------------------------------------------------------------------

sub key {
    my ($self,$arg) = @_;

    if (ref $arg) {
        if (Quiq::Reference->isArrayRef($arg)) {
            return $arg->[0];
        }
        else {
            return $$arg;
        }
    }

    return $arg;
}

# -----------------------------------------------------------------------------

=head3 value() - Liefere Platzhalter-Wert als Zeichenkette

=head4 Synopsis

    $str = $tpl->value($arg);

=head4 Description

Die Methode liefert die Zeichenkette $str zum (bei L<replace|"replace() - Ersetze Platzhalter">()
angegebenen) Platzhalter-Wert $arg.

=over 4

=item String:

Liefere String.

=item Arrayreferenz:

Ermittele die Zeichenketten-Werte aller Array-Elemente,
konkateniere diese mit "\n" und liefere das Resultat zurück.

=item Corereferenz:

Rufe Subroutine auf und liefere den Zeichenketten-Wert des
Returnwerts.

=item Template-Objekt:

Rufe Methode L<asString|"asString() - Liefere Inhalt">() des Objekts auf und liefere
das Resultat zurück.

=back

=cut

# -----------------------------------------------------------------------------

sub value {
    my ($self,$arg) = @_;

    if (!ref $arg) {
        # Zeichenkette -> liefern

        if ($self->{'protect'}) {
            my $type = $self->{'type'};

            if (defined($arg) && ($type eq 'xml' || $type eq 'html')) {
                # Metazeichen schützen
                $arg =~ s/&/&amp;/g;
                $arg =~ s/</&lt;/g;
                $arg =~ s/>/&gt;/g;
            }
        }

        return $arg;
    }
    elsif (Scalar::Util::blessed($arg) && $arg->isa('Quiq::Template')) {
        # Referenz auf Template-Objekt -> asString() aufrufen
        return $arg->asString;
    }
    elsif (Quiq::Reference->isArrayRef($arg)) {
        # Array-Referenz -> Werte mit "\n" konkatenieren
        return join "\n",map {$self->value($_)} @$arg;
    }
    elsif (Quiq::Reference->isCodeRef($arg)) {
        # Subroutine-Referenz -> Wert berechnen
        return $self->value($arg->());
    }
    else {
        # Stringreferenz: Wir liefern den Wert unverändert
        return $$arg
    }

    $self->throw;
}

# -----------------------------------------------------------------------------

=head3 removeOptional() - Entferne Optional-Metatags

=head4 Synopsis

    $tpl->removeOptional;

=head4 Description

Entferne die <optional>-Metatags aus dem Template-Text.
Ein <optional>-Metatag hat die Struktur

    <!--optional-->...<!--/optional-->

oder

    <!--optional-->
    ...
    <!--/optional-->

<optional>-Konstrukte können geschachtelt sein. Sie werden von innen
nach außen aufgelöst.

B<Attribute>

=over 4

=item default="VALUE"

Enthält der Inhalt einen unersetzten Platzhalter, ersetze den
Inhalt durch VALUE.

=item placeholder="NAME"

Entferne den Inhalt nur dann, wenn der Platzhalter __NAME__ unersetzt
ist. Andere unersetzte Platzhalter werden nicht beachtet.

=back

=cut

# -----------------------------------------------------------------------------

sub removeOptional { # Perl 5.8.8
    my $self = shift;

    my $str = $self->{'string'}; # Kopie, auf der wir ersetzen

    my $skipped = 0; # Anzahl der wegen Einbettung übergangener Tags
    # Wir kopieren den Wert, da sonst Totschleife unter 5.8.8
    my $tmp = $self->{'string'};
    while ($tmp =~ m|<!--optional(.*?)-->(.*?)<!--/optional-->|sg) {
        my $pre = $`;
        my $tag = $&;
        my $post = $';
        my $attr = $1;
        my $content = $2;

        # Schachtelung prüfen

        if ($content =~ m|<!--optional(.*?)-->|) {
            # Schachtelung: Content enthält weiteren Optional-Tag,
            # wir übergehen das Konstrukt.

            $tmp =~ s|<!--optional|<!--OpTiOnAl|;
            $skipped++;
            next;
        }

        # Attribute ermitteln

        my $placeholder = '';
        if ($attr =~ /placeholder="(.*?)"/) {
            # Platzhalter angegeben. Ohne __ am Anfang und am Ende!
            # Also: placeholder="TEST" statt placeholder="__TEST__"
            # Der Inhalt wird nur entfernt, wenn dieser Platzhalter
            # enthalten ist.

            $placeholder = $1;
        }

        my $default = '';
        if ($attr =~ /default="(.*?)"/) {
            # Defaultwert angegeben
            $default = $1;
        }

        # Unerfüllter Platzhalter im Content enthalten?

        my $remove = 0;
        if ($placeholder) {
            # Platzhalter ist vorgegeben
            $remove = 1 if $content =~ /__${placeholder}__/;
        }
        else {
            # beliebiger Platzhalter
            $remove = 1 if $content =~ /__\w+?__/;
        }

        # Optional-Tag ersetzen

        if ($remove) {
            if ($default eq '') {
                # echtes Entfernen

                my ($indent) = $pre =~ /\n([ \t]*)$/;
                my ($trail) = $post =~ /^([ \t]*\n)/;

                if ($indent && $trail) {
                    $str =~ s|\Q$indent$tag$trail||;
                }
                else {
                    $str =~ s|\Q$tag||;
                }
            }
            else {
                # durch Defaultwert ersetzen
                $str =~ s|\Q$tag|$default|;
            }
        }
        else {
            # Durch Content ersetzen.
            
            if ($content =~ tr/\n//) {
                # Bei einem mehrzeiligen Content (der durch optional-Tags auf
                # eigenen Zeilen eingefasst sein sollte), beginnt und endet
                # dieser mit Whitespace, den wir hier entfernen.

                $content =~ s/^\s+//g;
                $content =~ s/\s+$//g;
            }

            $str =~ s|\Q$tag|$content|;
        }
    }

    $self->{'string'} = $str;

    if ($skipped) {
        # Es gab Konstrukte, die wir übergangen haben -> rekursiver Aufruf

        $self->{'string'} =~ s|<!--OpTiOnAl|<!--optional|g;
        $self->removeOptional;
    }

    return;
}

sub removeOptional_5_10 { # moderne Version für Perl 5.10 und höher. while ersetzen!
    my $self = shift;

    my $str = $self->{'string'}; # Kopie, auf der wir ersetzen

    my $skipped = 0; # Anzahl der wegen Einbettung übergangener Tags
#    while ($self->{'string'} =~
#            m|<!--optional(.*?)-->(.*?)<!--/optional-->|sgp) {
     while (1) { # durch obiges while ersetzen, wenn Perl 5.10 oder höher
        my $pre = ${^PREMATCH};
        my $tag = ${^MATCH};
        my $post = ${^POSTMATCH};
        my $attr = $1;
        my $content = $2;

        # Schachtelung prüfen

        if ($content =~ m|<!--optional(.*?)-->|) {
            # Schachtelung: Content enthält weiteren Optional-Tag,
            # wir übergehen das Konstrukt.

            $self->{'string'} =~ s|<!--optional|<!--OpTiOnAl|;
            $skipped++;
            next;
        }

        # Attribute ermitteln

        my $placeholder = '';
        if ($attr =~ /placeholder="(.*?)"/) {
            # Platzhalter angegeben. Ohne __ am Anfang und am Ende!
            # Also: placeholder="TEST" statt placeholder="__TEST__"
            # Der Inhalt wird nur entfernt, wenn dieser Platzhalter
            # enthalten ist.

            $placeholder = $1;
        }

        my $default = '';
        if ($attr =~ /default="(.*?)"/) {
            # Defaultwert angegeben
            $default = $1;
        }

        # Unerfüllter Platzhalter im Content enthalten?

        my $remove = 0;
        if ($placeholder) {
            # Platzhalter ist vorgegeben
            $remove = 1 if $content =~ /__${placeholder}__/;
        }
        else {
            # beliebiger Platzhalter
            $remove = 1 if $content =~ /__\w+?__/;
        }

        # Optional-Tag ersetzen

        if ($remove) {
            if ($default eq '') {
                # echtes Entfernen

                my ($indent) = $pre =~ /\n([ \t]*)$/;
                my ($trail) = $post =~ /^([ \t]*\n)/;

                if ($indent && $trail) {
                    $str =~ s|\Q$indent$tag$trail||;
                }
                else {
                    $str =~ s|\Q$tag||;
                }
            }
            else {
                # durch Defaultwert ersetzen
                $str =~ s|\Q$tag|$default|;
            }
        }
        else {
            # durch Content ersetzen
            
            if ($content =~ tr/\n//) {
                # Bei einem mehrzeiligen Content (der durch optional-Tags auf
                # eigenen Zeilen eingefasst sein sollte), beginnt und endet
                # dieser mit Whitespace, den wir hier entfernen.

                $content =~ s/^\s+//g;
                $content =~ s/\s+$//g;
            }

            $str =~ s|\Q$tag|$content|;
        }
    }

    $self->{'string'} = $str;

    if ($skipped) {
        # Es gab Konstrukte, die wir übergangen haben -> rekursiver Aufruf

        $self->{'string'} =~ s|<!--OpTiOnAl|<!--optional|g;
        $self->removeOptional;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 asString() - Liefere Inhalt

=head4 Synopsis

    $str = $tpl->asString;

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;
    return $self->{'string'};
}

# -----------------------------------------------------------------------------

=head3 asStringNL() - Liefere Inhalt mit Newline am Ende

=head4 Synopsis

    $str = $tpl->asStringNL;

=cut

# -----------------------------------------------------------------------------

sub asStringNL {
    my $self = shift;
    return $self->{'string'} eq ''? '': "$self->{'string'}\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
