# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::ContextMenu::Ajax - Erzeuge Code für ein jQuery Kontext-Menü

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erzeugt Code für ein Kontext-Menü, welches durch das
jQuery-Plugin L<jQuery contextmenu|https://swisnl.github.io/jQuery-contextMenu/docs.html> realisiert wird. Der Inhalt
des Menüs wird durch einen AJAX-Aufruf beschafft.

Der Perl-Code

  my $js = Quiq::JQuery::ContextMenu::Ajax->html(
      className => 'contextMenu',
      selector => '.popup',
      trigger => 'left',
  );

liefert

  $.contextMenu({
      className: 'contextMenu',
      selector: '.popup',
      trigger: 'left',
      build: function(ej,ev) {
          var options;
  
          $.ajax({
              type: 'GET',
              url: ej.attr('href'),
              async: false,
              beforeSend: function () {
                  $('body').css('cursor','wait');
              },
              complete: function () {
                  $('body').css('cursor','default');
              },
              success: function (data,textStatus,jqXHR) {
                  // Wir bekommen die Items in einem Array geliefert,
                  // damit die Reihenfolge wohldefiniert ist. Hier
                  // wandeln wir das Array in ein Objekt, wie
                  // das ContexMenu-Plugin es erwartet.
                  var items = {};
                  for (var i = 0; i < data.length; i += 2) {
                      items[data[i]] = data[i+1];
                  }
                  options = {
                      items: items,
                      callback: function(key,options) {
                          var item = items[key];
                          if (item.target)
                              window.open(item.url,item.target);
                          else
                              document.location = item.url;
                      },
                  };
              },
              error: function () {
                  alert('ERROR: AJAX Request failed');
              },
          });
  
          return options;
      },
  });

Das JavaScript-Array C<data>, das vom Server geliefert wird, hat
den Aufbau

  [
      <key>: {
          name: '<name>',
          url: '<url>',
          target: '<target>',
      }
      ...
  ]

Der serverseitige Perl-Code, der eine Menü-Definition liefert (Beispiel):

  return [
      sql => {
          name => 'SQL',
          url => 'sqlFromLog?'.Quiq::Url->queryEncode(
              system => $system,
              path => $logfile,
          ),
      },
      ...
  ];

=head1 SEE ALSO

=over 2

=item *

L<Allgmeine Doku|https://swisnl.github.io/jQuery-contextMenu/docs.html>

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::JQuery::ContextMenu::Ajax;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Assert;
use Quiq::Json::Code;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $obj = $class->new(@keyVal);

=head4 Attributes

=over 4

=item className => $name

Name der CSS-Klasse des Menüs. Kann explizit angegeben werden, wenn das
Menü customized werden soll. Beispiel ($name ist 'contextMenu'):

  .contextMenu {
      width: 85px !important;
      min-width: 50px !important;
  }

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
        className => undef,
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

  $js = $obj->%METHOD;
  $js = $obj->%METHOD(@keyVal);

=head4 Description

Generiere den JavaScript-Code eines Kontext-Menüs und liefere
diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub js {
    my $this = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Objektattribute

    my ($className,$selector,$trigger) =
        $self->get(qw/className selector trigger/);

    # Prüfe Attributwerte

    my $a = Quiq::Assert->new;
    $a->isNotNull($selector,-name=>'selector');

    # JSON-Generator
    my $j = Quiq::Json::Code->new;

    # Generiere JavaScript-Code

    return '$.contextMenu('.$j->o(
        className => $className,
        selector => $selector,
        trigger => $trigger,
        build => $j->c(q~
            function(ej,ev) {
                var options;

                $.ajax({
                    type: 'GET',
                    url: ej.attr('href'),
                    async: false,
                    beforeSend: function () {
                        $('body').css('cursor','wait');
                    },
                    complete: function () {
                        $('body').css('cursor','default');
                    },
                    success: function (data,textStatus,jqXHR) {
                        // Wir bekommen die Items in einem Array geliefert,
                        // damit die Reihenfolge wohldefiniert ist. Hier
                        // wandeln wir das Array in ein Objekt, wie
                        // das ContexMenu-Plugin es erwartet.
                        var items = {};
                        for (var i = 0; i < data.length; i += 2) {
                            items[data[i]] = data[i+1];
                        }
                        options = {
                            items: items,
                            callback: function(key,options) {
                                var item = items[key];
                                if (item.target)
                                    window.open(item.url,item.target);
                                else
                                    document.location = item.url;
                            },
                        };
                    },
                    error: function () {
                        alert('ERROR: AJAX Request failed');
                    },
                });

                return options;
            }
        ~),
    ).');'
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
