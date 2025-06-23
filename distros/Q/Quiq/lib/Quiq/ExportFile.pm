# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ExportFile - Manipuliere Exportdatei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse definiert Operationen auf Exportdateien der Art:

  per_id|per_vorname|per_nachname
  1|Rudi|Ratlos
  2|Elli|Pirelli
  3|Susi|Sorglos
  4|Kai|Nelust
  5|Lieschen|Müller
  6|Mark|Kiese
  7|Andreas|Kreuz
  8|Annie|Malisch
  9|Kurt|Schluss
  10|Franz|Brötchen
  11|Klara|Fall
  12|Carmen|Bär
  13|Nico|Laus
  14|Vitali|Sierend
  15|Hella|Wahnsinn
  16|Knut|Schmund
  17|Ernst|Fall
  18|Rainer|Zufall
  19|Erika|Mustermann

=cut

# -----------------------------------------------------------------------------

package Quiq::ExportFile;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $exf = $class->new($file);

=head4 Arguments

=over 4

=item $file

Pfad der Exportdatei.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    return $class->SUPER::new(
        file => $file,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 addColumn() - Füge Kolumne hinzu

=head4 Synopsis

  $exf->addColumn($column);
  $exf->addColumn($column,$value);

=head4 Arguments

=over 4

=item $column

Name der Kolumne, die hinzugefügt werden soll.

=item $value (Default: '')

Setze den Wert der Kolumne auf $value.

=back

=head4 Description

Füge Kolumne $column mit Wert $value zur Exportdatei hinzu.

=head4 Example

  $ perl -MQuiq::ExportFile -E \
      'Quiq::ExportFile->new("person.dat")->addColumn("per_geburtstag")'

=cut

# -----------------------------------------------------------------------------

sub addColumn {
    my ($self,$column,$value) = @_;

    $value //= '';

    my $inFile = $self->file;
    my $tmpFile = "$inFile.tmp";

    my $p = Quiq::Path->new;

    my $fhIn = Quiq::FileHandle->new('<',$inFile);
    my $fhOut = Quiq::FileHandle->new('>',$tmpFile);

    my $titles = <$fhIn>;
    chomp $titles;
    my @titles = split /\|/,$titles;
    my $width = @titles;

    my $index = -1;
    for (my $i = 0; $i < @titles; $i++) {
        if ($titles[$i] eq $column) {
            $index = $i;
            last;
        }
    }
    if ($index >= 0) {
        # Kolumne existiert bereits -> nichts tun

        $fhIn->close;
        $fhOut->close;
        
        return;
    }
    
    push @titles,$column;
    say $fhOut join('|',@titles);

    my $line = 1;
    while (<$fhIn>) {
        $line++;
        chomp;
        my @arr = split /\|/,$_,-1;
        if (@arr != $width) {
            $self->throw(
                'EXPORTFILE-00002: Wrong column width',
                Column => $column,
                Width => scalar(@arr),
                ExpectedWidth => $width,
                Line => $line,
            );
        }
        push @arr,$value;
        say $fhOut join('|',@arr);
    }

    $fhIn->close;
    $fhOut->close;

    $p->rename($tmpFile,$inFile);

    return;
}

# -----------------------------------------------------------------------------

=head3 dropColumn() - Entferne Kolumne

=head4 Synopsis

  $exf->dropColumn($column);

=head4 Arguments

=over 4

=item $column

Name der Kolumne, die entfernt werden soll.

=back

=head4 Description

Entferne Kolumne $column aus der Exportdatei.

=head4 Example

  $ perl -MQuiq::ExportFile -E \
      'Quiq::ExportFile->new("person.dat")->dropColumn("per_geburtstag")'

=cut

# -----------------------------------------------------------------------------

sub dropColumn {
    my ($self,$column) = @_;

    my $inFile = $self->file;
    my $tmpFile = "$inFile.tmp";

    my $p = Quiq::Path->new;

    my $fhIn = Quiq::FileHandle->new('<',$inFile);
    my $fhOut = Quiq::FileHandle->new('>',$tmpFile);

    my $titles = <$fhIn>;
    chomp $titles;
    my @titles = split /\|/,$titles;
    my $width = @titles;

    my $index = -1;
    for (my $i = 0; $i < @titles; $i++) {
        if ($titles[$i] eq $column) {
            $index = $i;
            last;
        }
    }
    if ($index < 0) {
        $self->throw(
            'EXPORTFILE-00001: Column not found',
            Column => $column,
        );
    }

    splice @titles,$index,1;
    say $fhOut join('|',@titles);

    my $line = 1;
    while (<$fhIn>) {
        $line++;
        chomp;
        my @arr = split /\|/,$_,-1;
        if (@arr != $width) {
            $self->throw(
                'EXPORTFILE-00002: Wrong column width',
                Column => $column,
                Width => scalar(@arr),
                ExpectedWidth => $width,
                Line => $line,
            );
        }
        splice @arr,$index,1;
        say $fhOut join('|',@arr);
    }

    $fhIn->close;
    $fhOut->close;

    $p->rename($tmpFile,$inFile);

    return;
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
