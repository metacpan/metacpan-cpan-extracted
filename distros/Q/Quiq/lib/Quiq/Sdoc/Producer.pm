package Quiq::Sdoc::Producer;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.181';

use Quiq::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Producer - Sdoc-Generator

=head1 BASE CLASS

L<Quiq::Hash>

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
(s. Abschnitt L<Attributes|"ATTRIBUTES">) und liefere eine Referenz auf dieses
Objekt zurück.

=head4 Example

Generiere Sdoc mit Einrückung 2:

  $gen = Quiq::Sdoc::Producer->new(
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

=head3 code() - Code-Abschnitt

=head4 Synopsis

  $str = $gen->code($text);

=head4 Description

Erzeuge einen Code-Abschnitt mit Text $text und liefere den
resultierenden Sdoc-Code zurück.

=head4 Example

  $gen->code("Dies ist\nein Test\n");

erzeugt

  |  Dies ist\n
  |  ein Test.\n
  |\n

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$text) = @_;

    $text = Quiq::Unindent->trim($text);
    if ($text eq '') {
        return $text;
    }

    my $ind = ' ' x $self->indentation;
    $text =~ s/^/$ind/mg;

    return "$text\n\n";
}

# -----------------------------------------------------------------------------

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

=head3 paragraph() - Paragraph

=head4 Synopsis

  $str = $gen->paragraph($text);

=head4 Description

Erzeuge einen Paragraph mit Text $text und liefere den
resultierenden Sdoc-Code zurück.

=head4 Example

  $gen->paragraph("Dies ist\nein Test\n");

erzeugt

  |Dies ist\n
  |ein Test.\n
  |\n

=cut

# -----------------------------------------------------------------------------

sub paragraph {
    my ($self,$text) = @_;

    $text = Quiq::Unindent->trim($text);
    if ($text eq '') {
        return $text;
    }

    return "$text\n\n";
}

# -----------------------------------------------------------------------------

=head3 table() - Tabelle

=head4 Synopsis

  $str = $gen->table($text,@keyVal);

=head4 Description

Erzeuge eine Tabelle mit der ASCII-Darstellung $text mit den Eigenschaften
@keyVal und liefere den resultierenden Sdoc-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub table {
    my $self = shift;
    my $text = Quiq::Unindent->trim(shift);
    # @_: @keyVal

    if (!defined($text) || $text eq '') {
        return $text;
    }

    my $ind = ' ' x $self->indentation;
    
    my $str = "%Table:\n";
    while (@_) {
        $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
    }
    $text =~ s/^/$ind/mg;
    $str .= "$text\n.\n\n";

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

  $str = $gen->section($level,$title);
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
    my ($self,$level,$title) = splice @_,0,3;
    # @_: $body

    my $str;
    if ($level == -1) {
        $str = sprintf "=- %s\n\n",$title;
    }
    elsif ($level == 0) {
        $str = sprintf "==- %s\n\n",$title;
    }
    else {
        $str = sprintf "%s %s\n\n",('=' x $level),$title;
    }
    if (@_) {
        my $body = shift;
        $body =~ s/\s+$//;
        if ($body ne '') {
            $str .= "$body\n\n";
        }
    }

    return $str;
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

1.181

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2020 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
