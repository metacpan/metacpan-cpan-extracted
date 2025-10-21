# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::StreamServe::Stream - Inhalt einer StreamServe Stream-Datei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert den Inhalt einer StreamServe
Stream-Datei:

=over 2

=item *

Feldwerte können abgfragt werden

=item *

Über den Blöcken kann iteriert werden

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::StreamServe::Stream;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.232';

use Quiq::StreamServe::Block;
use Quiq::FileHandle;
use Quiq::Hash;
use Quiq::AnsiColor;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ssf = $class->new($file,%options);

=head4 Arguments

=over 4

=item $file

Pfad der Streamdatei.

=back

=head4 Options

=over 4

=item -debug => $bool (Default: 0)

Gib den Inhalt des Streams auf STDOUT aus (Blöcke in Lesereihenfolge,
Felder alphanumerisch sortiert).

=item -ignore => \@vals (Default: [])

Feldwerte, die auf einen Leerstring reduziert werden. Beispiel:

  -ignore => ['.','*','-']

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.
Enthält die Streamdatei mehr als einen Stream, wird eine Exception
geworfen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file,%options

    # Optionen und Argumente

    my $debug = 0;
    my $ignoreA = [];

    my $argA = $class->parameters(1,1,\@_,
        -debug => \$debug,
        -ignore => \$ignoreA,
    );
    my $file = shift @$argA;

    # Datenstrukturen mit erstem (zunächst leeren) Block

    my $n = 0;
    my $type;
    my $prefix = '*';
    my $blk = Quiq::StreamServe::Block->new($prefix);
    my @blocks = ($blk);
    my %section;
    my $secBlkA = $section{$prefix} = [$blk];

    # StreamServe-Datei lesen

    my $fh = Quiq::FileHandle->new('<',$file);
    $fh->setEncoding('UTF-8');
    while (<$fh>) {
        chomp;
        if ($_ eq '') {
            # Wir übergehen Leerzeilen
            next;
        }
        my ($key,$val) = split /\t/,$_,2;
        if (!defined $val) {
            # Wir übergehen Zeilen ohne Wert. Es sollte nur eine geben:
            #     BEGIN<NAME>
            ($type) = $key =~ /BEGIN(.*)/;
            if (++$n > 1) {
                $class->throw(
                    'STREAM-00099: Streamfile contains more than one stream',
                    StreamFile => $file,
                );
            }
            next;
        }
        $val =~ s/^\s+|\s+$//; # Wert von umgebendem Whitespace befreien
        for my $ign (@$ignoreA) { # unerwünschte Werte wegfiltern
            if ($val eq $ign) {
                $val = '';
            }
        }
        if (/^(..)INDCTR/) {
            # Nächsten (zunächst leeren) Block hinzufügen
            $prefix = $1;
            $blk = Quiq::StreamServe::Block->new($prefix);
            push @blocks,$blk;    
            $secBlkA = $section{$prefix} //= [];
            push @$secBlkA,$blk;
        }
        else {
            $blk->add($key=>$val); 
        }
    }
    $fh->close;

    return $class->SUPER::new(
        file => $file,
        type => $type,
        blockA => \@blocks,
        sectionH => Quiq::Hash->new(\%section),
    );
}

# -----------------------------------------------------------------------------

=head3 numberOfStreams() - Anzahl der (Einzel-)Streams

=head4 Synopsis

  $n = $class->numberOfStreams($file);

=head4 Arguments

=over 4

=item $file

Stream-Datei

=back

=head4 Returns

(Integer) Anzahl der Einzelstreams

=head4 Description

Ermittele die Anzahl der Einzelstreams und liefere diese zurück.
Ax-Streams zählen wir nicht mit.

=cut

# -----------------------------------------------------------------------------

sub numberOfStreams {
    my ($class,$file) = @_;

    my $n = 0;
    my $fh = Quiq::FileHandle->new('<',$file);
    while (<$fh>) {
        if (/^BEGIN/) {
            if (!/A\d$/) {
                $n++;
            }
        }
    }
    $fh->close;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege (Multi-)Stream in Einzelstreams

=head4 Synopsis

  @arr | $arrA = $class->split($file);
  @arr | $arrA = $class->split(\$data);

=head4 Arguments

=over 4

=item $file

Stream-Datei

=item $data

Stream-Daten

=back

=head4 Returns

(Array of Strings) Liste der Einzelstreams

=head4 Description

Zerlege einen (Multi-)Stream (aus Datei oder In-Memory-Daten)
in Einzelstreams und liefere die Liste der Einzelstreams zurück.

Ax-Streams ignorieren wir. D.h. die gelieferte Liste ist leer, wenn der
Stream lediglich einen A0- oder A1-Stream enthält.

=cut

# -----------------------------------------------------------------------------

sub split {
    my ($class,$file) = @_;

    my @arr;
    my $i = 0;
    my $skip = 0;
    my $fh = Quiq::FileHandle->new('<',$file);
    while (<$fh>) {
        if (/^BEGIN/) {
            if (/A\d$/) {
                $skip = 1;
            }
            else {
                $skip = 0;
                $i++;
            }
        }
        if ($skip) {
            next;
        }
        $arr[$i] .= $_;
    }
    $fh->close;

    $i = 0;
    my $header = shift @arr;
    for my $body (@arr) {
        $arr[$i++] = $header.$body;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 allBlocks() - Liste aller Blöcke

=head4 Synopsis

  @arr | $arrH = $ssf->allBlocks;

=head4 Returns

(Array of Hashes) Liste von Blöcken

=head4 Description

Liefere die Liste aller Blöcke des Streams.

=cut

# -----------------------------------------------------------------------------

sub allBlocks {
    my $self = shift;

    my $arr = $self->blockA;
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 blocks() - Liste der Blöcke einer Blockart

=head4 Synopsis

  @arr | $arrH = $ssf->blocks($prefix);
  @arr | $arrH = $ssf->blocks($prefix,$sloppy);

=head4 Arguments

=over 4

=item $prefix

Die Blockart

=back

=head4 Options

=over 4

=item $sloppy

Wenn gesetzt, wirf keine Exception, wenn die Blockart nicht existiet,
sondern liefere eine leere Liste.

=back

=head4 Returns

(Array of Hashes) Liste von Blöcken

=head4 Description

Liefere die Liste der Blöcke einer Blockarten. Eine Blockart ist durch
ihren Präfix charakterisiert.

=cut

# -----------------------------------------------------------------------------

sub blocks {
    my ($self,$prefix,$sloppy) = @_;

    my $arrA = eval {$self->sectionH->get($prefix)};
    if ($@) {
        if ($sloppy) {
            $arrA = [];
        }
        else {
            $self->throw(
                'STREAMSERVE-00099: Block does not exist',
                Prefix => $prefix,
            );
        }
    }
    return wantarray? @$arrA: $arrA;
}

# -----------------------------------------------------------------------------

=head3 file() - Pfad der Streamdatei (Accessor-Methode)

=head4 Synopsis

  $path = $ssf->file;

=head4 Returns

(String) Pfad der Streamdatei

=head4 Description

Liefere den Pfad der Streamdatei.

=cut

# -----------------------------------------------------------------------------

# Accessor-Methode

# -----------------------------------------------------------------------------

=head3 get() - Liefere Wert

=head4 Synopsis

  $val = $ssf->get($name,$i);
  $val = $ssf->get($name);

=head4 Arguments

=over 4

=item $name

Name des abzufragenden Feldes

=item $i (Default: 0)

Index im Falle mehrfachen Vorkommens des Feldes

=back

=head4 Returns

(String) Wert

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$name) = splice @_,0,2;
    my $i = shift // 0;

    my $prefix = substr($name,0,1) eq '*'? '*': substr($name,0,2);
    return $self->sectionH->get($prefix)->[$i]->get($name);
}

# -----------------------------------------------------------------------------

=head3 prefixes() - Liste der Blockarten (Präfixe)

=head4 Synopsis

  @arr | $arrH = $ssf->prefixes;

=head4 Returns

(Array of Strings) Liste der Block-Präfixe

=head4 Description

Liefere die Liste der Blockarten. Eine Blockart ist durch die Liste
der gemeinsamen Feldpräfixe charakterisiert.

=cut

# -----------------------------------------------------------------------------

sub prefixes {
    my $self = shift;

    my @arr = sort keys %{$self->sectionH};
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 report() - Liefere Bericht über den Stream

=head4 Synopsis

  $text = $ssf->report;

=head4 Returns

(String) Text des Berichts

=head4 Description

Erzeuge einen Bericht über den Stream und liefere dessen Text zurück.

=cut

# -----------------------------------------------------------------------------

sub report {
    my $self = shift;

    my $a = Quiq::AnsiColor->new(1);

    my $text = sprintf "---%s---\n",$a->str('bold red','Stream Report');

    for my $blk ($self->allBlocks) {
        $text .= $blk->prefix."\n";
        my $h = $blk->hash;
        my $r = $blk->read;
        for my $key (sort $blk->hash->keys) {
            # $text .= "  $key\n";
            my $val = $h->{$key};
            $text .= sprintf "  %s = %s\n",$key,
                $r->{$key}? $a->str('green',$val): $val;
        }
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Wert

=head4 Synopsis

  $val = $ssf->try($name,$i);
  $val = $ssf->try($name);

=head4 Arguments

=over 4

=item $name

Name des abzufragenden Feldes

=item $i (Default: 0)

Index im Falle mehrfachen Vorkommens des Feldes

=back

=head4 Returns

(String) Wert

=head4 Description

Wie get(), nur dass der Zugriff auf ein nicht-existentes Feld nicht
zu einer Exception führt, sondern C<undef> geliefert wird.

=cut

# -----------------------------------------------------------------------------

sub try {
    my ($self,$name) = splice @_,0,2;
    my $i = shift // 0;

    my $prefix = substr($name,0,1) eq '*'? '*': substr($name,0,2);
    my $val = eval {$self->{'sectionH'}->{$prefix}->[$i]->get($name)};
    return $val;
}

# -----------------------------------------------------------------------------

=head3 type() - Typ des Stream

=head4 Synopsis

  $type = $ssf->type;
  $type = $class->type($file);

=head4 Arguments

=over 4

=item $file

Stream-Datei

=back

=head4 Returns

(String) Typ des Stream, z.B. C<SOS1890H>

=head4 Description

Liefere den Typ der Streamdatei $ssf bzw. $file. Als Klassenmethode
gerufen, wird der Typ effizient ermittelt, ohne den ganzen Stream
einzulesen.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $this = shift;

    # Typ aus dem Objekt liefern

    if (ref $this) {
        return $this->{'type'};
    }

    # StreamServe-Datei lesen

    my $file = shift;

    my $type;
    my $fh = Quiq::FileHandle->new('<',$file);
    while (<$fh>) {
        if (/^BEGIN(.*)/) {
            $type = $1;
        }
    }
    $fh->close;

    return $type;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.232

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
