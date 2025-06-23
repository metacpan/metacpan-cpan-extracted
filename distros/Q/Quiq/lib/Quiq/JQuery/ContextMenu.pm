# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::ContextMenu - Erzeuge Code für ein jQuery Kontext-Menü

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt Code für ein Kontext-Menü, welches durch das
jQuery-Plugin L<jQuery contextmenu|https://swisnl.github.io/jQuery-contextMenu/docs.html> realisiert wird.

=head1 SEE ALSO

=over 2

=item *

L<Allgmeine Doku|https://swisnl.github.io/jQuery-contextMenu/docs.html>

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::JQuery::ContextMenu;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Assert;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $obj = $class->new(@keyVal);

=head4 Attributes

=over 4

=item autoHide => $bool (Default: 0)

Schließe das Menü, wenn der Mauszeiger das Triggerelement
oder das Menü verlässt.

=item callback => $jsFunction

Funktion, die bei Aufruf eines Menüpunkts gerufen wird. Beispiel:

  callback: function(key,opt) {
      document.location = key;
  },

=item className => $name

Name der CSS-Klasse des Menüs. Kann explizit angegeben werden, wenn das
Menü customized werden soll. Beispiel ($name ist 'contextMenu'):

  .contextMenu {
      width: 85px !important;
      min-width: 50px !important;
  }

=item items => \@items (Default: [])

Array mit den Definitionen der Menüeinträge.

Das JavaScript-Array C<data>, das vom Server geliefert wird, hat
den Aufbau

  [
      $key => $j->object(
          name => $name,
          ...
      ),
      ...
  ]

=item selector => $selector

Der jQuery-Selektor, der die Elemente identifiziert, auf die das
Kontext-Menü gelegt wird. Siehe Plugin-Doku: L<selector|https://swisnl.github.io/jQuery-contextMenu/docs.html#trigger>.

=item trigger => $event

Das Ereignis, durch das das Kontext-Menü angesprochen wird.
Siehe Plugin-Doku: L<tigger>.

=back

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        autoHide => 0,
        callback => undef,
        className => undef,
        items => [],
        selector => undef,
        trigger => undef,
        
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 js() - Generiere JavaScript-Code

=head4 Synopsis

  $js = $obj->%METHOD($j);
  $js = $class->%METHOD($j,@keyVal);

=head4 Description

Generiere den JavaScript-Code eines Kontext-Menüs und liefere
diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub js {
    my ($this,$j) = splice @_,0,2;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Objektattribute

    my ($autoHide,$callback,$className,$itemA,$selector,$trigger) =
        $self->get(qw/autoHide callback className items selector trigger/);

    # Prüfe Attributwerte

    my $a = Quiq::Assert->new;
    $a->isNotNull($callback,-name=>'callback');
    $a->isNotNull($selector,-name=>'selector');

    # Generiere JavaScript-Code

    return '$.contextMenu('.$j->o(
        className => $className,
        selector => $selector,
        trigger => $trigger,
        autoHide => $autoHide? \'true': \'false',
        callback => $j->code($callback),
        items => $j->object(@$itemA),
    ).');';
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
