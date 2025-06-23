# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Cache - Cache Datenstruktur in Datei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::Cache;
  
  sub ... {
      ...
  
      # Instantiiere Cache
  
      my $c = Quiq::Cache->new($cacheDir,$duration,\@key)
          -inactive => $condition,
      );
      if (my $ref = $c->read) {
          return $ref; # liefere Datenstruktur aus Cache
      }
  
      # Baue Datenstruktur auf
  
      ...
  
      $c->write($ref); # schreibe Datenstuktur auf Cache
  
      return $ref; # liefere Datenstruktur
  }

=head1 DESCRIPTION

Ein Objekt der Klasse verwaltet einen Cache. Der Cache ist ein Verzeichnis
(C<$cacheDir>) im Dateisystem. Eine Cachedatei speichert eine beliebige
Datenstruktur. Diese wird von C<Storable> geschrieben und gelesen.
Die Datenstruktur darf ein Objekt (also geblesst) oder zirkulär sein.
Die Cachdatei ist $duration Sekunden gültig. Danach ist sie
ungültig und wird neu berechnet.

Die Aufrufe L<read|"read() - Lies Daten aus Cachedatei">() und L<write|"write() - Schreibe Daten auf Cachdatei">() haben keine Wirkung, wenn
C<$condition> wahr ist. Damit kann das Caching für bestimmte
Fälle abgschaltet werden.

Das Array @key besteht aus ein oder mehr einzelnen Werten, die zusammen
den Schlüssel für die Cachdatei bilden. Der interne Schüssel ist der
MD5-Hash über diesen Werten. Dieser bildet den Namen der Cachedatei.

=head1 EXAMPLE

Cachen einer HTML-Seite, die von einem einzigen Parameter $day abhängt:

  my $day = $self->param('day') // $today;
  
  my $c = Quiq::Cache->new('~/var/html-cache',43_200,[$day],
      -inactive => $day eq $today,
  );
  if (my $ref = $c->read) {
      $self->render(text=>$$ref);
      return;
  }
  
  my $html = ...HTML erzeugen...
  
  $c->write(\$html);

=cut

# -----------------------------------------------------------------------------

package Quiq::Cache;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Digest;
use Quiq::Path;
use Quiq::Storable;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $c = $class->new($dir,$duration,\@key,@opt);

=head4 Arguments

=over 4

=item $dir

Verzeichnis, in dem die Cachdatei gespeichert wird.

=item $duration

Zeitdauer in Sekunden, die die Cachdatei ab ihrer Erzeugung
gültig ist.

=item @key

Die zur Bildung des Hash herangezogenen Werte.

=back

=head4 Options

=over 4

=item -inactive => $bool (default: 0)

Wenn wahr, ist der Cache inaktiv, d.h. $c->L<read|"read() - Lies Daten aus Cachedatei">() liefert immer
C<undef> und $c->L<write|"write() - Schreibe Daten auf Cachdatei">() hat keine Wirkung.

=item -prefix => $str (Default: '')

Prefix, der der Cachedatei vorangestellt wird.

=back

=head4 Returns

Cache-Objekt

=head4 Description

Instantiiere ein Cache-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir,$duration,$keyA) = splice @_,0,4;

    # Optionen und Argumente

    my $inactive = 0;
    my $prefix = '';

    $class->parameters(\@_,
        -inactive => \$inactive,
        -prefix => \$prefix,
    );

    return $class->SUPER::new(
         duration => $duration,
         file => sprintf('%s/%s%s',$dir,$prefix,Quiq::Digest->md5(@$keyA)),
         inactive => $inactive,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 read() - Lies Daten aus Cachedatei

=head4 Synopsis

  $ref = $c->read;

=head4 Returns

Referenz auf Datenstruktur oder C<undef>

=head4 Description

Liefere eine Referenz auf die Datenstruktur in der Cachdatei oder
C<undef>. Wir liefern C<undef>, wenn

=over 2

=item *

der Cache inaktiv ist

=item *

die Cachdatei nicht existiert

=item *

die Cachdatei exisiert, aber älter ist als die Gültigkeitsdauer

=back

=cut

# -----------------------------------------------------------------------------

sub read {
    my $self = shift;

    if ($self->{'inactive'}) {
        return undef;
    }

    my $p = Quiq::Path->new;
    my ($file,$duration) = @{$self}{qw/file duration/};
    if (!$p->exists($file) || $duration && $p->age($file) > $duration) {
        return undef;
    }

    return Quiq::Storable->thaw(Quiq::Path->read($file));
}

# -----------------------------------------------------------------------------

=head3 write() - Schreibe Daten auf Cachdatei

=head4 Synopsis

  $c->write($ref);

=head4 Arguments

=over 4

=item $ref

Referenz auf Datenstruktur.

=back

=head4 Description

Schreibe Datenstruktur $ref auf die Cachedatei.

=cut

# -----------------------------------------------------------------------------

sub write {
    my ($self,$ref) = @_;

    if (!$self->{'inactive'}) {
        my $file = $self->{'file'};
        Quiq::Path->write($file,Quiq::Storable->freeze($ref));
    }

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
