package Quiq::Html::Form::Layout;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Html::Widget::Hidden;
use Quiq::Template;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Form::Layout - HTML-Formular mit freiem Layout

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt ein HTML-Formular mit einem freiem Layout,
d.h. der HTML-Code "um die Widgets herum" wird von der Klasse
nicht vorgegeben, sondern per Objektattribut gesetzt, ebenso wie
die Liste der Widgets. Die Methode html() der Klasse setzt die
Widgets in das Layout ein.

Für jedes Widget enthält das Layout einen Platzhalter, der sich
aus dem Namen des Widget herleitet. Der Platzhalter wird gebildet,
indem der Widget-Name in Großbuchstaben gewandelt und um zwei
Unterstriche am Anfang und am Ende ergänzt wird.

Beispiele:

    Widget-Name  Platzhalter
    -----------  -----------
    vorname      __VORNAME__
    nachname     __NACHNAME__
    aktion       __AKTION__

Anmerkungen:

=over 2

=item *

Hidden-Widgets oder Widgets, die hidden geschaltet sind, werden
nicht in das Layout eingesetzt, sondern als Hidden-Inputs
(C<< <input type="hidden" ...> >>) dem Layout-HTML vorangestellt.

=item *

C<< <!--optional ...--> >> Meta-Tags werden nach dem
Einsetzen der Widgets in das Layout aufgelöst.

=back

=head1 ATTRIBUTES

=over 4

=item form => \@keyVal (Default: undef)

Eigenschaften des C<form>-Tag. Ist das Attribut nicht gesetzt,
wird kein C<form>-Tag erzeugt.

=item hidden => \@keyVal (Default: [])

Schlüssel/Wert-Paare, die als Hidden-Widgets gesetzt werden.

=item layout => $html (Default: '')

Der HTML-Code des Layouts. In das Layout wird der HTML-Code der
Widgets eingesetzt.

=item widgets => \@widgets (Default: [])

Liste der Widgets, die in das Layout eingesetzt werden.

=back

=head1 EXAMPLE

Der Code

    Quiq::Html::Form::Layout->html($h,
        layout => Quiq::Html::Table::Simple->html($h,
            class => 'form',
            rows => [
                [['Vorname:'],['__VORNAME__']],
                [['Nachname:'],['__NACHNAME__']],
                [[''],['__AKTION__']],
            ],
        ),
        widgets => [
            Quiq::Html::Widget::Hidden->new(
                name => 'id',
                value => '4711',
            ),
            Quiq::Html::Widget::TextField->new(
                name => 'vorname',
                value => 'Lieschen',
            ),
            Quiq::Html::Widget::TextField->new(
                name => 'nachname',
                value => 'Müller',
            ),
            Quiq::Html::Widget::Button->new(
                id => 'speichern',
                name => 'aktion',
                value => 'speichern',
                content => 'Speichern',
            ),
        ],
    );

erzeugt

    <input type="hidden" name="id" value="4711">
    <table class="form" cellspacing="0">
    <tr>
      <td>Vorname:</td>
      <td><input type="text" name="vorname" value="Lieschen" /></td>
    </tr>
    <tr>
      <td>Nachname:</td>
      <td><input type="text" name="nachname" value="Müller" /></td>
    </tr>
    <tr>
      <td></td>
      <td><button id="speichern" name="aktion" type="button"
        value="speichern">Speichern</button></td>
    </tr>
    </table>

Das tabellarische Layout wird hier von einer anderen Klasse
(Quiq::Html::Table::Simple) geliefert, die die Tabelle
erzeugt.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein Formular-Objekt mit den Eigenschaften @keyVal und
liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        form => undef,
        hidden => undef,
        layout => '',
        widgets => [],
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des Formular-Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($formA,$hiddenA,$layout,$widgetA) = $self->get(qw/form hidden
        layout widgets/);

    # Schlüssel/Wert-Paare, die hidden gesetzt werden

    my $hidden = '';
    if ($hiddenA) {
        for (my $i = 0; $i < @$hiddenA; $i += 2) {
            $hidden .= Quiq::Html::Widget::Hidden->html($h,
                name => $hiddenA->[$i],
                value => $hiddenA->[$i+1],
            );
        }
    }

    # a) Widgets ihrem Platzhalter zuordnen
    # b) Hidden-Widgets nicht einsetzen, sondern hidden setzen

    my @keyVal;
    for my $w (@$widgetA) {
        if ($w->hidden) {
            $hidden .= $w->html($h);
            next;
        }
        push @keyVal,sprintf('__%s__',uc $w->name),$w->html($h);
    }

    $layout = $h->tag('form',
        -ignoreTagIf => !$formA,
        @$formA,
        $hidden.$layout
    );

    my $tpl = Quiq::Template->new('text',\$layout,
        -singleReplace  =>  1,
    );
    $tpl->replace(@keyVal);
    $tpl->removeOptional;
        
    return $tpl->asStringNL;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
