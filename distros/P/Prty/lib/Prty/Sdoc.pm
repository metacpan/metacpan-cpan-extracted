package Prty::Sdoc;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.119;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Sdoc - Sdoc-Generator

=head1 BASE CLASS

L<Prty::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Sdoc-Generator. Die
Methoden der Klasse erzeugen die Konstrukte, aus denen ein
Sdoc-Dokument aufgebaut ist.

=head1 ATTRIBUTES

=over 4

=item indentation => $n (Default: 4)

Einrücktiefe bei der Codegenerierung

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $gen = $class->new(@keyVal);

=head4 Description

Instantiiere einen Sdoc-Generator mit den Eigenschaften @keyVal
(s. Abschnitt L</Attributes>) und liefere eine Referenz auf dieses
Objekt zurück.

=head4 Example

Generiere Sdoc mit Einrückung 2:

    $gen = Prty::Sdoc->new(
        indentation=>2,
    );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        indentation=>4,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 comment() - Kommentar

=head4 Synopsis

    $str = $gen->comment($text);

=head4 Description

Erzeuge einen Kommentar mit dem Text $text und liefere den
resultierenden Sdoc-Code zurück.

=head4 Example

    $gen->comment("Dies ist\nein Test\n");

erzeugt

    # Dies ist\n
    # ein Test.\n
    \n

=cut

# -----------------------------------------------------------------------------

sub comment {
    my ($self,$text) = @_;
    $text =~ s/\s+$//;
    $text =~ s/^/# /mg;
    return "$text\n\n";
}

# -----------------------------------------------------------------------------

=head3 document() - Dokument-Definition

=head4 Synopsis

    $str = $gen->document(@keyVal);

=head4 Description

Erzeuge eine Dokument-Definition mit den Eigenschaften @keyVal und
liefere den resultierenden Sdoc-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub document {
    my $self = shift;
    # @_: @keyVal

    my $ind = ' ' x $self->indentation;
    
    my $str = "%Document:\n";
    while (@_) {
        $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
    }
    $str .= "\n";

    return $str;
}

# -----------------------------------------------------------------------------

=head3 tableOfContents() - Inhaltsverzeichnis-Definition

=head4 Synopsis

    $str = $gen->tableOfContents(@keyVal);

=head4 Description

Erzeuge eine Inhaltsverzeichnis-Definition mit den Eigenschaften
@keyVal und liefere den resultierenden Sdoc-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub tableOfContents {
    my $self = shift;
    # @_: @keyVal

    my $ind = ' ' x $self->indentation;
    
    my $str = "%TableOfContents:\n";
    while (@_) {
        $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
    }
    $str .= "\n";

    return $str;
}

# -----------------------------------------------------------------------------

=head3 section() - Abschnitt

=head4 Synopsis

    $str = $gen->section($level,$title,$body);

=head4 Description

Erzeuge einen Abschnitt der Tiefe $level mit dem Titel $title und
dem Abschnitts-Körper $body und liefere den resultierenden
Sdoc-Code zurück.

=head4 Example

    $gen->section(2,'Test',"Dies ist\nein Test.");

erzeugt

    == Test\n
    \n
    Dies ist\n
    ein Test.\n
    \n

=cut

# -----------------------------------------------------------------------------

sub section {
    my ($self,$level,$title,$body) = @_;
    $body =~ s/\s+$//;
    return sprintf "%s %s\n\n%s\n\n",('=' x $level),$title,$body;
}

# -----------------------------------------------------------------------------

=head3 definitionList() - Definitions-Liste

=head4 Synopsis

    $str = $gen->definitionList(\@items);

=head4 Description

Erzeuge eine Definitions-Liste mit den Elementen @items (Array von
Schlüssel/Wert-Paaren oder von zweielementigen Sub-Arrays) und
liefere den resultierenden Sdoc-Code zurück.

=head4 Examples

Die Aufrufe

    $gen->definitionList([A=>'Eins',B=>'Zwei']);

oder

    $gen->definitionList([['A','Eins'],['B','Zwei']]);

erzeugen

    [A]:\n
        Eins\n
    \n
    [B]:\n
        Zwei\n
    \n

Endet der Schlüssel mit einem Doppelpunkt, wie bei den Aufrufen

    $gen->definitionList(['A:'=>'Eins','B:'=>'Zwei']);

oder

    $gen->definitionList([['A:','Eins'],['B:','Zwei']]);

steht der Doppelpunkt I<in> der Klammer

    [A:]\n
        Eins\n
    \n
    [B:]\n
        Zwei\n
    \n

was bedeutet, dass dieser mit gesetzt wird.

=cut

# -----------------------------------------------------------------------------

sub definitionList {
    my ($self,$itemA) = @_;

    my $step = 2;
    if (ref $itemA->[0]) {
        $step = 1; # zweielementige Listen
    }

    my $str = '';
    my $ind = ' ' x $self->indentation;
    for (my $i = 0; $i < @$itemA; $i += $step) {
        my ($key,$val) = $step == 1? @{$itemA->[$i]}: @$itemA[$i,$i+1];
        $val =~ s/^\n+//;
        $val =~ s/\s+$//;
        $val =~ s/^/$ind/mg;
        my $colon = substr($key,-1) eq ':'? '': ':';
        $str .= "[$key]$colon\n$val\n\n";
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 eof() - EOF-Kommentar

=head4 Synopsis

    $str = $gen->eof;

=head4 Description

Erzeuge einen EOF-Kommentar und liefere den resultierenden
Sdoc-Code zurück.

=head4 Example

    $gen->eof;

erzeugt

    # eof\n

=cut

# -----------------------------------------------------------------------------

sub eof {
    my $self = shift;
    return "# eof\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.119

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
