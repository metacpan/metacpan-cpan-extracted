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

our $VERSION = '1.228';

use Quiq::StreamServe::Block;
use Quiq::FileHandle;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ssf = $class->new($file);

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    # Datenstrukturen mit erstem (zunächst leeren) Block

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
            next;
        }
        $val =~ s/^\s+|\s+$//; # Wert von umgebendem Whitespace befreien
        if (/^(..)INDCTR/) {
            # $blk->lockKeys;
            # Nächsten (zunächst leeren) Block hinzufügen
            $prefix = $1;
            $blk = Quiq::StreamServe::Block->new($prefix);
            push @blocks,$blk;    
            $secBlkA = $section{$prefix} //= [];
            push @$secBlkA,$blk;
        }
        else {
            $blk->set($key=>$val); 
        }
    }
    $fh->close;
    # $blk->lockKeys;

    return $class->SUPER::new(
        blockA => \@blocks,
        sectionH => Quiq::Hash->new(\%section),
    );
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege (Multi-)Streamdatei in Einzelstreams

=head4 Synopsis

  @arr | $arrA = $class->split($file);

=head4 Returns

(Array of Strings) Liste der Einzelstreams

=head4 Description

Zerlege die (Multi-)Streamdatei in Einzelstreams und liefere die Liste
der Einzelstreams zurück.

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
            if (/A0$/) {
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
            $self->thow(
                'STREAMSERVE-00099: Block does not exist',
                Prefix => $prefix,
            );
        }
    }
    return wantarray? @$arrA: $arrA;
}

# -----------------------------------------------------------------------------

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
