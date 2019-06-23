package Quiq::Pod::Generator;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Pod::Generator - POD-Generator

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Dokumentation der POD-Syntax: L<http://perldoc.perl.org/perlpod.html>

Ein Objekt der Klasse repräsentiert einen POD-Generator. Mit den
Methoden der Klasse können aus einem Perl-Programm heraus
POD-Dokumente erzeugt werden, wobei man sich um die Syntaxregeln
und die Details der Formatierung nicht zu kümmern braucht.

=head1 ATTRIBUTES

=over 4

=item indentation => $n (Default: 4)

Einrücktiefe bei Code-Abschnitten und Listen.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere POD-Generator

=head4 Synopsis

    $pg = $class->new(@keyVal);

=head4 Description

Instantiiere einen POD-Generator und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Example

Generiere POD mit Einrückung 2:

    $pg = Quiq::Pod::Generator->new(
        indentation => 2,
    );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        indentation => 4,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Abschnitts-Kommandos

Alle Abschnitts-Methoden ergänzen den generierten POD-Code um eine
Leerzeile am Ende, so dass das nächste Konstrukt direkt angefügt
werden kann. Diese Leezeile ist in den Beispielen nicht
wiedergegeben.

=head3 encoding() - Deklaration des Encodings

=head4 Synopsis

    $pod = $pg->encoding($encoding);

=head4 Description

Erzeuge eine Deklaration des Encodings $encoding und liefere
den resultierenden POD-Code zurück.

=head4 Example

    $pg->encoding('utf-8');

erzeugt

    =encoding utf-8

=cut

# -----------------------------------------------------------------------------

sub encoding {
    my ($self,$encoding) = @_;
    return "=encoding $encoding\n\n";
}

# -----------------------------------------------------------------------------

=head3 section() - Abschnitt

=head4 Synopsis

    $pod = $pg->section($level,$title);
    $pod = $pg->section($level,$title,$body);

=head4 Description

Erzeuge einen Abschnitt der Tiefe $level mit dem Titel $title und
dem Abschnitts-Körper $body und liefere den resultierenden
POD-Code zurück. Ist $body nicht angegeben oder ein Leerstring,
wird nur der Titel erzeugt. Andernfalls wird $body per trim()
von einer Einrückung befreit.

=head4 Examples

=over 2

=item *

ohne Body

    $pg->section(1,'Test');

erzeugt

    =head1 Test

=item *

mit Body

    $pg->section(1,'Test',"Dies ist\nein Test.");

erzeugt

    =head1 Test
    
    Dies ist
    ein Test.

=item *

eine Einrückung wird automatisch entfernt

    $pg->section(1,'DESCRIPTION',q~
        Dies ist
        ein Test.
    ~);

erzeugt

    =head1 Test
    
    Dies ist
    ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub section {
    my ($self,$level,$title,$body) = @_;

    my $pod = "=head$level $title\n\n";
    if (defined $body) {
        $body = Quiq::Unindent->trim($body);
        if ($body ne '') {
            $pod .= "$body\n\n";
        }
    }

    return $pod;
}

# -----------------------------------------------------------------------------

=head3 code() - Code-Abschnitt

=head4 Synopsis

    $pod = $pg->code($text);

=head4 Description

Erzeuge einen Code-Abschnitt mit Text $text und liefere den
resultierenden POD-Code zurück.

=head4 Example

    $pg->code("sub f {\n    return 1;\n}");

erzeugt

    $n Leerzeichen
    ----
        sub f {
            return 1;
        }

Der Code ist um $n Leerzeichen (den Wert des Objekt-Attributs
"indentation") eingerückt.

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$text) = @_;

    $text = Quiq::Unindent->trim($text);

    my $indent = ' ' x $self->indentation;
    $text =~ s/^/$indent/mg;

    return "$text\n\n";
}

# -----------------------------------------------------------------------------

=head3 bulletList() - Punkte-Liste

=head4 Synopsis

    $pod = $pg->bulletList(\@items);

=head4 Description

Erzeuge eine Punkte-Liste mit den Elementen @items und liefere
den resultierenden POD-Code zurück.

=head4 Example

    $pg->bulletList(['Eins','Zwei']);

erzeugt

    =over 4
    
    =item *
    
    Eins
    
    =item *
    
    Zwei
    
    =back

=cut

# -----------------------------------------------------------------------------

sub bulletList {
    my ($self,$itemA) = @_;

    my $indent = $self->indentation;

    my $pod = '';
    for (@$itemA) {
        my $item = $_;
        $item =~ s/^\n+//;
        $item =~ s/\s+$//;
        $pod .= "=item *\n\n$item\n\n";
    }
    if ($pod) {
        $pod = "=over $indent\n\n$pod=back\n\n";
    }

    return $pod;
}

# -----------------------------------------------------------------------------

=head3 orderedList() - Aufzählungs-Liste

=head4 Synopsis

    $pod = $pg->orderedList(\@items);

=head4 Description

Erzeuge eine Aufzählungs-Liste mit den Elementen @items und liefere
den resultierenden POD-Code zurück.

=head4 Example

    $pg->orderedList(['Eins','Zwei']);

erzeugt

    =over 4
    
    =item 1.
    
    Eins
    
    =item 2.
    
    Zwei
    
    =back

=cut

# -----------------------------------------------------------------------------

sub orderedList {
    my ($self,$itemA) = @_;

    my $indent = $self->indentation;

    my $pod = '';
    my $i = 1;
    for (@$itemA) {
        my $item = $_;
        $item =~ s/^\n+//;
        $item =~ s/\s+$//;
        $pod .= sprintf "=item %d.\n\n$item\n\n",$i++;
    }
    if ($pod) {
        $pod = "=over $indent\n\n$pod=back\n\n";
    }

    return $pod;
}

# -----------------------------------------------------------------------------

=head3 definitionList() - Definitions-Liste

=head4 Synopsis

    $pod = $pg->definitionList(\@items);

=head4 Description

Erzeuge eine Definitions-Liste mit den Elementen @items und liefere
den resultierenden POD-Code zurück.

=head4 Example

Die Aufrufe

    $pg->definitionList([A=>'Eins',B=>'Zwei']);

oder

    $pg->definitionList([['A','Eins'],['B','Zwei']]);

erzeugen

    =over 4
    
    =item A
    
    Eins
    
    =item B
    
    Zwei
    
    =back

=cut

# -----------------------------------------------------------------------------

sub definitionList {
    my ($self,$itemA) = @_;

    my $step = 2;
    if (ref $itemA->[0]) {
        $step = 1; # zweielementige Listen
    }

    my $pod = '';
    for (my $i = 0; $i < @$itemA; $i += $step) {
        my ($key,$val) = $step == 1? @{$itemA->[$i]}: @$itemA[$i,$i+1];
        $val =~ s/^\n+//;
        $val =~ s/\s+$//;
        $pod .= "=item $key\n\n$val\n\n";
    }
    if ($pod) {
        my $indent = $self->indentation;
        $pod = "=over $indent\n\n$pod=back\n\n";
    }

    return $pod;
}

# -----------------------------------------------------------------------------

=head3 for() - Formatierer-Code

=head4 Synopsis

    $pod = $pg->for($format,$code);

=head4 Description

Definiere Code $code für Formatierer des Formats $format und
liefere das Resultat zurück. Ist $code einzeilig, wird eine
for-Instruktion erzeugt, ansonsten eine begin/end-Instruktion.

=head4 Examples

=over 2

=item *

einzeiliger Code

    $pg->for('html','<img src="figure1.png" />');

erzeugt

    =for html <img src="figure1.png" />

=item *

mehrzeiliger Code

    $pg->for('html',qq|Ein Bild:\n<img src="figure1.png" />|);

erzeugt

    =begin html
    
    Ein Bild:
    <img src="figure1.png" />
    
    =end html

=back

=cut

# -----------------------------------------------------------------------------

sub for {
    my ($self,$format,$code) = @_;

    $code =~ s/\s+$//;

    my $pod;
    if ($code =~ tr/\n//) {
        $pod = "=begin $format\n\n$code\n\n=end $format\n\n";
    }
    else {
        $pod = "=for $format $code\n\n";
    }
        
    return $pod;
}

# -----------------------------------------------------------------------------

=head3 pod() - Beginne POD-Block

=head4 Synopsis

    $pod = $pg->pod;

=head4 Description

Beginne einen POD-Block. Diese Instruktion ist nur nötig, wenn der
Block mit einem einfachen Text beginnt, denn I<jede> andere
POD-Instruktion beginnt ebenfalls einen POD-Block.

=head4 Example

    $pg->pod;

erzeugt

    =pod

=cut

# -----------------------------------------------------------------------------

sub pod {
    my $self = shift;
    return "=pod\n\n";
}

# -----------------------------------------------------------------------------

=head3 cut() - Beende POD-Block

=head4 Synopsis

    $pod = $pg->cut;

=head4 Description

Beende einen POD-Block. Diese Instruktion ist nicht nötig, wenn
danach kein Perl-Code folgt.

=head4 Example

    $pg->cut;

erzeugt

    =cut

=cut

# -----------------------------------------------------------------------------

sub cut {
    my ($self,$encoding) = @_;
    return "=cut\n\n";
}

# -----------------------------------------------------------------------------

=head2 Format-Codes

=head3 fmt() - Format-Code

=head4 Synopsis

    $str = $this->fmt($type,$text);

=head4 Description

Erzeuge Inline-Segment vom Typ $type (B, I, C usw.)
und liefere den resultierenden POD-Code dieses zurück.

Die Methode sorgt dafür, dass das Segment korrekt generiert wird,
wenn in $text die Zeichen '<' oder '>' vorkommen.

=head4 Examples

Nomal:

    $pg->fmt('C','$x');
    =>
    C<$x>

1x > eingebettet:

    $pg->fmt('C','$class->new()');
    =>
    C<< $class->new() >>

2x > eingebettet:

    $pg->fmt('C','$x >> $y');
    =>
    C<<< $x >> $y >>>

=cut

# -----------------------------------------------------------------------------

sub fmt {
    my ($this,$type,$text) = @_;

    my $maxL = 0;
    while ($text =~ /(>+|<+)/g) {
        my $l = length($1);
        if ($l > $maxL) {
            $maxL = $l;
        }
    }
    if ($maxL or $text =~ /^</ or $text =~ />$/) {
        $text = " $text ";
    }
    $maxL++;

    return sprintf '%s%s%s%s',$type,'<'x$maxL,$text,'>'x$maxL;
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
