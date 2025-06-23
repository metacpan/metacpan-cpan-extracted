# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Json::Code - Erzeuge JSON-Code in Perl

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

=head2 Klasse laden und Objekt instantiieren

  use Quiq::Json::Code;
  
  my $j = Quiq::Json::Code->new;

=head2 JSON-Objekt via object()

  $json = $j->object(
      pi => 3.14159,
      str => 'Hello world!',
      bool => \'true',
      obj => $j->object(
          id => 4711,
          name => 'Wall',
          numbers => [1..5],
      ),
      min => undef,
  );

erzeugt

  {
      pi: 3.14159,
      str: 'Hello world!',
      bool: true,
      obj: {
          id: 4711,
          name: 'Wall',
          numbers: [1,2,3,4,5],
      },
      min: undefined,
  }

Bei der Methode $j->L<object|"object() - Erzeuge Code für JSON-Objekt">()

=over 2

=item *

bleibt die Reihenfolge der Schlüssel/Wert-Paare erhalten

=item *

jedes Schlüssel/Wert-Paar beginnt auf einer eigenen Zeile und
wird eingerückt

=back

=head2 JSON-Datenstruktur via encode()

  $json = $j->encode({
      pi => 3.14159,
      str => 'Hello world!',
      bool => \'true',
      obj => {
          id => 4711,
          name => 'Wall',
          numbers => [1..5],
      },
      min => undef,
  });

erzeugt

  {bool:true,min:undefined,obj:{id:4711,name:'Wall',numbers:[1,2,3,4,5]},pi:3.14159,str:'Hello world!'}

Bei der Methode $j->L<encode|"encode() - Wandele Perl- in JavaScript-Datenstruktur">()

=over 2

=item *

werden die Schlüssel/Wert-Paare von JSON-Objekten
alphanumerisch sortiert (bei {...} ist die Reihenfolge sonst
undefiniert)

=item *

gibt es keine Einrückung oder Leerraum nach dem :

=back

=head1 DESCRIPTION

Die Klasse ermöglicht die präzise Erzeugung von JavaScript-Datenstrukturen
aus Perl heraus. Der Fokus liegt nicht auf der Übermittlung von Daten,
sondern auf der Einsetzung der Strukturen in JavaScript-Quelltexte.
Insofern gehen die Möglichketen der Klasse über JSON hinaus.
Die JavaScript-Klasse Chart.js arbeitet z.B. mit einer komplexen
Datenstruktur. Diese Struktur aus Perl heraus dynamisch erzeugen zu
können, war der Anlass für die Entwicklung dieser Klasse.
Das Perl-Modul JSON ist für diese Zwecke nicht geeignet, denn z.B.
kann eine JavaScript-Datenstruktur Referenzen auf (inline definierte)
JavaScript-Funktionen enthalten. Dies ist mit dieser Klasse möglich.
Weitere Vorteile dieser Klasse:

=over 2

=item *

die Reihenfolge von Objektattributen bleibt erhalten

=item *

Werte können literal eingesetzt werden (z.B. Funktionsdefinionen,
spezielle Werte wie C<true>, C<false>, C<null> usw.)

=item *

lesbarerer Code

=back

=head1 EXAMPLE

Ein realer Fall. Die Erzeugung einer Konfiguration für Chart.js. Wir
nutzen hier die Aliase o() und c() für die Methoden object() und code().

  my @dataSets;
  my $title = 'Windspeed';
  my $unit = 'm/s';
  my $tMin = undef;
  my $tMax = undef;
  my $yMin = 0;
  my $yMax = undef;
  
  $json = $j->o(
      type => 'line',
      data => $j->o(
          datasets => \@dataSets,
      ),
      options => $j->o(
          maintainAspectRatio => \'false',
          title => $j->o(
              display => \'true',
              text => $title,
              fontSize => 16,
              fontStyle => 'normal',
          ),
          tooltips => $j->o(
              intersect => \'false',
              displayColors => \'false',
              backgroundColor => 'rgb(0,0,0,0.6)',
              titleMarginBottom => 2,
              callbacks => $j->o(
                  label => $j->c(qq~
                      function(tooltipItem,data) {
                          var i = tooltipItem.datasetIndex;
                          var label = data.datasets[i].label || '';
                          if (label)
                              label += ': ';
                          label += tooltipItem.value + ' $unit';
                          return label;
                      }
                  ~),
              ),
          ),
          legend => $j->o(
              display => \'false',
          ),
          scales => $j->o(
              xAxes => [$j->o(
                  type => 'time',
                  ticks => $j->o(
                      minRotation => 30,
                      maxRotation => 60,
                  ),
                  time => $j->o(
                      min => $tMin,
                      max => $tMax,
                      minUnit => 'second',
                      displayFormats => $j->o(
                          second => 'YYYY-MM-DD HH:mm:ss',
                          minute => 'YYYY-MM-DD HH:mm',
                          hour => 'YYYY-MM-DD HH',
                          day => 'YYYY-MM-DD',
                          week => 'YYYY-MM-DD',
                          month => 'YYYY-MM',
                          quarter => 'YYYY [Q]Q',
                          year => 'YYYY',
                      ),
                      tooltipFormat => 'YYYY-MM-DD HH:mm:ss',
                  ),
              )],
              yAxes => [$j->o(
                  ticks => $j->o(
                      min => $yMin,
                      max => $yMax,
                  ),
                  scaleLabel => $j->o(
                      display => \'true',
                      labelString => $unit,
                  ),
              )],
          ),
      ),
  );

erzeugt

  {
      type: 'line',
      data: {
          datasets: [],
      },
      options: {
          maintainAspectRatio: false,
          title: {
              display: true,
              text: 'Windspeed',
              fontSize: 16,
              fontStyle: 'normal',
          },
          tooltips: {
              intersect: false,
              displayColors: false,
              backgroundColor: 'rgb(0,0,0,0.6)',
              titleMarginBottom: 2,
              callbacks: {
                  label: function(tooltipItem,data) {
                      var i = tooltipItem.datasetIndex;
                      var label = data.datasets[i].label || '';
                      if (label)
                          label += ': ';
                      label += tooltipItem.value + ' m/s';
                      return label;
                  },
              },
          },
          legend: {
              display: false,
          },
          scales: {
              xAxes: [{
                  type: 'time',
                  ticks: {
                      minRotation: 30,
                      maxRotation: 60,
                  },
                  time: {
                      min: undefined,
                      max: undefined,
                      minUnit: 'second',
                      displayFormats: {
                          second: 'YYYY-MM-DD HH:mm:ss',
                          minute: 'YYYY-MM-DD HH:mm',
                          hour: 'YYYY-MM-DD HH',
                          day: 'YYYY-MM-DD',
                          week: 'YYYY-MM-DD',
                          month: 'YYYY-MM',
                          quarter: 'YYYY [Q]Q',
                          year: 'YYYY',
                      },
                      tooltipFormat: 'YYYY-MM-DD HH:mm:ss',
                  },
              }],
              yAxes: [{
                  ticks: {
                      min: 0,
                      max: undefined,
                  },
                  scaleLabel: {
                      display: true,
                      labelString: 'm/s',
                  },
              }],
          },
      },
  }

=cut

# -----------------------------------------------------------------------------

package Quiq::Json::Code;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Unindent;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Instantiierung

=head3 new() - Konstruktor

=head4 Synopsis

  $j = $class->new(@keyVal);

=head4 Attributes

=over 4

=item indent => $n (Default: 4)

Tiefe der Einrückung.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        indent => 4,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 code() - Erzeuge Sourcecode für JSON-Datenstruktur

=head4 Synopsis

  $code = $j->code($text);    # Scalar-Kontext
  ($codeS) = $j->code($text); # List-Kontext

=head4 Alias

c()

=head4 Arguments

=over 4

=item $text

Sourcecode, typischerweise mehrzeiliger JavaScript-Code.

=back

=head4 Returns

Sourecode (String). Im List-Kontext eine Referenz auf den Code.

=head4 Description

Erzeuge Sourcecode, der in eine JSON-Datenstruktur eingebettet
werden kann, und liefere diesen zurück. Der Code

=over 2

=item *

erhält die richtige Einrückung

=item *

wird "as is" eingebettet, also nicht gequotet

=back

=head4 Example

Weise Funktionsreferenz an Objekt-Attribut zu

  $unit = 'm/s';
  $json = $j->object(
      label => $j->code(qq~
          function(tooltipItem,data) {
              var i = tooltipItem.datasetIndex;
              var label = data.datasets[i].label || '';
              if (label)
                  label += ': ';
              label += tooltipItem.value + ' $unit';
              return label;
          }
      ~),
  ),

liefert

  {
      label: function(tooltipItem,data) {
          var i = tooltipItem.datasetIndex;
          var label = data.datasets[i].label || '';
          if (label)
              label += ': ';
          label += tooltipItem.value + ' m/s';
          return label;
      },
  }

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$text) = @_;
    my $code = Quiq::Unindent->trim($text);
    return wantarray? \$code: $code;
}

{
    no warnings 'once';
    *c = \&code;
}

# -----------------------------------------------------------------------------

=head3 encode() - Wandele Perl- in JavaScript-Datenstruktur

=head4 Synopsis

  $json = $j->encode($scalar);

=head4 Arguments

=over 4

=item $scalar

Skalarer Wert: undef, \0, \1, Number, String, String-Referenz,
Array-Referenz, Hash-Referenz.

=back

=head4 Returns

JSON-Code (String)

=head4 Description

Wandele $scalar nach JSON und liefere den resultierenden Code zurück.
Die Übersetzung erfolgt (rekursiv) nach folgenden Regeln:

=over 4

=item undef

Wird abgebildet auf: C<undefined>. In einem Objekt wird das
betreffende Attribut weggelassen.

=item \1 oder \'true'

Wird abgebildet auf: C<true>

=item \0 oder \'false'

Wird abgebildet auf: C<false>

=item NUMBER

Wird unverändert übernommen: NUMBER

=item STRING

Wird abgebildet auf: 'STRING'

=item STRING_REF

Wird abgebildet auf: STRING (literale Einsetzung von STRING)

Dies ist z.B. nützlich, wenn ein Teil der Datenstruktur
abweichend formatiert werden soll.

=item ARRAY_REF

Wird abgebildet auf: [ELEMENT1,ELEMENT2,...]

=item HASH_REF

Wird abgebildet auf: {KEY1:VALUE1,KEY2:VALUE2,...}. Im Falle des
Werts undef, wird das betreffende Schlüssel/Wert-Paar weggelassen.

=back

=cut

# -----------------------------------------------------------------------------

sub encode {
    my ($self,$arg) = @_;

    my $json = '';

    my $refType = Scalar::Util::reftype($arg);
    if (!defined $refType) {
        if (!defined $arg) {
            $json = 'undefined';
        }
        elsif (Scalar::Util::looks_like_number($arg)) {
            $json = $arg;
        }
        else {
            $json = "'$arg'";
        }
    }
    elsif ($refType eq 'SCALAR') {
        if ($$arg eq '1') {
            $json = 'true';
        }
        elsif ($$arg eq '0') {
            $json = 'false';
        }
        else {
            $json = $$arg;
        }
    }
    elsif ($refType eq 'ARRAY') {
        for (my $i = 0; $i < @$arg; $i++) {
            if ($json ne '') {
                $json .= ',';
            }
            $json .= $self->encode($arg->[$i]);
        }
        $json = "[$json]";
    }
    elsif ($refType eq 'HASH') {
        for my $key (sort keys %$arg) {
            my $val = $arg->{$key} // next; # Attribut streichen, wenn undef
            if ($json) {
                $json .= ',';
            }
            $json .= $self->key($key);
            $json .= ':'.$self->encode($val);
        }
        $json = "{$json}";
    }
    else {
        $self->throw(
            'JSON-00001: Unknown data type',
            Arg => $arg,
            Type => $refType,
        );
    }

    return $json;
}

# -----------------------------------------------------------------------------

=head3 object() - Erzeuge Code für JSON-Objekt

=head4 Synopsis

  $json = $j->object(@opt,@keyVal);    # Scalar-Kontext
  ($jsonS) = $j->object(@opt,@keyVal); # List-Kontext

=head4 Alias

o()

=head4 Arguments

=over 4

=item @keyVal

Liste der Schlüssel/Wert-Paare

=back

=head4 Options

=over 4

=item -indent => $bool (Default: 1)

Rücke die Elemente des Hash ein.

=back

=head4 Returns

JSON-Code (String). Im List-Kontext eine Referenz auf den Code.

=head4 Description

Erzeuge den Code für ein JSON-Objekt mit den Attribut/Wert-Paaren
@keyVal und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub object {
    my $self = shift;
    # @_: @keyVal

    # Optionen

    my $indent = 1;

    while (@_) {
        if (substr($_[0],0,1) ne '-') {
            # Implizites Ende der Optionsliste
            last;
        }
        my $opt = shift;
        if ($opt eq '-') {
            # Explizites Ende der Optionsliste
            last;
        }
        elsif ($opt eq '-indent') {
            $indent = shift;
        }
        else {
            $self->throw(
                'JSON-00001: Unknown option',
                Option => $opt,
                Value => shift,
            );
        }
    }

    my $json = '';
    if ($indent) {
        while (@_) {
            my $key = shift;
            my $val = shift // next;
            if ($json) {
                $json .= "\n";
            }
            $json .= sprintf '%s: %s,',$self->key($key),$self->encode($val);
        }
        if ($json) {
            my $indent = ' ' x $self->{'indent'};
            $json =~ s/^/$indent/mg;
            $json = "{\n$json\n}";
        }
        else {
            $json = '{}';
        }
    }
    else {
        while (@_) {
            my $key = shift;
            my $val = shift // next;
            if ($json) {
                $json .= ',';
            }
            $json .= $self->key($key).':'.$self->encode($val);
        }
        $json = "{$json}";
    }

    return wantarray? \$json: $json;
}

{
    no warnings 'once';
    *o = \&object;
}

# -----------------------------------------------------------------------------

=head2 Hilfsmethoden

=head3 key() - Schlüssel eines JSON-Objekts

=head4 Synopsis

  $str = $j->key($key);

=head4 Arguments

=over 4

=item $key

Schlüssel.

=back

=head4 Returns

String

=head4 Description

Erzeuge den Code für den Schlüssel $key eines JSON-Objekts und
liefere diesen zurück. Enthält der Schlüssel nur Zeichen, die
in einem JavaScript-Bezeichner vorkommen dürfen, wird er unverändert
geliefert, ansonsten wird er in einfache Anführungsstriche eingefasst.

=head4 Example

Schlüssel aus dem Zeichenvorrat eines JavaScript-Bezeichners:

  $str = $j->Quiq::Json::Code('borderWidth');
  ==>
  "borderWidth"

Schlüssel mit Zeichen, die nicht in einem JavaScript-Bezeichner vorkommen:

  $str = $j->Quiq::Json::Code('border-width');
  ==>
  "'border-width'"

=cut

# -----------------------------------------------------------------------------

sub key {
    my ($self,$key) = @_;
    return $key =~ /\W/? "'$key'": $key;
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
