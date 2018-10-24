package Prty::Parameters;
use base qw/Prty::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.125;

use Prty::Converter;
use Prty::Hash;
use Encode ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Parameters - Verarbeitung von Programm- und Methodenparametern

=head1 BASE CLASS

L<Prty::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 extract() - Extrahiere Optionen und Argumente

=head4 Synopsis

    # Optionswerte an Variablen zuweisen
    $argA = $class->extract(1,$encoding,\@params,$n,@optRef);
    
    # Optionen und Werte per Optionsobjekt zurückgeben
    ($argA,$opt) = $class->extract(0,$encoding,\@params,$n,@optVal);

=head4 Arguments

=over 4

=item $varMode (0 oder 1)

Der erste Parameter entscheidet, ob die Optionswerte an ein
Optionsobjekt (0) oder an Variablen (1) zugewiesen werden.

=item $encoding

Programm-Parameter müssen ggf. dekodiert werden. Dies geschieht,
wenn mit diesem Parameter ein Encoding vereinbart wird. Sollen die
Parameter nicht dekodiert werden, was bei der Verarbeitung von
Methodenparametern typischerweise der Fall ist, wird C<undef>
angegeben.

=item @params

Parameterliste, z.B. @ARGV oder @_.

=item $n

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

=item $opt

Hash-Objekt mit den Optionen aus @params gemäß @optVal.

=item $argA

Array-Objekt mit den (maximal $n) Argumenten aus @params.

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
in @params, werden also nicht extrahiert. Die Anzahl der Argumente $n
ist eine maximale Anzahl, die unterschritten werden kann.

Es obliegt dem Aufrufer, durch Tests auf @params und @$argA zu
prüfen, ob beim Aufruf des Programms oder der Methode zu viele
Parameter (= @params wurde nicht komplett geleert) oder zu wenige
Parameter (= @$argA enthält nicht genügend Elemente) übergeben wurden.

Eine mögliche Wrapper-Methode für eine finale Parameterverarbeitung,
die bei zu wenig/zu vielen Argumenten oder nicht vereinbarten
Optionen eine Exception wirft:

    sub parameters {
        my ($self,$varMode,$encoding,$paramA,$minArgs,$maxArgs) =
            splice @_,0,6;
    
        my ($argA,$opt) = Prty::Parameters->extract($varMode,
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
    my ($class,$varMode,$encoding,$paramA,$n) = splice @_,0,5;
    # @_: @optVal -or- @optRef

    my @args;

    # Hash mit allen angegebenen Optionen aufbauen. Wert ist entweder
    # eine Variablen-Referenz (VarMode) oder der Defaultwert der Option.
    # Wir können uns die Initialisierung des Options-Hash ersparen,
    # wenn wir im VarMode sind und die Parameterliste leer ist.

    my %opt;
    if (!$varMode || @$paramA) {
        while (@_) {
            my $key = shift;
            $key =~ s/^-+//; # führende Bindestriche entfernen
            $opt{$key} = shift;
        }
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
        if ($noMoreOptions || !defined($param) || $param eq '-' ||
                substr($param,0,1) ne '-') {
            # Parameter ist Argument

            if (!defined($n) || $n > @args) {
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
            $key = Prty::Converter->snakeCaseToCamelCase($key);

            # Existenz der Option prüfen

            if (!exists $opt{$key}) {
                # Option existiert nicht. Wir übergehen die Parameter.

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

    return $varMode? \@args: (\@args,Prty::Hash->new(\%opt));
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.125

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
