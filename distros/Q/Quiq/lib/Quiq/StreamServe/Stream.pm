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

our $VERSION = '1.226';

use Quiq::FileHandle;
use Hash::Util ();

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

    my $prefix = '*';
    my %section; # Abschnittsarten
    my $blockA = $section{$prefix} = []; # Liste der Abschnittsartenblöcke
    my $blockH = {}; # erster Block
    my $fh = Quiq::FileHandle->new('<',$file);
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
            # Vorhergehenden Block speichern
            Hash::Util::lock_keys(%$blockH);
            push @$blockA,$blockH;
            # Nächsten Block vorbereiten
            $prefix = $1;
            $blockA = $section{$prefix} //= [];
            $blockH = {};
        }
        else {
            $blockH->{$key} = $val; 
        }
    }
    $fh->close;

    # Letzten Block speichern
    Hash::Util::lock_keys(%$blockH);
    push @$blockA,$blockH;

    return $class->SUPER::new(\%section);
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

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$name) = splice @_,0,2;
    my $i = shift // 0;

    my $prefix = substr($name,0,1) eq '*'? '*': substr($name,0,2);
    return $self->{$prefix}->[$i]->{$name};
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

    my @arr = sort keys %$self;
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 blocks() - Liste der Blöcke einer Blockart

=head4 Synopsis

  @arr | $arrH = $ssf->blocks($prefix);

=head4 Arguments

=over 4

=item $prefix

Die Blockart

=back

=head4 Returns

(Array of Hashes) Liste von Blöcken

=head4 Description

Liefere die Liste der Blöcke einer Blockarten. Eine Blockart ist durch
ihren Präfix charakterisiert.

=cut

# -----------------------------------------------------------------------------

sub blocks {
    my ($self,$prefix) = @_;

    my $arrA = $self->{$prefix};
    return wantarray? @$arrA: $arrA;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.226

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
