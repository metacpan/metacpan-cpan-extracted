package Quiq::JQuery::DataTable;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Html::Table::List;
use Quiq::Unindent;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::DataTable - Erzeuge eine HTML/JavaScript DataTables-Tabelle

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

=begin html

<p class="sdoc-fig-p">
  <img class="sdoc-fig-img" src="https://raw.github.com/s31tz/Quiq/master/img/quiq_jquery_datatable_example01.png" width="757" height="170" alt="" />
</p>

=end html

Quelltext siehe Abschnitt L<Beispiel Synopsis|"Beispiel Synopsis">.

=head1 DESCRIPTION

Hompage des DataTables-Plugin:
L<https://datatables.net/>

Die Klasse liefert den HTML- und JavaScript-Code für ein
DataTable-Widget.

=head1 ATTRIBUTES

=over 4

=item arguments => $json (Default: undef)

JSON-Code der das DataTable-Objekt in JavaScript instantiiert. Die
äußeren geschweiften Klammern werden hierbei weggelassen. Die
Kolumnendefinitionen (DataTables-Attribut columns:) wird intern
generiert und zu diesem Code hinzugefügt.

=item class => $class (Default: undef)

CSS-Klasse der DataTable (des Table-Elements).

=item columns => \@columns (Default: [])

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
    }

Nicht benötigte Komponenten können weggelassen werden.

Mögliche Werte für $type: 'date', 'num', 'num-fmt', 'html-num',
'html-num-fmt', 'html', 'string'. Siehe
L<https://datatables.net/reference/option/columns.type>

=item footer => $bool (Default: 0)

Setze die Titel auch als Footer.

=item id => $id (Default: undef)

DOM-Id der DataTable (des Table-Elements).

=item instantiate => $bool (Default: 0)

Füge die Instantiierung des DataTable-Objektes (JavaScript) zum
HTML-Code der Methode html() hinzu.

=item rowCallback => $sub (Default: s.u.)

Referenz auf eine Subroutine, die für jedes Row-Objekt die
darzustellende Zeileninformation (für tr- und td-Tag) liefert
(siehe Quiq::Html::Table::List). Default:

    rowCallback => sub {
        my ($row,$i,$columnA) = @_;
    
        my @arr;
        for my $col (@$columnA) {
            my $name = $col->name;
            push @arr,$name? $row->get($name): undef;
        }
    
        return (undef,@arr);
    };

=item rows => \@rows (Default: [])

Liste der Row-Objekte. Für jedes Element wird die Callback-Methode
(Attribut rowCallback) aufgerufen.

=back

=head1 EXAMPLES

=head2 Beispiel Synopsis

Default-Aussehen einer DataTable:

=begin html

<p class="sdoc-fig-p">
  <img class="sdoc-fig-img" src="https://raw.github.com/s31tz/Quiq/master/img/quiq_jquery_datatable_example01.png" width="757" height="170" alt="" />
</p>

=end html

Das Programm

    my $tab = Quiq::Database::Row::Object->makeTable(
        [qw/per_id per_vorname per_nachname per_geburtsdatum/],
        qw/1 Rudi Ratlos 1971-04-23/,
        qw/2 Erika Mustermann 1955-03-16/,
        qw/3 Harry Hirsch 1948-07-22/,
        qw/4 Susi Sorglos 1992-10-23/,
    );
    
    my $h = Quiq::Html::Tag->new('html-5');
    
    my $html = Quiq::JQuery::DataTable->html($h,
        id => 'personTable',
        class => 'compact stripe hover cell-border',
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
        instantiate => 1,
    );

erzeugt den HTML-Code (lange Zeilen umbrochen)

    <table id="personTable" class="compact stripe hover cell-border"
      cellspacing="0">
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
        <td>Erika</td>
        <td>Mustermann</td>
        <td>1955-03-16</td>
      </tr>
      <tr>
        <td>3</td>
        <td>Harry</td>
        <td>Hirsch</td>
        <td>1948-07-22</td>
      </tr>
      <tr>
        <td>4</td>
        <td>Susi</td>
        <td>Sorglos</td>
        <td>1992-10-23</td>
      </tr>
    </tbody>
    </table>
    <script type="text/javascript">
      jQuery('#personTable').DataTable({
        columns: [
          {
            className: 'dt-right',
          },{
            className: 'dt-left',
          },{
            className: 'dt-left',
          },{
            className: 'dt-center',
          },
        ],
      });
    </script>

=head2 Mit Instantiierungs-Argumenten (HTML-Seite)

Beispiel für die Angabe von Instantiierungs-Argumenten. Dies
kann bei Aufruf der Methode
L<instantiate() - Instantiiere Widget in JavaScript|"instantiate() - Instantiiere Widget in JavaScript">

    $dt->instantiate(q~
        fixedHeader: true,
        stateSave: true,
        dom: 't',
    ~),

oder durch Zuweisung an das Attribut instantiate erfolgen

    instantiate => q~
        fixedHeader: true,
        stateSave: true,
        dom: 't',
    ~

Die Angabe C<dom: 't'> bewirkt hier, dass das DataTables-Plugin
keine Bedienelemente erzeugt:

=begin html

<p class="sdoc-fig-p">
  <img class="sdoc-fig-img" src="https://raw.github.com/s31tz/Quiq/master/img/quiq_jquery_datatable_example02.png" width="757" height="117" alt="" />
</p>

=end html

Das Programm

    my $tab = Quiq::Database::Row::Object->makeTable(
        [qw/per_id per_vorname per_nachname per_geburtsdatum/],
        qw/1 Rudi Ratlos 1971-04-23/,
        qw/2 Erika Mustermann 1955-03-16/,
        qw/3 Harry Hirsch 1948-07-22/,
        qw/4 Susi Sorglos 1992-10-23/,
    );
    
    my $h = Quiq::Html::Tag->new('html-5');
    
    my $dt = Quiq::JQuery::DataTable->new(
        id => 'personTable',
        class => 'compact stripe hover cell-border',
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
    );
    
    my $html = Quiq::Html::Page->html($h,
        styleSheet => Quiq::JQuery::DataTable->stylesheetUrl,
        styleSheet => q|
            body {
                font-family: sans-serif;
                font-size: 12px;
                color: black;
                background-color: white;
            }
        |,
        body => $dt->html($h),
        javaScript => [
            'https://code.jquery.com/jquery-1.10.2.js',
            Quiq::JQuery::DataTable->pluginUrl,
            $dt->instantiate(q~
                fixedHeader: true,
                stateSave: true,
                dom: 't',
            ~),
        ],
    );

erzeugt den HTML-Code (lange Zeilen umbrochen)

    <!DOCTYPE html>
    
    <html>
    <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8">
      <link rel="stylesheet" type="text/css"
        href="https://cdn.datatables.net/t/dt/dt-1.10.11/datatables.min.css">
      <style type="text/css">
        body {
          font-family: sans-serif;
          font-size: 12px;
          color: black;
          background-color: white;
        }
      </style>
    </head>
    <body>
      <table id="personTable" class="compact stripe hover cell-border"
        cellspacing="0">
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
          <td>Erika</td>
          <td>Mustermann</td>
          <td>1955-03-16</td>
        </tr>
        <tr>
          <td>3</td>
          <td>Harry</td>
          <td>Hirsch</td>
          <td>1948-07-22</td>
        </tr>
        <tr>
          <td>4</td>
          <td>Susi</td>
          <td>Sorglos</td>
          <td>1992-10-23</td>
        </tr>
      </tbody>
      </table>
      <script type="text/javascript"
        src="https://code.jquery.com/jquery-1.10.2.js"></script>
      <script type="text/javascript"
        src="https://cdn.datatables.net/t/dt/dt-1.10.11/datatables.min.js">
      </script>
      <script type="text/javascript">
        jQuery('#personTable').DataTable({
          fixedHeader: true,
          stateSave: true,
          dom: 't',
          columns: [
            {
              className: 'dt-right',
            },{
              className: 'dt-left',
            },{
              className: 'dt-left',
            },{
              className: 'dt-center',
            },
          ],
        });
      </script>
    </body>
    </html>

=head1 METHODS

=head2 Plugin-Code (Klassenmethoden)

=head3 stylesheetUrl() - URL der DataTables CSS-Definitionen

=head4 Synopsis

    $url = $class->stylesheetUrl;
    $url = $class->stylesheetUrl($config);

=head4 Description

Liefere den CDN URL der DataTables CSS-Definitionen.

=head4 Example

    Quiq::JQuery::DataTable->stylesheetUrl;
    =>
    'https://cdn.datatables.net/t/dt/dt-1.10.11/datatables.min.css'

=cut

# -----------------------------------------------------------------------------

sub stylesheetUrl {
    my $class = shift;
    my $config = shift || 'dt-1.10.11';
    return "https://cdn.datatables.net/t/dt/$config/datatables.min.css";
}

# -----------------------------------------------------------------------------

=head3 pluginUrl() - URL des Plugin

=head4 Synopsis

    $url = $class->pluginUrl;
    $url = $class->pluginUrl($config);

=head4 Description

Liefere den CDN URL des DataTables Plugin.

=head4 Example

    Quiq::JQuery::DataTable->pluginUrl;
    =>
    'https://cdn.datatables.net/t/dt/dt-1.10.11/datatables.min.js'

=cut

# -----------------------------------------------------------------------------

sub pluginUrl {
    my $class = shift;
    my $config = shift || 'dt-1.10.11';
    return "https://cdn.datatables.net/t/dt/$config/datatables.min.js";
}

# -----------------------------------------------------------------------------

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
        arguments => undef,
        class => undef,
        columns => [],
        footer => 0,
        id => undef,
        instantiate => 0,
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

    my ($arguments,$class,$footer,$id,$instantiate,$rowCallback,$rowA) =
        $self->get(qw/arguments class footer id instantiate rowCallback rows/);

    # Liste der Kolumnendefinitionen als Hash-Objekte
    my @columns = $self->getColumns;

    # HTML generieren

    if (!@columns) {
        return '';
    }

    my @titles;
    for my $col (@columns) {
        push @titles,$col->title;
    }

    if (!$rowCallback) {
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

    my $html = Quiq::Html::Table::List->html($h,
        allowHtml => 1,
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

    if ($instantiate) {
        $html .= $h->tag('script',
            $self->instantiate,
        );
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head3 instantiate() - Instantiiere Widget in JavaScript

=head4 Synopsis

    $javaScript = $e->instantiate;
    $javaScript = $e->instantiate($json);

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

    my ($id,$arguments) = $self->get(qw/id arguments/);

    $arguments = Quiq::Unindent->string($arguments);
    $arguments .= Quiq::Unindent->string($json);

    my $columns;
    for my $col ($self->getColumns) {
        my $keyVals;
        if (my $type = $col->type) {
            $keyVals .= "type: '$type',\n"; 
        }
        if (my $align = $col->align || 'left') {
            $keyVals .= "className: 'dt-$align',\n"; 
        }
        if (my $searchable = $col->searchable) {
            $keyVals .= "searchable: '$searchable',\n"; 
        }
        if (my $orderable = $col->orderable) {
            $keyVals .= "orderable: '$orderable',\n"; 
        }
        if (my $visible = $col->visible) {
            $keyVals .= "visible: '$visible',\n"; 
        }
        if (my $width = $col->width) {
            $keyVals .= "width: '$width',\n"; 
        }
        if ($keyVals) {
            $keyVals =~ s/^/    /mg;
            $columns .= sprintf "{ // %s\n%s},",$col->title,$keyVals;
        }
        else {
            $columns .= sprintf "{ // %s\n},",$col->title;
        }
    }
    $columns =~ s/^/    /mg;

    $arguments .= "columns: [\n$columns\n],\n";
    $arguments =~ s/^/    /mg;

    return sprintf qq|jQuery('#%s').DataTable({\n%s\n});|,$id,$arguments;
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
            searchable
            visible
            width
        /])->join($h);
    }

    return wantarray? @columns: \@columns;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

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
