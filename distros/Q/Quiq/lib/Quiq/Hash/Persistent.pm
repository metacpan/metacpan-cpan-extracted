# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Hash::Persistent - Persistente Hash-Datenstruktur

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Definition des Konstruktors in einer abgeleiteten Klasse (in diesem
Fall ohne Konstruktorargumente):

  package MyClass;
  use base qw/Quiq::Hash::Persistent/;
  
  sub new {
      my $class = shift;
      ...
      return $class->SUPER::new($file,$timeout,sub {
          my $class = shift;
          ...
          return $class->Quiq::Hash::new(
              ...
          );
      };
  }

=over 2

=item *

Die Klasse (hier MyClass) wird von Quiq::Hash::Persistent abgeleitet

=item *

Der Konstruktor der Klasse kann eine beliebige Signatur haben

=item *

Aus den aktuellen Parametern ergibt sich u.U. der Cache-Dateiname

=item *

Der gesamte oder zumindest der "teure" Anteil des Konstruktors
wird in der anonymen Subroutine sub{} imlementiert

=item *

Die anonyme Subroutine liefert einen Hash der Klasse Quiq::Hash

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Hash::Persistent;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Storable;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $h = $class->new($file,$timeout,$sub);

=head4 Arguments

=over 4

=item $file

Cachedatei, in der die Hash.Datenstruktur persistent gespeichert wird.

=item $timeout (Integer oder undef)

Dauer in Sekunden, die die Cachdatei gültig ist. Falls C<undef>,
ist die Cachdatei unbegrenzt lange gültig.

=item $sub

Subroutine, die den zu persistierenden Hash instantiiert.

=back

=head4 Returns

Referenz auf Hash-Objekt.

=head4 Description

Instantiiere einen Hash aus Datei $file und liefere eine Referenz
auf dieses Objekt zurück. Existiert Datei $file nicht oder liegt
ihr letzter Änderungszeitpunkt mehr als abs($timeout) Sekunden
zurück, rufe $sub auf, um den Hash zu erzeugen und speichere ihn
persistent in Datei $file. Der Hash wird um die Komponenten

=over 2

=item *

cacheFile

=item *

cacheTimeout

=back

erweitert.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file,$timeout,$sub) = @_;

    return Quiq::Storable->memoize($file,$timeout,sub {
        my $h = $sub->($class);
        $h->add(
            cacheFile => $file,
            cacheTimeout => $timeout,
        );
        return $h;
    });
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 cacheFile() - Pfad der Cachedatei

=head4 Synopsis

  $file = $self->cacheFile;

=head4 Returns

Pfad (String)

=head4 Description

Liefere den Pfad der Cachedatei.

=head3 cacheTimeout() - Cache-Timeout

=head4 Synopsis

  $timeout = $self->cacheTimeout;

=head4 Returns

Anzahl Sekunden (Integer oder undef)

=head4 Description

Liefere das für die Cachedatei definierte Timeout.

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
