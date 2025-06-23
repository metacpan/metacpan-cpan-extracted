# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs::Reference - Erzeuge Plotly.js Reference Manual

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::PlotlyJs::Reference;
  use Quiq::Html::Producer;
  
  $root = Quiq::PlotlyJs::Reference->new;
  $h = Quiq::Html::Producer->new;
  $html = $root->asHtml($h);

=head1 DESCRIPTION

Die L<Dokumentation zu Plotly.js|https://plot.ly/javascript/> ist
umfangreich. Ein wichtiger Teil davon, die
L<Full Reference|https://plot.ly/javascript/reference/> mit der Beschreibung aller
Attribute ist allerdings umständlich zu handhaben. Diese Klasse
erzeugt eine L<übersichtlichere Fassung der Full Reference|https://s31tz.github.io/plotlyjs-reference.html>.

=head1 EXAMPLE

=head2 Dokument an der Kommandozeile erzeugen

  $ perl -MQuiq::Html::Producer -MQuiq::PlotlyJs::Reference -E '$h = Quiq::Html::Producer->new; print Quiq::PlotlyJs::Reference->new->asHtml($h)'

produziert auf stdout

  <details>
    <summary>
      0. Layout
    </summary>
    <div style="margin-left: 22px">
      <p>
        <details>
          <summary>
            angularaxis
          </summary>
          <div style="margin-left: 22px">
            <dl>
              <dt>Parent:</dt>
              <dd>layout</dd>
  ... und mehr als 11.000 weitere Zeilen ...

=cut

# -----------------------------------------------------------------------------

package Quiq::PlotlyJs::Reference;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Hash;
use HTML::TreeBuilder ();
use Quiq::Html::List;
use Quiq::Html::Page;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $root = $class->new;

=head4 Returns

Wurzelknoten des Dokument-Baums (Object)

=head4 Description

Parse das Originaldokument, überführe es in einen Dokumentbaum
und liefere eine Referenz auf den Wurzelknoten dieses Baums zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    # my $file = 'Blob/doc-content/plotlyjs-reference-orig.html';
    # my $hRoot = HTML::TreeBuilder->new_from_file($file)->elementify;

    my $url = 'https://plot.ly/javascript/reference/';
    my $hRoot = HTML::TreeBuilder->new_from_url($url)->elementify;

    # Parse die Attributliste eines Knotens

    my $attributesSub; # muss wg. rekursivem Aufruf vorher deklariert werden
    $attributesSub = sub {
        my $h = shift;

        my @attributes;

        my $ul = $h->look_down(_tag=>'ul');
        if ($ul) {
            for my $li ($ul->content_list) {
                # Name

                my $name = $li->look_down(class=>'attribute-name')->as_text;
                $name =~ s/^\s+//;
                $name =~ s/\s+$//;

                my $html = $li->as_HTML;

                # Parent

                my ($parent) = $html =~ m|Parent:.*?<code>(.*?)</code>|;
                if (!defined $parent) {
                    # Angabe Parent: erwarten wir immer
                    $class->throw;
                }

                # Type

                my $type;
                if ($html =~ /Type:/) {
                    ($type) = $html =~ m{Type:</em>(.*?)(<br|<p>|<ul>|$)}s;
                    if (!defined $type) {
                        # Wenn Angabe Type: vorkommt, müssen wir sie
                        # extrahieren können
                        $class->throw(
                             'PLOTYJS-00001: Can\'t extract Type:',
                             Html => $html,
                        );
                    }
                    $type =~ s/^\s+//;
                    $type =~ s/\s+$//;
                    $type =~ s|</?code>||g;
                    $type =~ s|&quot;|"|g;
                }

                # Default

                my $default;
                if ($html =~ /Default:/) {
                    ($default) = $html =~ m|Default:.*?<code>(.*?)</code>|;
                    if (!defined $default) {
                        # Wenn Angabe Default: vorkommt, müssen wir sie
                        # extrahieren können
                        $class->throw(
                             'PLOTYJS-00001: Can\'t extract Default:',
                             Html => $html,
                        );
                    }
                    $default =~ s|</?code>||g;
                    $default =~ s|&quot;|"|g;
                }

                # Description

                my $descr;
                my $p = $li->look_down(_tag=>'p');
                if ($p) {
                    $descr = $p->as_text;
                    $descr =~ s|M~|\\M~|g;
                }

                push @attributes,Quiq::Hash->new(
                    name => $name,
                    parent => $parent,
                    type => $type,
                    default => $default,
                    description => $descr,
                    attributeA => $attributesSub->($li),
                );
            }
        }

        return \@attributes;
    };

    # Parse Dokument

    my $i = 0;
    my @sections;
    for my $hSec ($hRoot->look_down(_tag=>'div',class=>'row')) {
        if (!$i++) {
            # Die Einleitung des Reference-Dokuments übergehen wir
            next;
        }

        my $title = ucfirst $hSec->look_down(_tag=>'h4')->as_text;
        $title =~ s/^\s+//;
        $title =~ s/\s+$//;

        my $descr;
        my $e = $hSec->look_down(_tag=>'div',class=>'description');
        if ($e) {
            $descr = $e->as_text;
        }

        push @sections,Quiq::Hash->new(
            title => $title,
            description => $descr,
            attributeA => $attributesSub->($hSec),
        );
    }

    # Abschnitt Layout an den Anfang
    unshift @sections,pop @sections;

    return $class->SUPER::new(
        title => 'Plotly.js Reference',
        sectionA => \@sections,
    );
}

# -----------------------------------------------------------------------------

=head2 HTML-Repräsentation

=head3 asHtml() - Erzeuge HTML-Repräsentation

=head4 Synopsis

  $html = $obj->asHtml($h);

=head4 Arguments

=over 4

=item $h

Quiq::Html::Tag Objekt.

=back

=head4 Options

=over 4

=item -document => $bool (Default: 0)

Erzeuge ein vollständiges HTML-Dokument.

=item -indent => $n (Default: 22)

Rücke die Ebenen um $n Pixel ein.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Liefere die plotly.js Dokumentation in HTML.

=cut

# -----------------------------------------------------------------------------

sub asHtml {
    my ($self,$h) = splice @_,0,2;

    # Optionen

    my $document = 0;
    my $indent = 22;

    $self->parameters(\@_,
        document => \$document,
        indent => \$indent,
    );

    # Generiere Attributliste 

    my $attributesAsHtmlSub; # muss wg. rekursivem Aufruf deklariert werden
    $attributesAsHtmlSub = sub {
        my ($node,$h,$indent) = @_;

        my $html = '';

        my @attributes = sort {$a->get('name') cmp $b->get('name')}
            @{$node->get('attributeA')};

        for my $att (@attributes) {
            $html .= $h->tag('details',
                '-',
                $h->tag('summary',
                    $att->get('name')
                ),
                $h->tag('div',
                    style => "margin-left: ${indent}px",
                    '-',
                    Quiq::Html::List->html($h,
                        type => 'description',
                        isText => 1,
                        items => [
                            'Parent:' => $att->get('parent'),
                            'Type:' => $att->get('type'),
                            'Default:' => $att->get('default'),
                        ],
                    ),
                    $h->tag('p',
                        -text => 1,
                        $att->get('description')
                    ),
                ),
            );
            $html .= $h->tag('div',
                -ignoreIfNull => 1,
                style => "margin-left: ${indent}px",
                $attributesAsHtmlSub->($att,$h,$indent)
            );
        }

        return $html;
    };

    # Generiere Dokument

    my $html = '';
    my $i = 0;
    for my $sec (@{$self->get('sectionA')}) {
        $html .= $h->tag('details',
            '-',
            $h->tag('summary',
                "$i. ".$sec->get('title')
            ),
            $h->tag('div',
                style => "margin-left: ${indent}px",
                '-',
                $h->tag('p',
                    -text => 1,
                    $sec->get('description')
                ),
                $h->tag('p',
                    $attributesAsHtmlSub->($sec,$h,$indent)
                ),
            ),
        );
        $i++;
    }

    if ($document) {
        my $title = $self->get('title');
        $html = Quiq::Html::Page->html($h,
            title => $title,
            styleSheet => qq~
                body {
                    font-family: sans-serif;
                    font-size: 11pt;
                }
            ~,
            body => $h->cat(
                $h->tag('h1',$title),
                $html,
            ),
        );
    }

    return $html;
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
