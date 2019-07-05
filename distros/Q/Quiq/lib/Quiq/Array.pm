package Quiq::Array;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Encode ();
use Quiq::Reference;
use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Array - Operationen auf Arrays

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Array. Jede der Methoden kann
sowohl auf ein Objekt der Klasse als auch per Aufruf als Klassenmethode
auf ein ungeblesstes Perl-Array angewendet werden.

Aufruf als Objektmethode:

    $arr->$meth(...);

Aufruf als Klassenmethode:

    $class->$meth(\@arr, ...);

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $arr = $class->new;
    $arr = $class->new(\@arr);

=head4 Description

Instantiiere ein Array-Objekt und liefere eine Referenz auf dieses
Objekt zurück. Ohne Angabe einer Array-Referenz wird ein leeres
Array-Objekt instantiiert.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $arr = shift || [];
    return bless $arr,$class;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 different() - Vergleiche Array gegen Array

=head4 Synopsis

    ($only1A,$only2A,$bothA) = $arr1->different(\@arr2);
    ($only1A,$only2A,$bothA) = $class->different(\@arr1,\@arr2);

=head4 Alias

compare()

=head4 Description

Vergleiche die Elemente der Arrays @$arr1 und @arr2 und liefere
Referenzen auf drei Arrays (Mengen) zurück:

=over 4

=item $only1A:

Referenz auf die Liste der Elemente, die nur in @arr1
enthalten sind.

=item $only2A:

Referenz auf die Liste der Elemente, die nur in @arr2
enthalten sind.

=item $bothA:

Referenz auf die Liste der Elemente, die sowohl in @arr1
als auch in @arr2 enthalten sind.

=back

Die drei Ergebnislisten sind als Mengen zu sehen: Jedes Element taucht
in einer der drei Listen höchstens einmal auf, auch wenn es in den
Eingangslisten mehrfach vorkommt.

Die gelieferten Arrays sind auf die Klasse geblesst.

=head4 Example

=over 2

=item *

Verwalte Objekte auf Datenbank

Die Methode ist nützlich, wenn eine Menge von Objekten
auf einer Datenbank identisch zu einer Menge von Elementen
einer Benutzerauswahl gehalten werden soll. Die Objekte werden
durch ihre Objekt-Id identifiziert. Die Liste der
Datenbankobjekte sei @idsDb und die Liste der Objekte der
Benutzerauswahl sei @idsUser. Dann liefert der Aufruf

    ($idsNew,$idsDel) = $idsUserA->different(\@idsDb);

mit @$idsNew die Liste der zur Datenbank hinzuzufügenden Objekte und
mit @$idsDel die Liste der von der Datenbank zu entfernenden Objekte.
Die Liste der identischen Objekte wird hier nicht benötigt.

=item *

Prüfe zwei Arrays auf Identiät

Prüfe, ob zwei Arrays die gleichen Elemente enthalten, aber nicht
unbedingt in der gleichen Reihenfolge:

    ($only1,$only2) = $arr1->different(\@arr2);
    if (!@$only1 && !@$only2) {
        # @$arr1 und @$arr2 enthalten die gleichen Elemente
    }

=back

=cut

# -----------------------------------------------------------------------------

sub different {
    my $arr1 = CORE::shift;
    $arr1 = CORE::shift if !ref $arr1; # Klassenmethode
    my $arr2 = CORE::shift;
            
    # Hash mit den Elementen von @$arr1

    my (%arr1,%arr2);
    @arr1{@$arr1} = (1) x @$arr1;
    @arr2{@$arr2} = (1) x @$arr2;

    my (%seen,@arr1,@arr2,@arr);
    for my $e (@$arr1,@$arr2) {
        next if $seen{$e}++;
        push @{$arr1{$e}? $arr2{$e}? \@arr: \@arr1: \@arr2},$e;
    }

    my $class = ref $arr1;

    return (
        bless(\@arr1,$class),
        bless(\@arr2,$class),
        bless(\@arr,$class),
    );
}

{
    no warnings 'once';
    *compare = \&different;
}

# -----------------------------------------------------------------------------

=head3 decode() - Dekodiere Array

=head4 Synopsis

    $arr->decode($encoding);
    $class->decode(\@arr,$encoding);

=head4 Description

Dekodiere die Elemente des Arrays gemäß Encoding $encoding.

=cut

# -----------------------------------------------------------------------------

sub decode {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $encoding = CORE::shift;

    @$arr = map {Encode::decode($encoding,$_)} @$arr;

    return;
}

# -----------------------------------------------------------------------------

=head3 exists() - Teste, ob Element existiert

=head4 Synopsis

    $bool = $arr->exists($str);
    $bool = $class->exists(\@arr,$str);

=head4 Description

Durchsuche $arr nach Element $str. Kommt $str in $arr vor,
liefere "wahr", sonst "falsch". Vergleichsoperator ist eq.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $str = CORE::shift;

    for (my $i = 0; $i < @$arr; $i++) {
        if ($arr->[$i] eq $str) {
            return 1;
        }
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 extractKeyVal() - Extrahiere Paar, liefere Wert

=head4 Synopsis

    $val = $arr->extractKeyVal($key);
    $val = $arr->extractKeyVal($key,$step);
    $val = $class->extractKeyVal(\@arr,$key);
    $val = $class->extractKeyVal(\@arr,$key,$step);

=head4 Alias

extractPair()

=head4 Description

Durchsuche @arr nach Element $key und liefere das folgende
Element $val. Beide Elemente werden aus @arr entfernt. Kommt $key
in @arr nicht vor, liefere undef und lasse @arr unverändert.
Vergleichsoperator ist eq. Per Default wird das Array paarweise
durchsucht, d.h. der Defaultwert für $step ist 2. Wird $step auf
1 gesetzt, kann jedes Element den gesuchten $key enthalten.

=cut

# -----------------------------------------------------------------------------

sub extractKeyVal {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $key = CORE::shift;
    my $step = CORE::shift // 2;

    for (my $i = 0; $i < @$arr; $i += $step) {
        if ($arr->[$i] eq $key) {
            return scalar CORE::splice @$arr,$i,2;
        }
    }

    return undef;
}

{
    no warnings 'once';
    *extractPair = \&extractKeyVal;
}

# -----------------------------------------------------------------------------

=head3 eq() - Vergleiche Arrays per eq

=head4 Synopsis

    $bool = $arr->eq(\@arr);
    $bool = $class->eq(\@arr1,\@arr2);

=head4 Description

Vergleiche @arr1 und @arr2 elementweise per eq. Liefere "wahr",
wenn alle Elemente identisch sind, andernfalls "falsch".

Sind zwei Elemente undef, gelten sie als identisch.

=cut

# -----------------------------------------------------------------------------

sub eq {
    my $arr1 = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $arr2 = CORE::shift;

    return 0 if $#$arr1 != $#$arr2;

    my $l = @$arr1;
    for (my $i = 0; $i < $l; $i++) {
        my $val1 = $arr1->[$i];
        my $val2 = $arr2->[$i];

        # Wenn einer der Werte undefiniert ist,
        # können wir nicht mit den normalen
        # Operatoren vergleichen

        if (!defined $val1 || !defined $val2) {
            return 0 if defined $val1 || defined $val2;
            next;
        }
        return 0 if $val1 ne $val2;
    }

    return 1;
}

# -----------------------------------------------------------------------------

=head3 findPairValue() - Liefere Wert zu Schlüssel

=head4 Synopsis

    $val = $arr->findPairValue($key);
    $val = $class->findPairValue(\@arr,$key);

=head4 Returns

Wert oder C<undef>

=head4 Description

Durchsuche $arr paarweise nach Element $key. Kommt es vor, liefere
dessen Wert. Kommt es nicht vor, liefere undef. Vergleichsoperator
ist eq.

=cut

# -----------------------------------------------------------------------------

sub findPairValue {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $key = CORE::shift;

    for (my $i = 0; $i < @$arr; $i += 2) {
        if ($arr->[$i] eq $key) {
            return $arr->[$i+1];
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 index() - Suche Element

=head4 Synopsis

    $i = $arr->index($val);
    $i = $class->index(\@arr,$val);

=head4 Description

Durchsuche @arr vom Anfang her nach Element $val und liefere
dessen Index zurück. Kommt $str in @arr nicht vor, liefere -1.
Vergleichsoperator ist eq.

=cut

# -----------------------------------------------------------------------------

sub index {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $val = CORE::shift;

    for (my $i = 0; $i < @$arr; $i++) {
        if ($arr->[$i] eq $val) {
            return $i;
        }
    }

    return -1;
}

# -----------------------------------------------------------------------------

=head3 last() - Liefere letztes Element

=head4 Synopsis

    $e = $arr->last;
    $e = $class->last(\@arr);

=cut

# -----------------------------------------------------------------------------

sub last {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    return $arr->[-1];
}

# -----------------------------------------------------------------------------

=head3 maxLength() - Länge des längsten Elements

=head4 Synopsis

    $l = $arr->maxLength;
    $l = $class>maxLength(\@arr);

=head4 Description

Ermittele die Länge des längsten Arrayelements und liefere diese
zurück.

=cut

# -----------------------------------------------------------------------------

sub maxLength {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my $max = 0;
    for (@$arr) {
        my $l = length;
        $max = $l if $l > $max;
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head3 pick() - Liefere Elemente nach Position heraus

=head4 Synopsis

    $arr2 | @arr = $class->pick(\@arr,$n,$m);
    $arr2 | @arr = $class->pick(\@arr,$n);
    $arr2 | @arr = $arr->pick($n,$m);
    $arr2 | @arr = $arr->pick($n);

=head4 Description

Picke jedes $n-te Array-Element ab Positon $m heraus, bilde aus diesen
Elementen ein neues Array und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub pick {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $n = CORE::shift;
    my $m = CORE::shift || 0;

    my @arr;
    for (my $i = $m; $i < @$arr; $i += $n) {
        CORE::push @arr,$arr->[$i];
    }
    if (wantarray) {
       return @arr;
    }
    if (my $class = ref $arr) {
       return bless \@arr,$class;
    }

    return \@arr;
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Element am Ende hinzu

=head4 Synopsis

    $arr->push($e);
    $class->push(\@arr,$e);

=cut

# -----------------------------------------------------------------------------

sub push {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $e = CORE::shift;

    CORE::push @$arr,$e;

    return;
}

# -----------------------------------------------------------------------------

=head3 select() - Selektiere Array-Elemente

=head4 Synopsis

    $arr2|@arr2 = $arr->select($test);
    $arr2|@arr2 = $class->select(\@arr,$test);

=head4 Description

Wende Test $test auf alle Arrayelemente an und liefere ein Array mit
den Elementen zurück, die den Test erfüllen.

Folgende Arten von Tests sind möglich:

=over 4

=item Regex qr/REGEX/

Wende Regex-Test auf jedes Element an.

=item Code-Referenz sub { CODE }

Wende Subroutine-Test auf jedes Element an. Als erster
Parameter wird das zu testende Element übergeben. Die
Subroutine muss einen boolschen Wert liefern.

=back

=cut

# -----------------------------------------------------------------------------

sub select {
    my ($class,$arr) = Quiq::Object->this(CORE::shift); # Wir brauchen $class
    $arr ||= CORE::shift;
    my $test = CORE::shift;

    my @arr;
    if (Quiq::Reference->isCodeRef($test)) {
        for (@$arr) {
            CORE::push @arr,$_ if $test->($_);
        }
    }
    else {
        for (@$arr) {
            CORE::push @arr,$_ if /$test/;
        }
    }

    return wantarray? @arr: bless \@arr,$class;
}

# -----------------------------------------------------------------------------

=head3 shuffle() - Verwürfele Array-Elemente

=head4 Synopsis

    $arr->shuffle;
    $arr->shuffle($factor);
    $class->shuffle(\@arr);
    $class->shuffle(\@arr,$factor);

=head4 Arguments

=over 4

=item @arr

Das zu mischende Array.

=item $factor (Default: 100)

Faktor für die Anzahl der Vertauschungsoperationen. Es werden
I<Arraygröße> * $factor Vertauschungsoperationen ausgeführt.

=back

=head4 Description

Mische die Elemente des Array @arr, d.h. bringe sie in eine
zufällige Reihenfolge. Die Operation wird in-place ausgeführt.

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub shuffle {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $factor = CORE::shift || 100;

    my $size = @$arr;
    for (my $i = 0; $i < $factor; $i++) {
        for (my $j = 0; $j < $size; $j++) {
            my $k = int rand $size;
            @$arr[$k,$j] = @$arr[$j,$k];
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 sort() - Sortiere Elemente alphanumerisch

=head4 Synopsis

    $arr | @arr = $arr->sort;
    $arr | @arr = $class->sort(\@arr);

=head4 Description

Sortiere die Elemente des Array alphanumerisch.

Im Skalar-Kontext sortiere die Elemente "in place" und liefere
die Array-Referenz zurück (Method-Chaining).

Im List-Kontext liefere die Elemente sortiert zurück, ohne
den Inhalt des Array zu verändern.

=cut

# -----------------------------------------------------------------------------

sub sort {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    if (wantarray) {
        return sort @$arr;
    }

    @$arr = sort @$arr;
    return $arr;
}

# -----------------------------------------------------------------------------

=head3 toHash() - Erzeuge Hash aus Array

=head4 Synopsis

    %hash | $hashH = $arr->toHash;
    %hash | $hashH = $arr->toHash($val);
    %hash | $hashH = $class->toHash(\@arr);
    %hash | $hashH = $class->toHash(\@arr,$val);

=head4 Arguments

=over 4

=item @$arr, @arr

Array.

=item $val (Default: 1)

Wert.

=back

=head4 Returns

Hash. Im Skalarkontext wird eine Referenz auf den Hash geliefert.

=head4 Description

    Erzeuge aus Array @$arr bzw. @arr einen Hash mit den Werten des Array
    als Schlüssel und dem Wert $val als deren Werte und liefere diesen zurück.
    Ist $val nicht angegeben, werden alle Werte des Hash auf 1 gesetzt.

=cut

# -----------------------------------------------------------------------------

sub toHash {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $val = shift // 1;

    # FIXME: Ist das schneller?
    # my %hash;
    # @hash{@$arr} = ($val) x @$arr;

    my %hash = map {$_=>$val} @$arr;

    return wantarray? %hash: \%hash;
}

# -----------------------------------------------------------------------------

=head2 Numerische Operationen

=head3 gcd() - Größter gemeinsamer Teiler

=head4 Synopsis

    $gcd = $arr->%METHOD;
    $gcd = $class->gcd(\@arr);

=head4 Description

Berechne den größten gemeinsamen Teiler (greatest common divisor)
der natürlichen Zahlen in Array @$arr bzw. @arr und liefere diesen
zurück. Ist das Array leer, wird C<undef> geliefert. Enthält das
Array nur ein Element, wird dessen Wert geliefert.

=cut

# -----------------------------------------------------------------------------

sub gcd {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my $gcd;
    if (@$arr) {
        $gcd = $arr->[0];
        for (my $i = 1; $i < @$arr; $i++) {
            $gcd = Quiq::Math->gcd($gcd,$arr->[$i]);
        }
    }
    
    return $gcd;
}

# -----------------------------------------------------------------------------

=head3 min() - Ermittele numerisches Minimum

=head4 Synopsis

    $min = $arr->min;
    $min = $class->min(\@arr);

=head4 Description

Ermittele die kleinste Zahl und liefere diese zurück. Enthält
$arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub min {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my $min;
    for my $x (@$arr) {
        $min = $x if !defined $min || $x < $min;
    }

    return $min;
}

# -----------------------------------------------------------------------------

=head3 max() - Ermittele numerisches Maximum

=head4 Synopsis

    $max = $arr->max;
    $max = $class->max(\@arr);

=head4 Description

Ermittele die größte Zahl und liefere diese zurück. Enthält $arr
keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub max {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my $max;
    for my $x (@$arr) {
        $max = $x if !defined $max || $x > $max;
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head3 minMax() - Ermittele numerisches Minimum und Maximum

=head4 Synopsis

    ($min,$max) = $arr->minMax;
    ($min,$max) = $class->minMax(\@arr);

=head4 Description

Ermittele die kleinste und die größte Zahl und liefere die beiden Werte
zurück. Enthält $arr keine Elemente, wird jeweils C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub minMax {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my ($min,$max);
    for my $x (@$arr) {
        $min = $x if !defined $min || $x < $min;
        $max = $x if !defined $max || $x > $max;
    }

    return ($min,$max);
}

# -----------------------------------------------------------------------------

=head3 meanValue() - Berechne Mittelwert

=head4 Synopsis

    $x = $arr->meanValue;
    $x = $class->meanValue(\@arr);

=head4 Description

Berechne das Arithmetische Mittel und liefere dieses
zurück. Enthält $arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub meanValue {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    return undef if !@$arr;

    my $sum = 0;
    for my $x (@$arr) {
        $sum += $x;
    }

    return $sum/@$arr;
}

# -----------------------------------------------------------------------------

=head3 standardDeviation() - Berechne Standardabweichung

=head4 Synopsis

    $x = $arr->standardDeviation;
    $x = $class->standardDeviation(\@arr);

=head4 Description

Berechne die Standardabweichung und liefere diese zurück. Enthält
$arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub standardDeviation {
    my ($class,$arr) = Quiq::Object->this(CORE::shift); # Wir brauchen $class
    $arr ||= CORE::shift;

    return undef if !@$arr;
    return sqrt $class->variance($arr);
}

# -----------------------------------------------------------------------------

=head3 variance() - Berechne Varianz

=head4 Synopsis

    $x = $arr->variance;
    $x = $class->variance(\@arr);

=head4 Description

Berechne die Varianz und liefere diese zurück. Enthält das Array
keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub variance {
    my ($class,$arr) = Quiq::Object->this(CORE::shift); # Wir brauchen $class
    $arr ||= CORE::shift;

    return undef if !@$arr;
    return 0 if @$arr == 1;

    my $meanVal = $class->meanValue($arr);

    my $sum = 0;
    for my $x (@$arr) {
        $sum += ($meanVal-$x)**2;
    }

    return $sum/(@$arr-1);
}

# -----------------------------------------------------------------------------

=head3 median() - Ermittele den Median

=head4 Synopsis

    $x = $arr->median;
    $x = $class->median(\@arr);

=head4 Description

Ermittele den Median und liefere diesen zurück. Enthält das Array
keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub median {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;

    my $size = @$arr;
    if ($size == 0) {
        # Array enthält keine Elemente
        return undef;
    }

    my @arr = sort {$a <=> $b} @$arr;
    my $idx = int $size/2;
    if ($size%2) {
        # Ungerade Anzahl Elemente. Wir liefern das mittlere Element.
        return $arr[$idx];
    }

    # Gerade Anzahl Elemente. Wir liefern den Mittelwert
    # der beiden mittleren Elemente.

    return ($arr[$idx-1]+$arr[$idx])/2;
}

# -----------------------------------------------------------------------------

=head2 Dump/Restore

=head3 dump() - Erzeuge einzeilige, externe Repräsentation

=head4 Synopsis

    $str = $arr->dump;
    $str = $arr->dump($colSep);
    $str = $class->dump(\@arr);
    $str = $class->dump(\@arr,$colSep);

=head4 Description

Liefere eine einzeilige, externe Repräsentation für Array $arr bzw. @arr
im Format

    elem0|elem1|...|elemN

Die Array-Elemente werden durch "|" (bzw. $colSep) getrennt. In den
Elementen werden folgende Wandlungen vorgenommen:

    undef    -> '' (undef wird zu Leerstring)
    \        -> \\ (Backslash wird verdoppelt)
    $colSep  -> \!
    LF       -> \n
    CR       -> \r

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $arr = ref $_[0]? CORE::shift: CORE::splice @_,0,2;
    my $colSep = CORE::shift // '|';

    my $regex = qr/\Q$colSep/;

    my $str;
    for (@$arr) {
        if (!defined) {
            $_ = '';
        }

        s/\\/\\\\/g;
        s/$regex/\\!/g;
        s/\n/\\n/g;
        s/\r/\\r/g;

        if (defined $str) {
            $str .= $colSep;
        }
        $str .= $_;
    }

    return defined $str? $str: '';
}

# -----------------------------------------------------------------------------

=head3 restore() - Wandele einzeilige, externe Repräsentation in Array

=head4 Synopsis

    $arr = $class->restore($str);
    $arr = $class->restore($str,$colSep);

=head4 Description

Wandele einzeilige, externe Array-Repräsentation (siehe Methode dump())
in ein Array-Objekt und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub restore {
    my $class = CORE::shift;
    my $str = CORE::shift;
    my $colSep = CORE::shift // '|';

    my $f = sub {
        return '\\' if $_[0] eq '\\';
        return $colSep if $_[0] eq '!';
        return "\n" if $_[0] eq 'n';
        return "\r" if $_[0] eq 'r';

        $class->throw(
            'ARR-00001: Inkorrekte Array-Repräsentation',
            EscapeSequence => "\\$_[0]",
        );
    };

    my @arr = split /\Q$colSep/,$str,-1;
    for (@arr) {
        s/\\(.)/$f->($1,$colSep)/ge;
    }

    return bless \@arr,$class;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
