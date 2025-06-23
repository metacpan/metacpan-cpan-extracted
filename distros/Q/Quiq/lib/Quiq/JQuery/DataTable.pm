# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::DataTable - Erzeuge eine HTML/JavaScript DataTables-Tabelle

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse liefert den HTML- und JavaScript-Code für ein
DataTable-Widget. Hompage des DataTables-Plugin:
L<https://datatables.net/>

=head1 ATTRIBUTES

Attribute, die bei der Instantiierung des JavaScript DataTable-Objekts
gesetzt werden, sind B<fett> hervorgehoben:

=over 4

=item B<< dom => $dom >> (Default: 't')

Definiert die Bedienelemente der Tabelle. Siehe:
L<https://datatables.net/reference/option/dom>

=item B<< emptyTableMsg => $str >> (Default: 'No data')

Text, der angezeigt wird, wenn die Tabelle keine Daten enthält.
Siehe (auch für weitere sprachabhängige Texte):
L<https://datatables.net/reference/option/language>

=item B<< info => $bool >> (Default: 0)

Zeige Information über den Tabelleninhalt an. Siehe:
L<https://datatables.net/reference/option/info>

=item $jsCode => $javaScript

JavaScript-Code der nach der Instantiierung des DataTable-Objektes
hinzugefügt wird.

=item B<< order => \@arrOfArr >> (Default: [])

Initiale Sortierung der Tabelle. Siehe:
L<https://datatables.net/reference/option/order>

=item B<< orderClasses => $bool >> (Default: 1)

Hebe die Sortierkolumnen hervor. Siehe:
L<https://datatables.net/reference/option/orderClasses>

=item B<< paging => $bool >> (Default: 0)

Schalte Paginierung ein. Siehe:
L<https://datatables.net/reference/option/paging>

=item B<< searchLabel => $str >> (Default: 'Search:')

Text, der vor dem Suchfeld angezeigt wird (falls vorhanden)
Siehe (auch für weitere sprachabhängige Texte):
L<https://datatables.net/reference/option/language>

=item B<< zeroRecordsMsg => $str >> (Default: 'No matching records found')

Text, der angezeigt wird, wenn die Suche keine Daten geliefert hat.
Siehe (auch für weitere sprachabhängige Texte):
L<https://datatables.net/reference/option/language>

=item B<< columns => \@columns >> (Default: [])

Referenz auf eine Liste mit Kolumnen-Spezifikationen. Eine einzelne
Kolumnen-Spezifikation ist ein Hash mit den Komponenten:

  {
      name => $name,        # interner Name, insbes. f. Wert-Lookup
      title => $title,      # Kolumnenüberschrift
      type => $type,        # DataTables-Kolumnentyp (s. Link unten)
      align => $align,      # 'left'|'center'|'right' (Default: 'left')
      orderable => $bool,   # 0|1 (Default: 1)
      searchable => $bool,  # 0|1 (Default: 1)
      visible => $bool,     # 0|1 (Default: 1)
      width => $width,      # s. DtaTables Doku
  }

Nicht benötigte Komponenten können weggelassen werden.

Mögliche Werte für $type: 'date', 'num', 'num-fmt', 'html-num',
'html-num-fmt', 'html', 'string'. Siehe
L<https://datatables.net/reference/option/columns.type>

=item allowHtml => $bool|\@titles (Default: 0)

Erlaube HTML insgesamt oder auf den Kolumnen in @titles,
d.h. ersetze die Werte der Kolumnen &, <, > I<nicht> automatisch
durch HTML-Entities.

=item class => $class (Default: "compact stripe hover cell-border nowrap \

order-column")
CSS-Klasse der DataTable (des Table-Elements).

=item fixedHeader => $bool (Default: 0)

Aktiviere FixedHeader. In dem Fall müssen zusätzlich die FixedHrader
CSS- und JS-Resourcen geladen werden.

=item footer => $bool (Default: 0)

Setze die Titel auch als Footer.

=item id => $id (Default: undef)

DOM-Id der DataTable (des Table-Elements).

=item rowsAreArrays => $bool (Default: 0)

Die Row-Objekte sind einfache Arrays. Als rowCallback wird
(per Default) verwendet:

  rowCallback => sub {
      my ($row,$i,$columnA) = @_;
      return (undef,@$row);
  }

Wenn nicht gesetzt, wird (per Default) als rowCallback verwendet:

  rowCallback => sub {
      my ($row,$i,$columnA) = @_;
  
      my @arr;
      for my $col (@$columnA) {
          my $name = $col->name;
          push @arr,$name? $row->get($name): undef;
      }
  
      return (undef,@arr);
  };

=item rowCallback => $sub (Default: s. Attribut rowsAreArrays)

Referenz auf eine Subroutine, die für jedes Row-Objekt die
darzustellende Zeileninformation (für tr- und td-Tag) liefert
(siehe Quiq::Html::Table::List). Der Default hängt vom
Wert des Attributs rowsAreArrays ab. Siehe dort.

=item rows => \@rows (Default: [])

Liste der Row-Objekte. Für jedes Element wird die Callback-Methode
(Attribut rowCallback) aufgerufen.

=back

=head1 EXAMPLE

Default-Aussehen einer DataTable:

=begin html

<p class="sdoc-fig-p">
  <img class="sdoc-fig-img" src="https://raw.github.com/s31tz/Quiq/master/img/quiq-jquery-datatable-example01.png" alt="" />
</p>

=end html

Das Programm

  my $h = Quiq::Html::Producer->new;
  
  my $tab = Quiq::Database::Row::Object->makeTable(
      [qw/per_id per_vorname per_nachname per_geburtsdatum/],
      qw/1 Rudi Ratlos 1971-04-23/,
      qw/2 Harry Hirsch 1948-07-22/,
      qw/3 Susi Sorglos 1992-10-23/,
      qw/4 Axel Nässe 1985-04-05/,
  );
  
  my $html = Quiq::Html::Page->html($h,
      load => [
          'https://code.jquery.com/jquery-latest.min.js',
          'https://cdn.datatables.net/v/dt/dt-1.11.3/datatables.min.css',
          'https://cdn.datatables.net/v/dt/dt-1.11.3/datatables.min.js',
      ],
      styleSheet => q~
          body {
              font-family: sans-serif;
              font-size: 12pt;
              max-width: 500px;
          }
      ~,
      body => Quiq::JQuery::DataTable->html($h,
          id => 'personTable',
          order => [[2,'asc']],
          columns => [
              {
                  name => 'per_id',
                  title => 'Id',
                  align => 'right',
              },{
                  name => 'per_vorname',
                  title => 'Vorname',
              },{
                  name => 'per_nachname',
                  title => 'Nachname',
              },{
                  name => 'per_geburtsdatum',
                  title => 'Geburtstag',
                  align => 'center',
              },
          ],
          rows => scalar $tab->rows,
      ),
  );

erzeugt den HTML-Code (lange Zeilen umbrochen)

  <!DOCTYPE html>
  
  <html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.11.3/datatables.min.css" />
    <script type="text/javascript" src="https://code.jquery.com/jquery-latest.min.js"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.11.3/datatables.min.js"> </script>
    <style type="text/css">
      body {
        font-family: sans-serif;
        font-size: 12pt;
        max-width: 500px;
      }
    </style>
  </head>
  <body>
    <table class="compact stripe hover cell-border nowrap order-column" id="personTable" cellspacing="0">
    <thead>
      <tr>
        <th>Id</th>
        <th>Vorname</th>
        <th>Nachname</th>
        <th>Geburtstag</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>1</td>
        <td>Rudi</td>
        <td>Ratlos</td>
        <td>1971-04-23</td>
      </tr>
      <tr>
        <td>2</td>
        <td>Harry</td>
        <td>Hirsch</td>
        <td>1948-07-22</td>
      </tr>
      <tr>
        <td>3</td>
        <td>Susi</td>
        <td>Sorglos</td>
        <td>1992-10-23</td>
      </tr>
      <tr>
        <td>4</td>
        <td>Axel</td>
        <td>Nässe</td>
        <td>1985-04-05</td>
      </tr>
    </tbody>
    </table>
    <script type="text/javascript">
      var dt = $('#personTable').DataTable({
        dom: 't',
        info: false,
        order: [[2,'asc']],
        orderClasses: true,
        paging: false,
        columns: [{className:'dt-right'},{className:'dt-left'},{className:'dt-left'},{className:'dt-center'}],
      });
      $('#personTable').show();
    </script>
  </body>
  </html>

=cut

# -----------------------------------------------------------------------------

package Quiq::JQuery::DataTable;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Html::Table::List;
use Quiq::Hash;
use Quiq::Json::Code;
use Quiq::Unindent;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $obj = $class->new(@keyVal);

=head4 Description

Instantiiere eine DataTable in Perl und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        # DataTable-Attribute
        dom => 't',
        emptyTableMsg => undef,
        info => 0,
        jsCode => undef,
        order => [],
        orderClasses => 1,
        paging => 0,
        searchLabel => undef,
        zeroRecordsMsg => undef,
        # HTML-Attribute
        allowHtml => 0,
        class => 'compact stripe hover cell-border nowrap order-column',
        columns => [],
        fixedHeader => 0,
        footer => 0,
        id => undef,
        rowsAreArrays => 0,
        rowCallback => undef,
        rows => [],
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Code-Generierung

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $obj->html($h);
  $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des DataTable-Objekts und liefere
diesen zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($allowHtml,$class,$footer,$id,$rowsAreArrays,
        $rowCallback,$rowA) = $self->get(qw/allowHtml class footer id
        rowsAreArrays rowCallback rows/);

    # Liste der Kolumnendefinitionen als Hash-Objekte
    my @columns = $self->getColumns;

    if (!$rowCallback) {
        if ($rowsAreArrays) {
            $rowCallback = sub {
                my ($row,$i,$columnA) = @_;
                return (undef,@$row);
            };
        }
        else {
            $rowCallback = sub {
                my ($row,$i,$columnA) = @_;

                my @arr;
                for my $col (@$columnA) {
                    my $name = $col->name;
                    push @arr,$name? $row->get($name): undef;
                }

                return (undef,@arr);
            };
        }
    };

    # HTML generieren

    if (!@columns) {
        return '';
    }

    my @titles;
    for my $col (@columns) {
        push @titles,$col->title;
    }

    if (ref $allowHtml) {
        my %column = map {$_->name => $_} @columns;
        my @arr;
        for my $name (@$allowHtml) {
            my $col = $column{$name};
            if (!$col) {
                $self->throw(
                     'DATATABLE-00001: Column does not exist',
                     Column => $name,
                );
            }
            push @arr,$col->title;
        }
        $allowHtml = \@arr;
    }

    my $html = Quiq::Html::Table::List->html($h,
        allowHtml => $allowHtml,
        border => 0,
        class => $class,
        empty => undef,
        id => $id,
        rowCallback => $rowCallback,
        rowCallbackArguments => [\@columns],
        rows => $rowA,
        titles => \@titles,
        footer => $footer,
    );

    # Instantiiere DataTable-Objekt

    $html .= $h->tag('script',
        $self->instantiate,
    );

    return $html;
}

# -----------------------------------------------------------------------------

=head2 Hilfsmethoden

=head3 getColumns() - Liste der Kolumnendefinitionen

=head4 Synopsis

  @columns | $columns = $e->getColumns;

=head4 Description

Liefere die Liste der Kolumnendefinitionen. Die Kolumnen werden
beim Setzen des Objektattributs columns als einfache Hashes
angegeben. Diese Methode liefert die Kolumnen-Definitionen als
Hash-Objekte (vom Typ Quiq::Hash).

=cut

# -----------------------------------------------------------------------------

sub getColumns {
    my $self = shift;

    my ($columnA) = $self->get(qw/columns/);

    # Column-Hashes in Objekte wandeln. Die Attributnamen werden
    # dabei auf Korrektheit geprüft.

    my @columns;
    for my $h (@$columnA) {
        push @columns,Quiq::Hash->new([qw/
            name
            title
            type
            align
            orderable
            render
            searchable
            visible
            width
        /])->join($h);
    }

    return wantarray? @columns: \@columns;
}

# -----------------------------------------------------------------------------

=head3 instantiate() - Instantiiere Widget in JavaScript

=head4 Synopsis

  $javaScript = $e->instantiate;

=head4 Description

Liefere den JavaScript-Code, der das DataTables-Objekt in JavaScript
instantiiert. Aufbau:

  jQuery('#ID').DataTable({
      <JSON-Code>,
      columns: [
          <Kolumnen-Definitionen>
      ]
  });

=cut

# -----------------------------------------------------------------------------

sub instantiate {
    my ($self,$json) = @_;

    my ($id,$dom,$emptyTableMsg,$fixedHeader,$footer,$info,$jsCode,$orderA,
        $orderClasses,$paging,$searchLabel,$zeroRecordsMsg) =
        $self->get(qw/id dom emptyTableMsg fixedHeader footer info jsCode order
        orderClasses paging searchLabel zeroRecordsMsg/);

    my $j = Quiq::Json::Code->new;

    my @language;
    if ($emptyTableMsg) {
        push @language,emptyTable=>$emptyTableMsg;
    }
    if ($searchLabel) {
        push @language,search=>$searchLabel;
    }
    if ($zeroRecordsMsg) {
        push @language,zeroRecords=>$zeroRecordsMsg;
    }

    my @prop = (
        dom => $dom,
        info => $info? \'true': \'false',
        order => $orderA,
        orderClasses => $orderClasses? \'true': \'false',
        paging => $paging? \'true': \'false',
        !@language? (): (language=>{@language}),
    );

    my @columns;
    for my $col ($self->getColumns) {
        my %col;
        if (my $type = $col->type) {
             $col{'type'} = $type; 
        }
        if (my $align = $col->align || 'left') {
            $col{'className'} = "dt-$align"; 
        }
        my $searchable = $col->searchable;
        if (defined $searchable) {
            $col{'searchable'} = $searchable; 
        }
        my $orderable = $col->orderable;
        if (defined $orderable) {
            $col{'orderable'} = $orderable? \'true': \'false'; 
        }
        my $visible = $col->visible;
        if (defined $visible) {
            $col{'visible'} = $visible? \'true': \'false';
        }
        if (my $width = $col->width) {
            $col{'width'} = $width; 
        }
        if (my $render = $col->render) {
            $col{'render'} = \$render; 
        }
        push @columns,\%col;
    }
    push @prop,columns=>\@columns;

    my $js = sprintf q|var dt = $('#%s').DataTable(%s);|,
        $id,scalar $j->object(@prop);

    if ($jsCode) {
        $js .= "\n".Quiq::Unindent->string($jsCode);
    }

    $js .= "\n".sprintf q|$('#%s').show();|,$id;

    if ($fixedHeader) {    
        $js .= "\n".sprintf q|new $.fn.dataTable.FixedHeader(dt,%s);|,
            scalar $j->object(
                header => \'true',
                !$footer? (): (footer => \'true'),
            )
        ;
    }
    return $js;
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
