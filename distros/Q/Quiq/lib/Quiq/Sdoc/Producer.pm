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

=cut

# -----------------------------------------------------------------------------

package Quiq::Sdoc::Producer;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Unindent;
use Quiq::Hash;
use Quiq::Table;

# -----------------------------------------------------------------------------

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
      indentation => 2,
  );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        indentation => 4,
        linkA => [],
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 code() - Code-Abschnitt

=head4 Synopsis

  $str = $gen->code($text,@keyVal);

=head4 Arguments

=over 4

=item $text

Text des Code-Abschnitts.

=item @keyVal

Eigenschaften des Code-Abschnitts.

=back

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
    my ($self,$text) = splice@_,0,2;
    # @_: @keyVal
    
    $text = Quiq::Unindent->trim($text);
    if ($text eq '') {
        return '';
    }

    my $ind = ' ' x $self->indentation;

    if (@_) {
        my $str = "%Code:\n";
        while (@_) {
            $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
        }
        $str .= "$text\n.\n\n";
        return $str;
    }

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

=head3 format() - Format-Abschnitt

=head4 Synopsis

  $str = $gen->format(
      $format => $code,
      ...
  );

=head4 Description

Erzeuge einen Format-Abschnitt für die angegebenen Format/Code-Paare und
liefere den resultierenden Sdoc-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub format {
    my $self = shift;
    # @_: @formatCode

    my $str = "%Format:\n";
    while (@_) {
        my $format = shift;
        my $code = shift;
        if ($code ne '' && substr($code,-1,1) ne "\n") {
            $code .= "\n";
        }
        $str .= sprintf "\@\@%s\@\@\n%s",$format,$code;
    }
    $str .= ".\n\n";

    return $str;
}

# -----------------------------------------------------------------------------

=head3 link() - Link

=head4 Synopsis

  $str = $gen->link($name,
      url => $url,
      ...
  );

=head4 Description

Erzeuge ein Link-Segment. Intern wird die Link-Defínition gespeichert,
die später mit allen anderen Link-Definitionen per $gen->linkDefs()
abgerufen werden kann.

=cut

# -----------------------------------------------------------------------------

sub link {
    my ($self,$name) = splice @_,0,2;
    # @_: @keyVal

    my $linkA = $self->linkA;
    push @$linkA,Quiq::Hash->new({@_},
        name => $name,
        url => undef,
    );

    return "L{$name}";
}

# -----------------------------------------------------------------------------

=head3 linkDefs() - Link-Definitionen

=head4 Synopsis

  $str = $gen->linkDefs;

=head4 Description

Generiere Link-Definitionen zu den Link-Segmenten des Dokuments
und liefere diese zurück. Die Methode wird typischerweise am Ende
des Dokuments gerufen.

=cut

# -----------------------------------------------------------------------------

sub linkDefs {
    my $self = shift;

    my $str = '';
    for my $l (@{$self->linkA}) {
        $str .= qq~%Link:\n  name="$l->{'name'}"\n  url="$l->{'url'}"\n\n~
    }

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

  $str = $gen->table(\@titles,\@rows,@keyVal); # mit Titelzeile
  $str = $gen->table($width,\@rows,@keyVal); # ohne Titelzeile
  $str = $gen->table($text,@keyVal);

=head4 Arguments

=over 4

=item @titles

(Array of Strings) Liste der Kolumnentitel

=item @rows

(Array of Arrays of Strings) Liste der Zeilen

=item $width

(Integer) Anzahl der Kolumnen

=item $text

(String) Tabellen-Body als Text

=item @keyVal

(Pairs of Strings) Liste von Tabellen-Eigenschaften

=back

=head4 Returns

(String) Sdoc-Code

=head4 Description

Erzeuge eine Tabelle mit den Titeln @titles und den Zeilen @rows bzw.
dem Tabellen-Body $text sowie den Eigenschaften @keyVal und liefere den
resultierenden Sdoc-Code zurück.

=head4 Example

  $str = $gen->table(['Integer','String','Float'],[
      [1,  'A',  76.253],
      [12, 'AB', 1.7   ],
      [123,'ABC',9999  ],
  ]);
  ==>
  %Table:
  Integer String    Float
  ------- ------ --------
        1 A        76.253
       12 AB        1.700
      123 ABC    9999.000
  .
  \n

=cut

# -----------------------------------------------------------------------------

sub table {
    my $self = shift;
    # @_: \@titles,\@rows,@keyVal -or- $text,@keyVal

    if (!defined($_[0]) || $_[0] eq '') {
        return '';
    }

    my $body;
    if (ref($_[0]) || $_[0] =~ /^\d+$/) {
        my $arg1 = shift; # $titleA -or- $width
        my $rowsA = shift;

        $body = Quiq::Table->new($arg1,$rowsA)->asAsciiTable;
    }
    else {
        $body = Quiq::Unindent->trimNl(shift);
    }

    my $str = "%Table:\n";
    my $ind = ' ' x $self->indentation;
    while (@_) {
        $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
    }
    $str .= "$body.\n\n";

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

  $str = $gen->section($level,$title,@keyVal);
  $str = $gen->section($level,$title,@keyVal,$body);

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
    # @_: @keyval -or- @keyVal,$body

    my $body;
    if (@_) {
        if (@_%2) { # ungerade Anzahl
            $body = pop;
        }
    }

    my ($str,$withKeyVal);
    if (@_) { # @keyVal
        $withKeyVal = 1;

        my $ind = ' ' x $self->indentation;

        $str = "%Section:\n";
        $str .= sprintf qq|%slevel="%s"\n|,$ind,$level;
        $str .= sprintf qq|%stitle="%s"\n|,$ind,$title;
        while (@_) {
            $str .= sprintf qq|%s%s="%s"\n|,$ind,shift,shift;
        }
        $str .= "\n";
    }
    else {
        if ($level == -1) {
            $str = sprintf "=- %s\n\n",$title;
        }
        elsif ($level == 0) {
            $str = sprintf "==- %s\n\n",$title;
        }
        else {
            $str = sprintf "%s %s\n\n",('=' x $level),$title;
        }
    }

    if (defined $body) {
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

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
