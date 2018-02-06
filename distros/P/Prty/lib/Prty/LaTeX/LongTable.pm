package Prty::LaTeX::LongTable;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.123;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::LaTeX::LongTable - Erzeuge LaTeX longtable

=head1 BASE CLASS

L<Prty::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX LongTable-Objekt

=head4 Synopsis

    $tab = $class->new(@keyVal);

=head4 Arguments

=over 4

=item alignments => \@alignments (Default: [])

Liste der Kolumnen-Ausrichtungen. Mögliche Werte je Kolumne: 'l',
'r', 'c'.

=item border => $border (Default: 'hHV')

Linien in und um die Tabelle. Der Wert ist eine Zeichenkette, die
sich aus den Zeichen 't', 'h', 'v', 'H', 'V' zusammensetzt.

=item caption => $str

Unterschrift zur Tabelle.

=item language => 'german'|'english'

Die Sprache des LaTeX-Dokuments.

=item makecell => $bool (Default: 0)

Wende C<\thead> (Titel) bzw. C<\makecell> (Daten) an. Diese Option
muss aktiviert werden, wenn mehrzeilige Zellen mehrzeilig
dargestellt werden sollen, denn dies kann LaTeX nicht. Wird die
Option aktiviert muss das Package C<makecell> geladen werden.
Außderdem sollte der Titelfont eingestellt werden, da das Package
eine seltsame Voreinstellung hat. Beispiel:

    \usepackage{makecell}
    \renewcommand{\theadfont}{\sffamily\bfseries\normalsize}

=item rows => \@rows (Default: [])

Liste der Tabellenzeilen.

=item rowCallback => sub {} (Default: I<siehe unten>)

Subroutine, die für jede Zeile in @rows die Zeileninformation
liefert, die in den LaTeX-Code eingesetzt wird. Default:

    sub {
        my ($self,$gen,$row,$n) = @_;
    
        my @row;
        for my $val (@$row) {
            push @row,$gen->protect($val);
        }
    
        return @row;
    }

=item titles => \@titles (Default: [])

Liste der Kolumnentitel.

=item titleCallback => sub {} (Default: I<siehe unten>)

Subroutine, die die Titelinformation liefert, die in den
LaTeX-Code eingesetzt wird. Default:

    sub {
        my ($self,$gen,$title,$n) = @_;
        return $gen->protect($title);
    }

=back

=head4 Returns

LongTable-Objekt

=head4 Description

Instantiiere ein LaTeX LongTable-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyval

    my $self = $class->SUPER::new(
        alignments => [],
        border => 'hHV',
        caption => undef,
        language => 'german',
        makecell => 0,
        rows => [],
        rowCallback => sub {
            my ($self,$gen,$row,$n) = @_;

            my @row;
            for my $val (@$row) {
                push @row,$gen->protect($val);
            }

            return @row;
        },
        titles => [],
        titleCallback => sub {
            my ($self,$gen,$title,$n) = @_;
            return $gen->protect($title);
        },
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $tab->latex($gen);
    $code = $class->latex($gen,@keyVal);

=head4 Description

Generiere den LaTeX-Code des Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub latex {
    my $this = shift;
    my $gen = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($alignA,$border,$caption,$language,$makecell,$rowA,$rowCb,$titleA,
        $titleCb) = $self->get(qw/alignments border caption language
        makecell rows rowCallback titles titleCallback/);

    if (!@$titleA && !@$rowA) {
        return '';
    }

    my $code;

    # Anzahl Kolumnen
    my $width = @$alignA;

    # Linien
    
    my $tBorder = $border =~ tr/th//? 1: 0;
    my $hBorder = $border =~ tr/h//? 1: 0;
    my $HBorder = $border =~ tr/H//? 1: 0;
    my $vBorder = $border =~ tr/v//? 1: 0;
    my $VBorder = $border =~ tr/V//? 1: 0;

    # Head

    my $titleLine = '';
    if (@$titleA) {
        my @arr;
        for (my $i = 0; $i < @$titleA; $i++) {
             my $val = $titleCb->($self,$gen,$titleA->[$i],$i);
             if ($makecell) {
                 $val =~ s|\n|\\\\|g;
                 $val = sprintf '\thead[%sb]{%s}',$alignA->[$i],$val;
             }
             push @arr,$val;
        }
        $titleLine .= join(' & ',@arr).' \\\\';
        $titleLine .= $tBorder? ' \hline': '';
        $titleLine .= "\n";
    }
    
    # \firsthead

    $code .= $HBorder? "\\hline\n": '';
    $code .= $titleLine; # Leer, wenn kein Titel
    $code .= "\\endfirsthead\n";
    
    # \endhead
        
    my $msg = $language eq 'german'? 'Fortsetzung': 'Continuation';
    $code .= "\\multicolumn{$width}{r}{\\emph{$msg}} \\\\\n";
    $code .= $HBorder? "\\hline\n": '';
    $code .= $titleLine; # leer, wenn kein Titel
    $code .= "\\endhead\n";

    # \endfoot

    $code .= $HBorder? "\\hline\n": '';
    $msg = $language eq 'german'? 'weiter': 'next';
    $code .= "\\multicolumn{$width}{r}{\\emph{$msg}} \\\\\n";
    $code .= "\\endfoot\n";

    # \endlastfoot

    if ($caption) {
        $code .= "\\caption{$caption}\n";
    }
    $code .= "\\endlastfoot\n";

    # Body

    for (my $i = 0; $i < @$rowA; $i++) {
        my @arr = $rowCb->($self,$gen,$rowA->[$i],$i);
        if ($makecell) {
            for (my $j = 0; $j < @arr; $j++) {
                 if ($arr[$j] =~ s|\n|\\\\|g) {
                     $arr[$j] = sprintf '\makecell[%st]{%s}',
                         $alignA->[$j],$arr[$j];
                 }
            }
        }
        my $line .= join(' & ',@arr).' \\\\';
        $line .= $i < @$rowA-1? $hBorder? ' \hline': '':
            $HBorder? ' \hline': '';
        $line .= "\n";
        $code .= $line;
    }

    # Environment

    my $colSpec = join $vBorder? '|': '',@$alignA;
    if ($VBorder) {
        $colSpec = "|$colSpec|";
    }

    return $gen->env('longtable',$code,
        -p => $colSpec,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.123

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
