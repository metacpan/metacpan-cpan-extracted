# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Form::Matrix - HTML-Formular mit Matrix-Layout

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt ein HTML-Formular mit Matrix-Layout,
d.h. es besteht aus mehreren Zeilen gleichartiger Widgets.

=head1 ATTRIBUTES

=over 4

=item border => $bool (Default: 0)

Umrande die Felder der zugrundeliegenden Tabelle.

=item initialize => $sub (Default: sub {})

Subroutine zur Initialisierung der Widgets. Beispiel:

  sub {
      my ($w,$name,$i) = @_;
  
      my $val = $self->param($name."_$i");
      $w->value($val);
  }

=item name => $name (Default: 'formMatrix')

Name der Formular-Matrix.

=item names => \@names (Default: [])

Liste der Widgetnamen. Zum diesen Widgetnamen wird jeweils "_$i"
mit der Nummer $i der Zeile hinzugefügt, beginnend mit 1 für die
erste Zeile.

=item rows => $n (Default: 1)

Anzahl der Zeilen.

=item titles => \@titles (Default: [])

Liste der Kolumnentitel.

=item widgets => \@widgets (Default: [])

Widgets einer Matrix-Zeile.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Form::Matrix;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Html::Widget::Hidden;
use Quiq::Storable;
use Quiq::Html::Table::Simple;

# -----------------------------------------------------------------------------

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
        border => 0,
        initialize => sub {},
        name => 'formMatrix',
        names => [],
        rows => 1,
        titles => [],
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

Generiere den HTML-Code der Formular-Matrix und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($border,$initializeSub,$name,$rows,$titleA,$widgetA) =
        $self->get(qw/border initialize name rows titles widgets/);

    if (!@$widgetA) {
        return '';
    }

    my @rows;

    my @row;
    for my $title (@$titleA) {
        push @row,[$title];
    }
    push @rows,\@row;

    my $hidden = Quiq::Html::Widget::Hidden->html($h,
        name => $name.'Size',
        value => $rows
    );

    for my $i (1 .. $rows) {
        my @row;
        for (@$widgetA) {
            my $w = Quiq::Storable->clone($_);
            my $name = $w->name;
            $w->name($name."_$i");
            $initializeSub->($w,$name,$i);
            if ($w->hidden) {
               $hidden .= $w->html($h);
               next;
            }
            push @row,[$w->html($h)];
        }
        push @rows,\@row;
    }

    return $hidden.
        Quiq::Html::Table::Simple->html($h,
            border => $border,
            rows => \@rows,
        )
    ;
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
