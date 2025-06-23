# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Assert - Zusicherungen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::Assert;
  
  my $a = Quiq::Assert->new;
  
  # Universeller Test (hier: Prüfe, ob Wert einen Punkt (.) enthält)
  $a->check('a.b',sub {index(shift,'.') >= 0});
  
  # Prüfe, ob Wert in Aufzählung vorkommt
  $a->isEnumValue('Birne',['Apfel','Birne','Pflaume']);
  
  # Prüfe, ob Wert nicht leer ist
  $a->isNotNull('xyz');
  
  # Prüfe, ob Wert eine Zahl ist
  $a->isNumber(3.14159);

=head1 DESCRIPTION

Die Klasse stellt Methoden zur Verfügung, mit denen eine Eingenschaft
eines Werts geprüft werden kann. Im Erfolgsfall kehrt die jeweilige
Methode zurück, im Fehlerfall wirft sie eine Exception.

=head1 EXAMPLE

Test von der Kommandozeile aus:

  $ perl -MQuiq::Assert -E 'Quiq::Assert->new->isNotNull("",-name=>"x")'
  Exception:
      ASSERT-00002: Value is null
  Name:
      x
  Stacktrace:
      Quiq::Assert::isNotNull() [+1 -e]
        Quiq::Object::throw() [+210 .../Quiq/Assert.pm]
          Quiq::Stacktrace::asString() [+425 .../Quiq/Object.pm]

=cut

# -----------------------------------------------------------------------------

package Quiq::Assert;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::Math;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $a = $class->new(@att);

=head4 Arguments

=over 4

=item @att

Attribut/Wert-Paare.

=over 4

=item nameSection => $label

Bezeichnung des Namensabschnitts.

=item stacktrace => $bool (Default: 1)

Gib bei Exception einen Stacktrace aus.

=back

=back

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
    # @_: @att

    my $self = $class->SUPER::new(
        nameSection => 'Name',
        stacktrace => 1,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Zusicherungen

Die folgenden Testmethoden können sowohl als Klassen- als auch als
Objektmethoden gerufen werden. Im Void-Kontext gerufen, werfen sie
eine Exception, wenn die Bedingung verletzt ist, andernfalls 0 oder 1.

=head3 check() - Prüfe beliebige Bedingung

=head4 Synopsis

  $this->check($val,@opt,$sub);         # Exception
  $bool = $this->check($val,@opt,$sub); # Rückgabewert

=head4 Arguments

=over 4

=item $val

Wert, der geprüft wird.

=item $sub

Prüf-Subroutine. Ist die Bedingung erfüllt, liefert sie "wahr",
andernfalls "falsch". Beispiel:

  sub {
      my $val = shift;
      return $val =~ /\.export$/? 1: 0;
  }

=back

=head4 Options

=over 4

=item -name => $str

Name, der bei Verletzung der Bedingung als Teil der Fehlermeldung
ausgegeben wird. Dies kann der Name der geprüften Variable,
des geprüften Parameters o.ä. sein.

=back

=head4 Returns

Boolean

=head4 Description

Prüfe den Wert $val daraufhin, ob er die Prüfung $sub besteht.
Ist dies nicht der Fall, wirf eine Exception, wenn die Methode im
Void-Kontext gerufen wurde, andernfalls 0. Ein leerer Wert verletzt
die Bedingung nicht, d.h. die Subroutine wird für einen leeren Wert nicht
gerufen und muss diesen Fall daher nicht behandeln.

=cut

# -----------------------------------------------------------------------------

sub check {
    my $self = ref $_[0]? shift: shift->new;
    my $val = shift;
    # @_: @opt,$sub

    # Optionen und Argumente

    my $name = undef;

    my $argA = $self->parameters(1,1,\@_,
        -name => \$name,
    );
    my $sub = shift @$argA;

    # Prüfung

    if (!defined($val) || $val eq '' || $sub->($val)) {
        return 1;
    }
    elsif (defined wantarray) {
        return 0;
    }

    $self->throw(
        'ASSERT-00001: Check failed',
        defined $name? ($self->{'nameSection'} => $name): (),
        Value => $val,
        -stacktrace => $self->{'stacktrace'},
    );
}

# -----------------------------------------------------------------------------

=head3 pathExists() - Prüfe Existenz von Pfad

=head4 Synopsis

  $this->pathExists($path);         # Exception
  $bool = $this->pathExists($path); # Rückgabewert

=head4 Aliases

=over 2

=item *

fileExists()

=item *

dirExists()

=back

=head4 Arguments

=over 4

=item $path (String)

Pfad

=back

=head4 Returns

Boolean

=head4 Description

Prüfe, ob Pfad $path existiert. Ist dies nicht der Fall, wirf eine
Exception, wenn die Methode im Void-Kontext gerufen wurde, andernfalls 0.
Ein leerer Wert verletzt die Bedingung nicht.

=cut

# -----------------------------------------------------------------------------

sub pathExists {
    my $self = ref $_[0]? shift: shift->new;
    my $path = shift;

    # Prüfung

    if (!defined($path) || $path eq '' || Quiq::Path->exists($path)) {
        return 1;
    }
    elsif (defined wantarray) {
        return 0;
    }

    $self->throw(
        'ASSERT-00001: Path does not exist',
        Path => $path,
    );
}

{
    no warnings 'once';
    *fileExists = \&pathExists;
    *dirExists = \&pathExists;
}

# -----------------------------------------------------------------------------

=head3 isEnumValue() - Prüfe auf Enthaltensein in Enum

=head4 Synopsis

  $this->isEnumValue($val,\@values,@opt);         # Exception
  $bool = $this->isEnumValue($val,\@values,@opt); # Rückgabewert

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

Boolean

=head4 Description

Prüfe den Wert $val daraufhin, dass er in Liste @values enthalten ist.
Ist dies nicht der Fall, wirf eine Exception, wenn die Methode
im Void-Kontext gerufen wurde, andernfalls 0. Ein leerer Wert verletzt
die Bedingung nicht.

=cut

# -----------------------------------------------------------------------------

sub isEnumValue {
    my $self = ref $_[0]? shift: shift->new;
    my $val = shift;
    my $valueA = shift;
    # @_: @opt

    # Optionen

    my $name = undef;

    $self->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '' || grep {$val eq $_} @$valueA) {
        return 1;
    }
    elsif (defined wantarray) {
        return 0;
    }

    $self->throw(
        'ASSERT-00001: Unexpected value',
        defined $name? ($self->{'nameSection'} => $name): (),
        Value => $val,
        Allowed => join(', ',map {"'$_'"} @$valueA),
        -stacktrace => $self->{'stacktrace'},
    );
}

# -----------------------------------------------------------------------------

=head3 isNotNull() - Prüfe auf nichtleeren Wert

=head4 Synopsis

  $this->isNotNull($val,@opt);         # Exception
  $bool = $this->isNotNull($val,@opt); # Rückgabewert

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

Boolean

=head4 Description

Prüfe den Wert $val daraufhin, dass er nichtleer, also weder
undefiniert noch ein Leerstring ist. Ist er leer, wirf eine Exception,
wenn die Methode im Void-Kontext gerufen wurde, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub isNotNull {
    my $self = ref $_[0]? shift: shift->new;
    my $val = shift;
    # @_: @opt

    # Optionen

    my $name = undef;

    $self->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (defined($val) && $val ne '') {
        return 1;
    }
    elsif (defined wantarray) {
        return 0;
    }

    $self->throw(
        'ASSERT-00002: Value is null',
        defined $name? ($self->{'nameSection'} => $name): (),
        -stacktrace => $self->{'stacktrace'},
    );
}

# -----------------------------------------------------------------------------

=head3 isNumber() - Prüfe auf dezimale Zahldarstellung

=head4 Synopsis

  $this->isNumber($val,@opt);         # Exception
  $bool = $this->isNumber($val,@opt); # Rückgabewert

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

Boolean

=head4 Description

Prüfe den Wert $val daraufhin, dass er eine dezimale Zahl darstellt.
Ist dies nicht der Fall, wirf eine Exception, wenn die Methode im
Void-Kontext gerufen wurde, andernfalls 0. Ein leerer Wert verletzt
die Bedingung nicht.

=cut

# -----------------------------------------------------------------------------

sub isNumber {
    my $self = ref $_[0]? shift: shift->new;
    my $val = shift;
    # @_: @opt

    # Optionen

    my $name = undef;

    $self->parameters(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '' || Quiq::Math->isNumber($val)) {
        return 1;
    }
    elsif (defined wantarray) {
        return 0;
    }

    $self->throw(
        'ASSERT-00001: Not a number',
        defined $name? ($self->{'nameSection'} => $name): (),
        Value => $val,
        -stacktrace => $self->{'stacktrace'},
    );
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
