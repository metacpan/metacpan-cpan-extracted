package Quiq::Assert;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Assert - Zusicherungen

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::Assert;
    
    my $a = Quiq::Assert->new;
    
    # Prüfe, ob Wert in Aufzählung vorkommt
    $a->isEnumValue('Birne',['Apfel','Birne','Pflaume']);
    
    # Prüfe, ob Wert nicht leer ist
    $a->isNotNull('xyz');
    
    # Prüfe, ob Wert eine Zahl ist
    $a->isNumber(3.14152);

=head1 DESCRIPTION

Die Klasse stellt Methoden zur Verfügung, mit denen eine Eingenschaft
eines Werts geprüft werden kann. Im Erfolgsfall kehrt die jeweilige
Methode zurück, im Fehlerfall wirft sie eine Exception.

=head1 EXAMPLE

    $ perl -MQuiq::Assert -E 'Quiq::Assert->isNotNull("",-name=>'x')'
    Exception:
        ASSERT-00002: Value is null
    Name:
        x
    Stacktrace:
        Quiq::Assert::isNotNull() [+1 -e]
          Quiq::Object::throw() [+210 .../Quiq/Assert.pm]
            Quiq::Stacktrace::asString() [+425 .../Quiq/Object.pm]

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $a = $class->new;

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt lediglich die Funktion, eine abkürzende
Aufrufschreibweise zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    state $dummy;
    return bless \$dummy,$class;
}

# -----------------------------------------------------------------------------

=head2 Tests

Die folgenden Testmethoden können sowohl als Klassen- als auch als
Objektmethode aufgerufen werden.

=head3 isEnumValue() - Prüfe auf Enthaltensein in Enum

=head4 Synopsis

    $val = $this->isEnumValue($val,\@values,@opt);

=head4 Arguments

=over 4

=item $val

Wert, der geprüft wird.

=item @values

Liste der Enum-Werte.

=back

=head4 Options

=over 4

=item -name => $str

Name, der bei Verletzung der Bedingung als Teil der Fehlermeldung
ausgegeben wird. Dies kann der Name der geprüften Variable,
des geprüften Parameters o.ä. sein.

=back

=head4 Returns

Geprüften Wert (Skalar)

=head4 Description

Prüfe den Wert $val daraufhin, dass er in Liste @values enthalten ist.
Ist dies nicht der Fall, wirf eine Exception.  Ein leerer Wert wird
übergangen.

=cut

# -----------------------------------------------------------------------------

sub isEnumValue {
    my ($this,$val,$valueA) = splice @_,0,3;
    # @_: @opt

    # Optionen

    my $name = undef;
    
    $this->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '') {
        return;
    }

    if (!grep {$val eq $_} @$valueA) {
        $this->throw(
            'ASSERT-00001: Value not allowed',
            defined $name? (Name => $name): (),
            Value => $val,
            Allowed => join(', ',map {"'$_'"} @$valueA),
        );
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 isNotNull() - Prüfe auf nichtleeren Wert

=head4 Synopsis

    $val = $this->isNotNull($val,@opt);

=head4 Arguments

=over 4

=item $val

Wert, der geprüft wird.

=back

=head4 Options

=over 4

=item -name => $str

Name, der bei Verletzung der Bedingung als Teil der Fehlermeldung
ausgegeben wird. Dies kann der Name der geprüften Variable,
des geprüften Parameters o.ä. sein.

=back

=head4 Returns

Geprüften Wert (nichtleerer Skalar)

=head4 Description

Prüfe den Wert $val daraufhin, dass er nichtleer, also weder
undefiniert noch ein Leerstring ist. Ist er leer, wirf
eine Exception.

=cut

# -----------------------------------------------------------------------------

sub isNotNull {
    my ($this,$val) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $name = undef;
    
    $this->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '') {
        $this->throw(
            'ASSERT-00002: Value is null',
            defined $name? (Name => $name): (),
        );
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 isNumber() - Prüfe auf dezimale Zahldarstellung

=head4 Synopsis

    $val = $this->isNumber($val,@opt);

=head4 Arguments

=over 4

=item $val

Wert, der geprüft wird.

=back

=head4 Options

=over 4

=item -name => $str

Name, der bei Verletzung der Bedingung als Teil der Fehlermeldung
ausgegeben wird. Dies kann der Name der geprüften Variable,
des geprüften Parameters o.ä. sein.

=back

=head4 Returns

Geprüften Wert (Number)

=head4 Description

Prüfe den Wert $val daraufhin, dass er eine dezimale Zahl
darstellt. Ist dies nicht der Fall, wirf eine Exception.  Ein
leerer Wert wird übergangen.

=cut

# -----------------------------------------------------------------------------

sub isNumber {
    my ($this,$val) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $name = undef;
    
    $this->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '') {
        return;
    }

    if (!Quiq::Math->isNumber($val)) {
        $this->throw(
            'ASSERT-00001: Not a number',
            defined $name? (Name => $name): (),
            Value => $val,
        );
    }

    return $val;
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
