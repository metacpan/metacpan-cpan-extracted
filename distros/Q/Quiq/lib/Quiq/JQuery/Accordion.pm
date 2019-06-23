package Quiq::JQuery::Accordion;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::Accordion - Erzeuge HTML einer jQuery UI Accodion Reiterleiste

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt den HTML-Code einer jQuery UI Accordion Reiterleiste.
Dem Konstruktor wird die Reiterkonfiguration mit dem Attribut
C<tabs> übergeben. Die Methode L<html|"html() - Generiere HTML">() generiert den HTML-Code.
Siehe Abschnitt L<EXAMPLE|"EXAMPLE">.

=head1 ATTRIBUTES

=over 4

=item id => $id (Default: undef)

DOM-Id der Accordion Reiterleiste.

=item class => $class (Default: undef)

CSS-Klasse der Accordion Reiterleiste.

=item tabs => \@arr (Default: [])

Definition der Accordion-Reiter.

=back

=head1 SEE ALSO

=over 2

=item *

L<Accordion Widget API|http://api.jqueryui.com/accordion/>

=item *

L<Accordion Widget Beispiele|http://jqueryui.com/accordion/>

=back

=head1 EXAMPLE

Perl:

    $html = Quiq::JQuery::Accordion->html($h,
        id => 'accordion',
        tabs => [{
                label => 'A',
                link => 'a',
            },{
                label => 'B',
                content => $h->tag('p',
                    -text => 1,
                    'Text des Reiters B',
                ),
        }],
    );

HTML:

    <div id="accordion">
      <h3><a href="a">A</a></h3>
      <div></div>
      <h3>B</h3>
      <div>
        <p>
          Text des Reiters B
        </p>
      </div>
    </div>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $obj = $class->new(@keyVal);

=head4 Description

Instantiiere ein Accordion-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        class => undef,
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

    my ($class,$id,$tabA) = $self->get(qw/class id tabs/);

    for my $h (@$tabA) {
        Quiq::Hash->validate($h,[qw/content label link/]);
    }

    return $h->tag('div',
        -ignoreIfNull => 1,
        id => $id,
        class => $class,
        '-',
        do {
            my $html;
            for my $t (@$tabA) {
                my $url = $t->{'link'};
                $html .= $h->cat(
                    $h->tag('h3',
                        $h->tag('a',
                            -ignoreTagIf => !$url,
                            href => $url,
                            $t->{'label'},
                        ),
                    ),
                    $h->tag('div',
                        $t->{'content'},
                    ),
                );
            }
            $html;
        },
    );
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
