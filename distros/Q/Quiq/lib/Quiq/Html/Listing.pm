package Quiq::Html::Listing;
use base qw/Quiq::Html::Base/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Listing - Programm-Listing in HTML

=head1 BASE CLASS

L<Quiq::Html::Base>

=head1 SYNOPSIS

    use Quiq::Html::Listing;
    
    my $h = Quiq::Html::Tag->new;
    
    my $obj = Quiq::Html::Listing->new(
        language => 'Perl',
        lineNumbers => 1,
        colNumbers => 79,
        source => $file,
    );
    
    my $html = $obj->html($h);

=head1 ATTRIBUTES

=over 4

=item anchor => 'doc'|'method'|undef (Default: 'doc')

Setze Methodenanker an den Anfang der eingebetteten Dokumentation
zur Methode (im Fall von Perl der POD-Dokumentation) oder an
den Anfang der Methode selbst. Im Falle von C<undef> wird kein
Anker gesetzt.

=item colNumbers => $n (Default: 0)

Setze eine Zeile mit Kolumnennummern. Die Mindest-Zeilenlänge ist $n
(z.B. 79). Bei colNumbers=>0 werden keine Kolumnennummern gesetzt.

=item escape => $bool (Default: 1)

Schütze &, >, < in den Daten durch HTML-Entities. Wenn die Daten
bereits geschützt sind, kann dies mit escape=>0 abgeschaltet werden.
In dem Fall sind die ermittelten Zeilenlängen für Option
colNumbers u.U. zu groß.

=item language => 'Perl' (Default: undef)

Sprache. Aktuell nur 'Perl'.

=item lineNumbers => $n (Default: 1)

Setze die Zeilennummer an den Anfang jeder Zeile, beginnend
mit $n. Bei lineNumbers=>0 wird keine Zeilennummer gesetzt.

=item minLineNumberWidth => $n (Default: 2)

Minimale Breite der Zeilennummern-Spalte in Zeichen. Ungenutzte Stellen
werden mit Leerzeichen aufgefüllt.

=item source => $filename -or- $strRef (Default: undef)

Inhalt. Dieser kann aus einer Datei oder einem String kommen.

=back

=head1 EXAMPLE

Programm:

     1: require R1::HtmlTag;
     2: require R1::Html::Listing;
     3: 
     4: my $h = R1::HtmlTag->new;
     5: 
     6: my $text = << '__PERL__';
     7: #!/usr/bin/perl
     8: 
     9: =encoding utf8
    10: 
    11: Nur ein Demo-Programm.
    12: 
    13: =cut
    14: 
    15: print "Hello world!\n";
    16: 
    17: # eof
    18: __PERL__
    19: 
    20: my $html = R1::Html::Listing->html($h,
    21:     cssPrefix=>'sdoc-code',
    22:     language=>'Perl',
    23:     source=>\$text,
    24: );

Ergebnis:

    1: 

Im Browser:

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $obj = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        anchor => 'doc',
        colNumbers => 0,
        cssPrefix => 'listing',
        escape => 1,
        language => undef,
        lineNumbers => 1,
        minLineNumberWidth => 1,
        source => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $obj->html($h);
    $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($anchor,$colNumbers,$cssPrefix,$escape,$id,$lang,$i,$lnWidth,
        $source) =
        $self->get(qw/anchor colNumbers cssPrefix escape id language
        lineNumbers minLineNumberWidth source/);

    my $noLn;
    if ($i) {
        if (ref $source) {
            my $n = $$source =~ tr/\n//;
            my $l = length $n;
            $lnWidth = $l if $l > $lnWidth;
        }
    }
    else {
        $noLn = 1;
        $i = 1; # für odd/even-Unterscheidung
    }

    # Pattern für Anker-Setzung

    my $anchorPat;
    if ($lang && $anchor) {
        if ($lang eq 'Perl') {
            if ($anchor eq 'doc') {
                $anchorPat = qr/^=head\d\s+(\w+)\(\)/;
            }
            elsif ($anchor eq 'method') {
                $anchorPat = qr/^sub\s+(\w+)/;
            }
            else {
                $self->throw(
                    'LISTING-00002: Unbekannter Anker-Typ',
                    Anchor => $anchor,
                );
            }
        }
    }

    my $html = '';
    my $maxLen = 0;
    my $isDoc = 0; # Dokumentationsabschnitt (bei Perl POD-Abschnitt)

    my $fh = Quiq::FileHandle->new('<',$source);
    for my $line (<$fh>) {
        chomp $line;

        # Ermittele längste Zeile

        if (my $l = length $line) {
            if ($l > $maxLen) {
                $maxLen = $l;
            }
        }

        # Daten schützen

        if ($escape) {
            $line =~ s/&/&amp;/g;
            $line =~ s/</&lt;/g;
            $line =~ s/>/&gt;/g;
        }

        if ($lang && $line ne '') {
            # <span> für Perl- und CoTeDo-Kommentare

            my $commentSub = sub {
                my ($h,$prefix,$str) = @_;
                return $h->tag('span',
                    class => "$prefix-comment",
                    '-',
                    $str
                );
            };

            if ($lang eq 'Perl') {
                my $html;

                if ($line =~ /^=\w/) {
                    $isDoc = 1;
                }

                # Methoden-Anker

                if ($anchorPat && $line =~ /$anchorPat/) {
                    # FIXME: Liste der Links merken um sie gegenüber
                    # Sdoc registrieren zu können. Dann l{} statt U{}.

                    $html = $h->tag('a',
                        name => "perl_method_$1",
                    );
                }

                # Dokumentationszeilen und Kommentare kennzeichnen

                if ($isDoc) {
                    # <span> für Dokumentations-Zeile

                    if ($line =~ /^=over/) {
                        # =over-Zeile hat insgesamt keinen Content
                        $html .= $line;
                    }
                    else {
                        # Aufteilung von POD-Kommando und Content
                        
                        $line =~ s/^(=\w+)//;
                        my $podCmd = $1;
                        if ($podCmd) {
                            $html .= $podCmd;
                        }
                        $html .= $h->tag('span',
                            class => "$cssPrefix-doc",
                            '-',
                            $line
                        );
                        if ($podCmd) {
                            $line = "$podCmd$line";
                        }
                    }
                }
                else {
                    (my $tmp = $line) =~ s/((^|\s)#.*)/
                        $commentSub->($h,$cssPrefix,$1)/e;
                    $html .= $tmp;
                }

                if ($line =~ /^=cut/) {
                    $isDoc = 0;
                }

                $line = $html;
            }
            elsif ($lang eq 'CoTeDo') {
                if ($line =~ /^# (\[|\&lt;|eof)/) { # Entity-Zeile
                    $line = $h->tag('span',
                        class => "$cssPrefix-entity",
                        '-',
                        $line
                    );
                }
                elsif ($line =~ /^\w+:$/) { # keyRegex SectionParser
                    $line = $h->tag('span',
                        class => "$cssPrefix-key",
                        '-',
                        $line
                    );
                }
                else {
                    $line =~ s/((^|\s)\!\!.*)/
                        $commentSub->($h,$cssPrefix,$1)/e;
                }
            }
            else {
                $self->throw(
                    'LISTING-00001: Unbekannte Sprache',
                    Language => $lang,
                );
            }
        }
        if ($line eq '') {
            $line = '&nbsp;';
        }

        $html .= $h->tag('tr',
            class => sprintf("$cssPrefix-tr-%s",$i%2? 'odd': 'even'),
            '-',
            $h->tag('td',
                -ignoreIf => $noLn,
                class => "$cssPrefix-td-ln",
                sprintf('%*d',$lnWidth,$i++)
            ),
            $h->tag('td',
                class => "$cssPrefix-td-line",
                $line
            )
        );
    }
    $fh->close;

    if ($colNumbers) {
        my $str = '1';
        my $max = $maxLen > $colNumbers? $maxLen: $colNumbers;
        my $limit = int($max/10)*10;
        for (my $i = 10; $i <= $limit; $i += 10) {
            $str .= '.' x ($i-length($str)-1);
            $str .= $i;
        }
        my $l = $max-length($str);
        if ($l > 0) {
            $str .= '.' x $l;
        }

        $html = $h->tag('tr','-',
            $h->tag('td',
                class => "$cssPrefix-td-edge",
            ),
            $h->tag('td',
                class => "$cssPrefix-td-cn",
                $str
            )
        ).
        $html;
    }

    $html = $h->tag('table',
        id => $id,
        class => "$cssPrefix-table",
        cellpadding => 0,
        cellspacing => 0,
        $html
    );

    return $html;
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 CSS-Klassen

    PREFIX-table|Das gesamte Konstrukt (Tabelle)
    PREFIX-tr-odd|Ungerade Zeile
    PREFIX-tr-even|Gerade Zeile
    PREFIX-td-ln|Zelle für Zeilennummer
    PREFIX-td-cn|Zelle für Kolumnennummer
    PREFIX-td-edge|Eckzelle Kolumnennummer/Zeilennummer
    PREFIX-td-line|Zelle für Zeileninhalt
    PREFIX-doc|Kennzeichnung Doku (bei Perl POD)
    PREFIX-comment|Kennzeichnung Kommentar

=head1 VERSION

1.148

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
