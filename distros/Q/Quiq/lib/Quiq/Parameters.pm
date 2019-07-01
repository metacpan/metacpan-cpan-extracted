package Quiq::Parameters;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Converter;
use Quiq::Hash;
use Encode ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Parameters - Verarbeitung von Programm- und Methodenparametern

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Universelle Methode

=head3 extract() - Extrahiere Optionen und Argumente

=head4 Synopsis

    # Options/Property-Werte an Variablen zuweisen
    $argA = $class->extract(1,$properties,$encoding,\@params,
        $maxArgs,@optRef);
    
    # Options/Property-Wertpaare per Optionsobjekt zurückgeben
    ($argA,$opt) = $class->extract(0,$properties,$encoding,\@params,
        $maxArgs,@optVal);

=head4 Arguments

=over 4

=item $varMode (0 oder 1)

Legt fest, ob die Optionswerte an ein Optionsobjekt (0) oder an
Variablen (1) zugewiesen werden.

=item $properties (0 oder 1)

Die Parameter sind Attribut/Wert-Paare, die in @optRef bzw. @optVal
spezifiziert sind. Argumente gibt es nicht.

=item $encoding

Programm-Parameter müssen ggf. dekodiert werden. Dies geschieht,
wenn mit diesem Parameter ein Encoding vereinbart wird. Sollen die
Parameter nicht dekodiert werden, was bei der Verarbeitung von
Methodenparametern typischerweise der Fall ist, wird C<undef>
angegeben.

=item @params

Parameterliste, z.B. @ARGV oder @_.

=item $maxArgs

Anzahl der maximal zu extrahierenden Argumente (Argument =
Parameter, der nicht mit einem Bindestrich beginnt). Die Anzahl
der tatsächlich extrahierten Argumente kann niedriger sein, wenn
weniger Argumente vorhanden sind. Sind mehr Argumente in @params
vorhanden, bleiben die überzähligen Argumente in @params
stehen. C<undef> bedeutet eine unbegrenzte Anzahl.

=item @optVal

Liste der Optionen (Option = Parameter, der mit einem
Bindestrich beginnt) und ihrer Defaultwerte. Optionen und ihre
Werte, die in der Liste nicht vorkommen, werden nicht extrahiert.

=item @optRef

Wie @optVal, nur dass anstelle des Defaultwerts eine
Variablenreferenz angegeben ist. An diese Variable wird der
Optionswert zugewiesen.

=back

=head4 Returns

=over 4

=item $argA

Array-Objekt mit den (maximal $maxArgs) Argumenten aus @params.

=item $opt

Hash-Objekt mit den Optionen aus @params gemäß @optVal.

=back

=head4 Description

Extrahiere Argumente und Optionen aus der Parameterliste @params.
Enthält die Parameterliste mehr Argumente oder Optionen als
vorgegeben sind, bleiben diese in @params stehen. Dies eröffnet
die Möglichkeit, Argumente und Optionen über mehrere
Aufrufebenen sukzessive zu verarbeiten.

B<Fehlerbehandlung>

Die Methode kennt keine Fehler. Überzählige Argumente oder Optionen,
die nicht in der Optionsliste @optVal (bzw. @optRef) vorkommen, bleiben
in @params, werden also nicht extrahiert. Die Anzahl der Argumente
$maxArgs ist eine I<maximale> Anzahl, die unterschritten werden kann.

Es obliegt dem Aufrufer, durch Tests auf @params und @$argA zu
prüfen, ob beim Aufruf des Programms oder der Methode zu viele
Parameter (= @params wurde nicht komplett geleert) oder zu wenige
Parameter (= @$argA enthält nicht genügend Elemente) übergeben wurden.

Eine mögliche Wrapper-Methode für eine finale Parameterverarbeitung,
die bei zu wenig/zu vielen Argumenten oder nicht vereinbarten
Optionen eine Exception wirft:

    sub parameters {
        my ($self,$varMode,$properties,$encoding,$paramA,$minArgs,
            $maxArgs) = splice @_,0,6;
    
        my ($argA,$opt) = Quiq::Parameters->extract($varMode,$properties,
            $encoding,$paramA,$maxArgs,@_);
        if (@$paramA) {
            die "ERROR: Unexpected parameter(s): @$paramA\n";
        }
        elsif (@$argA < $minArgs) {
            die "ERROR: Too few arguments\n";
        }
    
        if ($varMode) {
            return wantarray? @$argA: $argA;
        }
    
        return ($argA,$opt);
    }

=cut

# -----------------------------------------------------------------------------

sub extract {
    my ($class,$varMode,$properties,$encoding,$paramA,$maxArgs) =
        splice @_,0,6;
    # @_: @optVal -or- @optRef

    my @args;

    # Wir können sofort mit einer leeren Argumentliste zurückkehren,
    # wenn die Parameterliste leer ist und wir im VarMode sind.

    if (!@$paramA && $varMode) {
        return \@args;
    }

    # Hash mit allen angegebenen Optionen aufbauen. Wert ist entweder
    # eine Variablen-Referenz (VarMode) oder der Defaultwert der Option.

    my %opt;
    while (@_) {
        my $key = shift;
        $key =~ s/^-+//; # führende Bindestriche entfernen
        $opt{$key} = shift;
    }

    # Parameterliste verarbeiten

    my $noMoreOptions = 0; # Wird gesetzt wenn Parameter '--'

    my $i = 0;
    while ($i < @$paramA) {
        my $param = $paramA->[$i];
        if ($encoding) {
            $param = Encode::decode($encoding,$param);
        }

        my $remove = 0;
        if (!$properties && ($noMoreOptions || !defined($param) ||
                $param eq '-' || substr($param,0,1) ne '-')) {
            # Parameter ist Argument

            if (!defined($maxArgs) || $maxArgs > @args) {
                # Die maximale Argumentanzahl ist noch nicht erreicht.
                # Wir schieben den Parameter von @$paramA nach @args.

                push @args,splice(@$paramA,$i,1);
                next;
            }

            # Die maximale Argumentanzahl ist erreicht.
            # Wir übergehen den Parameter.

            $i++;
            next;
        }
        elsif ($param eq '--') {
            # Alle weiteren Parameter sind Argumente

            $noMoreOptions = 1;
            $remove = 1;
        }
        elsif ($param eq '-h' && exists $opt{'help'}) {
            # Hilfe mit -h ohne Wert

            $opt{'help'} = 1;
            $remove = 1;
        }
        else {
            # Parameter ist Option, beginnt also mit - oder --

            my $key = $param;
            my $dashPrefix = $key =~ s/^(-+)//? $1: '';
            my $val;

            if ($dashPrefix eq '--') {
                # Programm-Option: --KEY=VAL

                ($key,$val) = split /=/,$key,2;
                if (!defined $val) {
                    $val = 1;
                }
                $remove = 1;
            }
            else {
                # Methoden-Option: -KEY,VAL

                $val = $paramA->[$i+1];
                $remove = 2;
            }

            # Eingebettete Bindestriche in Camel Case wandeln
            $key = Quiq::Converter->snakeCaseToCamelCase($key);

            # Existenz der Option prüfen

            if (!exists $opt{$key}) {
                # Option existiert nicht. Wir übergehen den Parameter.

                $i += $remove;
                next;
            }

            # Optionswert setzen. Ist der Wert undef, bleibt der Default.

            if (defined $val) {
                if ($varMode) {
                    ${$opt{$key}} = $val;
                }
                else {
                    $opt{$key} = $val;
                }
            }
        }

        # Parameter aus Argumentliste entfernen

        if ($remove) {
            splice @$paramA,$i,$remove;
        }
    }

    return $varMode? \@args: (\@args,Quiq::Hash->new(\%opt));
}

# -----------------------------------------------------------------------------

=head2 Spezialisierte Methoden

Die nachfolgenden Methoden sind auf Basis der Methode extract()
implementiert. Sie realsieren Vereinfachungen für bestimmte
Anwendungsfälle.

=head3 extractPropertiesToVariables() - Extrahiere Properties und weise sie an Variablen zu

=head4 Synopsis

    $class->extractPropertiesToVariables(\@params,@optRef);

=head4 Arguments

=over 4

=item @params

Parameterliste, z.B. @_.

=item @optRef

Liste der Properties (und Optionen) und ihrer Variablenreferenzen.

=back

=head4 Returns

Nichts.

=head4 Description

Extrahiere Properties (und Optionen) aus der Parameterliste @params.
Enthält die Parameterliste unbekannte Properties (oder Optionen),
wird eine Exception geworfen. Die Methode wird typischerweise
zur Verarbeitung von Methodenparametern genutzt.

=head4 Example

Methode, die eine WikiMedia-Tabelle generiert. Die Tabelleneigenschaften
werden als Property/Wert-Paare übergeben:

    sub table {
        my $self = shift;
        # @_: @keyVal
    
        my $alignA = [];
        my $bodyBackground = '#ffffff';
        my $caption = undef;
        my $rowA = [];
        my $titleBackground = '#e8e8e8';
        my $titleA = [];
        my $valueCb = undef;
    
        Quiq::Parameters->extractPropertiesToVariables(\@_,
            alignments => \$alignA,
            bodyBackground => \$bodyBackground,
            caption => \$caption,
            rows => \$rowA,
            titleBackground => \$titleBackground,
            titles => \$titleA,
            valueCallback => \$valueCb,
        );
        ...
    }

=cut

# -----------------------------------------------------------------------------

sub extractPropertiesToVariables {
    my ($class,$paramA) = splice @_,0,2;

    $class->extract(1,1,undef,$paramA,0,@_);
    if (@$paramA) {
        $class->throw(
            'PARAM-00099: Unexpected parameter(s)',
            Parameters => "@$paramA",
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 extractPropertiesToObject() - Extrahiere Properties und weise sie an Hash-Objekt zu

=head4 Synopsis

    $opt = $class->extractPropertiesToObject(\@params,@propVal);

=head4 Arguments

=over 4

=item @params

Parameterliste, z.B. @_.

=item @propVal

Liste der Properties (und Optionen) und ihrer Defaultwerte.

=back

=head4 Returns

Hash-Objekt mit Eigenschaften (und Optionen)

=head4 Description

Extrahiere Properties (und Optionen) aus der Parameterliste @params.
Enthält die Parameterliste unbekannte Properties (oder Optionen),
wird eine Exception geworfen. Die Methode wird typischerweise
zur Verarbeitung von Methodenparametern genutzt.

=head4 Example

Methode, die eine WikiMedia-Tabelle generiert. Die Tabelleneigenschaften
werden als Property/Wert-Paare übergeben:

    sub table {
        my $self = shift;
        # @_: @keyVal
    
        my $opt = Quiq::Parameters->extractPropertiesToObject(\@_,
            alignments => [],
            bodyBackground => '#ffffff',
            caption => undef,
            rows => [],
            titleBackground => '#e8e8e8',
            titles => [],
            valueCallback => undef,
        );
        ...
    }

=cut

# -----------------------------------------------------------------------------

sub extractPropertiesToObject {
    my ($class,$paramA) = splice @_,0,2;

    my (undef,$opt) = $class->extract(0,1,undef,$paramA,0,@_);
    if (@$paramA) {
        $class->throw(
            'PARAM-00099: Unexpected parameter(s)',
            Parameters => "@$paramA",
        );
    }

    return $opt;
}

# -----------------------------------------------------------------------------

=head3 extractToVariables() - Extrahiere Parameter und weise Optionen Variablen zu

=head4 Synopsis

    @args | $argA = $class->extractToVariables(\@params,$minArgs,$maxArgs,@optRef);

=head4 Arguments

=over 4

=item @params

Parameterliste, z.B. @_.

=item $minArgs

Mindestanzahl an Argumenten.

=item $maxArgs

Maximale Anzahl an Argumenten, C<undef> bedeutet beliebig viele.

=item @optRef

Liste der Optionen und ihrer Variablenreferenzen.

=back

=head4 Returns

=over 4

=item $argA

Referenz auf die Liste der extrahierten Argumente.

=back

=head4 Description

Extrahiere Argumente und Optionen aus der Parameterliste @params.
Enthält die Parameterliste unbekannte Optionen oder zu wenige
oder zu viele Argumente, wird eine Exception geworfen.

=head4 Example

Konstruktor mit einer variablen Anzahl an Argumenten und zwei Optionen:

    sub new {
        my $class = shift;
        # @_: $url,@opt -or- $url,$user,$passw,@opt
    
    
        my $color = 1;
        my $debug = 0;
    
        my $argA = Quiq::Parameters->extractToVariables(\@_,1,3,
            -color => \$color,
            -debug => \$debug,
        );
        my ($url,$user,$password) = @$argA;
        ...
    }

=cut

# -----------------------------------------------------------------------------

sub extractToVariables {
    my ($class,$paramA,$minArgs,$maxArgs) = splice @_,0,4;

    my $argA = $class->extract(1,0,undef,$paramA,$maxArgs,@_);
    if (@$argA < $minArgs) {
        $class->throw(
            'PARAM-00099: not enough arguments',
        );
    }
    elsif (@$paramA) {
        $class->throw(
            'PARAM-00099: Unexpected parameter(s)',
            Parameters => "@_",
        );
    }

    return wantarray? @$argA: $argA;
}

# -----------------------------------------------------------------------------

=head3 extractToObject() - Extrahiere Parameter und speichere Optionen in Objekt

=head4 Synopsis

    ($argA,$opt) = $class->extractToObject(\@params,$minArgs,$maxArgs,@optVal);

=head4 Arguments

=over 4

=item @params

Parameterliste, z.B. @_.

=item $minArgs

Mindestanzahl an Argumenten.

=item $maxArgs

Maximale Anzahl an Argumenten, C<undef> bedeutet beliebig viele.

=item @optVal

Liste der Optionen und ihrer Defaultwerte.

=back

=head4 Returns

=over 4

=item $argA

Referenz auf die Liste der extrahierten Argumente.

=item $opt

Hash-Objekt mit den Optionen aus @params gemäß @optVal.

=back

=head4 Description

Extrahiere Argumente und Optionen aus der Parameterliste @params.
Enthält die Parameterliste unbekannte Optionen oder zu wenige
oder zu viele Argumente, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub extractToObject {
    my ($class,$paramA,$minArgs,$maxArgs) = splice @_,0,4;

    my ($argA,$opt) = $class->extract(0,0,undef,$paramA,$maxArgs,@_);
    if (@$argA < $minArgs) {
        $class->throw(
            'PARAM-00099: not enough arguments',
        );
    }
    elsif (@$paramA) {
        $class->throw(
            'PARAM-00099: Unexpected parameter(s)',
            Parameters => "@_",
        );
    }

    return ($argA,$opt);
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
