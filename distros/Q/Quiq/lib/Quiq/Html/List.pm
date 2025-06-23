# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::List - HTML-Aufzählungsliste

=head1 BASE CLASS

L<Quiq::Html::Base>

=head1 DESCRIPTION

Die Klasse dient der Erzeugung von Aufzählungslisten in HTML.
Sie kann die Listenarten

=over 2

=item *

Ordered List (<ol>)

=item *

Unordered List (<ul>)

=item *

Description List (<dl>)

=back

erzeugen. Siehe Abschnitt L<EXAMPLES|"EXAMPLES">.

=head1 ATTRIBUTES

=over 4

=item isText => $bool (Default: 0)

Der Content aller List-Items besteht aus Text, d.h. <, >, & werden
geschützt.

=item items => \@arr (Default: [])

Content der List-Items.

=item type => 'ordered' | 'unordered' | 'description' (Default: 'unordered')

Legt fest, ob die Aufzählungsliste eine I<Ordered List> (<ol>), eine
I<Unordered List> (<ul>) oder eine I<Description List> (<dl>) ist.

=back

=head1 EXAMPLES

=head2 Unordered List

Die I<Unordered List> ist der Default.

Der Aufruf

  $html = Quiq::Html::List->html($h,
      id => 'list01',
      class => 'list',
      isText => 1,
      items => ['Apfel & Birne','Orange','Pflaume','Zitrone'],
  );

liefert

  <ul id="list01" class="list">
    <li>Apfel &amp; Birne</li>
    <li>Orange</li>
    <li>Pflaume</li>
    <li>Zitrone</li>
  </ul>

=head2 Ordered List

Eine I<Ordered List> wird bei Setzung des Attributs
C<< type=>'ordered' >> erzeugt.

Der Aufruf

  $html = Quiq::Html::List->html($h,
      type => 'ordered',
      id => 'list02',
      class => 'list',
      isText => 1,
      items => ['Apfel & Birne','Orange','Pflaume','Zitrone'],
  );

liefert

  <ol id="list02" class="list">
    <li>Apfel &amp; Birne</li>
    <li>Orange</li>
    <li>Pflaume</li>
    <li>Zitrone</li>
  </ol>

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::List;
use base qw/Quiq::Html::Base/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $obj = $class->new(@keyVal);

=head4 Description

Instantiiere ein Aufzählungslisten-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        items => [],
        isText => 0,
        type => 'unordered',
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $obj->html($h);
  $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code eines Aufzählungslisten-Objekts und liefere
diesen zurück. Als Klassenmethode gerufen, wird das Objekt intern
erzeugt und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($class,$id,$itemA,$isText,$type) =
        $self->get(qw/class id items isText type/);

    if ($type eq 'description') {
        $type = 'dl';
    }
    elsif ($type eq 'ordered') {
        $type = 'ol';
    }
    else {
        $type = 'ul';
    }

    return $h->tag($type,
        id => $id,
        class => $class,
        do {
            my $html;
            if ($type eq 'dl') {
                for (my $i = 0; $i < @$itemA; $i += 2) {
                    my $val = $itemA->[$i+1];
                    if (!defined($val)) { # || $val eq '') {
                        next;
                    }
                    $html .= $h->tag('dt',
                        -text => $isText,
                        $itemA->[$i]
                    );
                    # Wir rücken <dd> zusätzlich ein
                    my $tmp = $h->tag('dd',
                        -text => $isText,
                        $val
                    );
                    $tmp =~ s/^/  /mg;
                    $html .= $tmp;
                }
            }
            else {
                for my $item (@$itemA) {
                    $html .= $h->tag('li',
                        -text => $isText,
                        $item,
                    );
                }
            }
            $html;
        }
    );
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
