package Quiq::JQuery::Tabs;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Hash;
use Quiq::Html::List;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::Tabs - Erzeuge HTML einer jQuery UI Tabs Reiterleiste

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt den HTML-Code einer jQuery UI Reiterleiste.
Dem Konstruktor wird die Reiterkonfiguration mit dem Attribut
C<tabs> übergeben. Die Methode L<html|"html() - Generiere HTML">() generiert den HTML-Code.
Siehe Abschnitt L<EXAMPLE|"EXAMPLE">.

=head1 ATTRIBUTES

=over 4

=item id => $id (Default: undef)

DOM-Id der Reiterleiste.

=item tabs => \@arr (Default: [])

Definition der Reiter.

=back

=head1 SEE ALSO

=over 2

=item *

L<Tabs Widget API|http://api.jqueryui.com/tabs/>

=item *

L<Tabs Widget Beispiele|http://jqueryui.com/tabs/>

=back

=head1 EXAMPLE

Perl:

    $html = Quiq::JQuery::Tabs->html($h,
        id => 'tabs',
        tabs => [
            {
                label => 'A',
                link => '#a',
                content => $h->tag('p',
                    -text => 1,
                    'Text des Reiters A',
                ),
            },{
                label => 'B',
                link => 'b',
            },
        ],
    );

HTML:

    <div id="tabs">
      <ul>
        <li><a href="#a">A</a></li>
        <li><a href="b">B</a></li>
      </ul>
      <div id="a">
        <p>
          Text des Reiters A
        </p>
      </div>
    </div>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $obj = $class->new(@keyVal);

=head4 Description

Instantiiere ein Reiterleisten-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        id => undef,
        tabs => [],
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

Generiere den HTML-Code eines Reiterleisten-Objekts und liefere
diesen zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($id,$tabA) = $self->get(qw/id tabs/);

    if (!@$tabA) {
        return '';
    }

    for my $h (@$tabA) {
        Quiq::Hash->validate($h,[qw/content label link/]);
    }

    return $h->tag('div',
        id => $id,
        '-',
        # <ul>-Abschnitt
        Quiq::Html::List->html($h,
            items => do{
                my @items;
                for my $t (@$tabA) {
                    push @items,$h->tag('a',
                        href => $t->{'link'},
                        $t->{'label'},
                    );
                }
                \@items;
            },
        ),
        # <div>-Abschnitt mit Unter-<divs> für jeden Reiter,
        # dessen Content lokal definiert ist (Link referenziert Anker)
        do {
            my $html = '';
            for my $t (@$tabA) {
                if (my ($anchor) = $t->{'link'} =~ /^#(.*)/) {
                    $html .= $h->tag('div',
                        id => $anchor,
                        $t->{'content'}
                    );
                }
            }
            $html;
        }
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
