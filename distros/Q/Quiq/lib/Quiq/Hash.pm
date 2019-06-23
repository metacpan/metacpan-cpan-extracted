package Quiq::Hash;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use Scalar::Util ();
use Hash::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Hash - Zugriffssicherer Hash mit automatisch generierten Attributmethoden

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

Klasse laden:

    use Quiq::Hash;

Hash-Objekt instantiieren:

    my $h = Quiq::Hash->new(a=>1,b=>1,c=>3);

Werte abfragen oder setzen:

    my $v = $h->get('a'); # oder: $v = $h->{'a'};
    $h->set(b=>2);        # oder: $h->{'b'} = 2;

Unerlaubte Zugriffe:

    $v = $h->get('d');    # Exception!
    $h->set(d=>4);        # Exception!

Erlaubte Zugriffe;

    $v = $h->try('d');    # undef
    $h->add(d=>4);

=head1 DESCRIPTION

Ein Objekt dieser Klasse repräsentiert einen I<zugriffssicheren> Hash,
d.h. einen Hash, dessen Schlüsselvorrat bei der Instantiierung
festgelegt wird. Ein lesender oder schreibender Zugriff mit einem
Schlüssel, der nicht zum Schlüsselvorrat gehört, ist nicht erlaubt
und führt zu einer Exception.

Der Zugriffsschutz beruht auf der Funktionalität des
L<Restricted Hash|http://perldoc.perl.org/Hash/Util.html#Restricted-hash>.

Abgesehen vom Zugriffsschutz verhält sich ein Hash-Objekt der
Klasse wie einer normaler Perl-Hash und kann auch so angesprochen
werden.  Bei den Methoden ist der konventionelle Zugriff als
C<Alternative Formulierung> angegeben.

=cut

# -----------------------------------------------------------------------------

our $GetCount = 0;
our $SetCount = 0;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Instantiierung

=head3 new() - Instantiiere Hash

=head4 Synopsis

    $h = $class->new;                       # [1]
    $h = $class->new(@keyVal);              # [2]
    $h = $class->new(\@keys,\@vals[,$val]); # [3]
    $h = $class->new(\@keys[,$val]);        # [4]
    $h = $class->new(\%hash);               # [5]

=head4 Description

Instantiiere ein Hash-Objekt, setze die Schlüssel/Wert-Paare
und liefere eine Referenz auf dieses Objekt zurück.

=over 4

=item [1]

Leerer Hash.

=item [2]

Die Argumentliste ist eine Aufzählung von Schlüssel/Wert-Paaren.

=item [3]

Schlüssel und Werte befinden sich in getrennten Arrays.
Ist ein Wert C<undef>, wird $val gesetzt, falls angegeben.

=item [4]

Nur die Schlüssel sind angegeben. Ist $val angegeben, werden
alle Werte auf diesen Wert gesetzt. Ist $val nicht angegeben,
werden alle Werte auf C<undef> gesetzt.

=item [5]

Blesse den Hash %hash auf Klasse $class.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Argumente

    my $h;
    if (!ref $_[0]) {
        # Aufruf: $h = $class->new;
        # Aufruf: $h = $class->new(@keyVal);

        $h = \my %h;
        while (@_) {
            my $key = shift;
            $h{$key} = shift;
        }
    }
    elsif ((Scalar::Util::reftype($_[0]) || '') eq 'HASH') { # Perform.
        # Aufruf: $h = $class->new(\%hash);
        $h = bless shift,$class;
    }
    else {
        # Aufruf: $h = $class->new(\@keys,...);
        my $keyA = shift;

        $h = \my %h;
        if (ref $_[0]) {
            # Aufruf: $h = $class->new(\@keys,\@vals,...);
            my $valA = shift;

            if (@_) {
                # Aufruf: $h = $class->new(\@keys,\@vals,$val);
                my $val = shift;
                my $i = 0;
                for my $key (@$keyA) {
                    $h{$key} = $valA->[$i++];
                    if (!defined $h{$key}) {
                        $h{$key} = $val;
                    }
                }
            }
            else {
                # Aufruf: $h = $class->new(\@keys,\@vals);
                @h{@$keyA} = @$valA;
            }
        }
        else {
            # Aufruf: $h = $class->new(\@keys[,$val]);

            my $val = shift;
            @h{@$keyA} = ($val) x @$keyA;
        }
    }

    # Sperre Schlüssel gegen Änderungen

    bless $h,$class;
    $h->lockKeys;

    return $h;
}

# -----------------------------------------------------------------------------

=head3 fabricate() - Instantiiere Hash für Klasse

=head4 Synopsis

    $h = $class->fabricate($subClass,...);

=head4 Description

Wie new(), nur dass der Hash als Instanz der Subklasse $subClass
erzeugt wird. Die Subklasse wird on-the-fly erzeugt, falls sie noch
nicht existiert.

=cut

# -----------------------------------------------------------------------------

sub fabricate {
    my ($class,$subClass) = splice @_,0,2;
    # @_: Argumente

    no strict 'refs';
    if (!defined *{$subClass.'::'}) {
        eval "package $subClass; our \@ISA = ('$class');";
        if ($@) {
            die;
        }
    }

    return $subClass->new(@_);
}

# -----------------------------------------------------------------------------

=head2 Akzessor-Methoden

=head3 get() - Werte abfragen

=head4 Synopsis

    $val = $h->get($key);
    @vals = $h->get(@keys);

=head4 Description

Liefere die Werte zu den angegebenen Schlüsseln. In skalarem Kontext
liefere keine Liste, sondern den Wert des ersten Schlüssels.

Alternative Formulierung:

    $val = $h->{$key};    # ein Schlüssel
    @vals = @{$h}{@keys}; # mehrere Schlüssel

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;
    # @_: @keys

    $GetCount++;
    if (wantarray) {
        my @arr;
        while (@_) {
            my $key = shift;
            push @arr,$self->{$key};
        }
        return @arr;
    }

    return $self->{$_[0]};
}

# -----------------------------------------------------------------------------

=head3 getRef() - Referenz auf Wert

=head4 Synopsis

    $valS = $h->getRef($key);

=head4 Description

Liefere nicht den Wert zum Schlüssel $key, sondern eine Referenz auf
den Wert.

Dies kann praktisch sein, wenn der Wert manipuliert werden soll. Die
Manipulation kann dann über die Referenz erfolgen und der Wert muss
nicht erneut zugewiesen werden.

Alternative Formulierung:

    $valS = \$h->{$key};

=head4 Example

Newline an Wert anhängen mit getRef():

    $valS = $h->getRef('x');
    $$valS .= "\n";

Dasselbe ohne getRef():

    $val = $h->get('x');
    $val .= "\n";
    $val->set(x=>$val);

=cut

# -----------------------------------------------------------------------------

sub getRef {
    return \$_[0]->{$_[1]};
}

# -----------------------------------------------------------------------------

=head3 getArray() - Liefere Array

=head4 Synopsis

    @arr|$arr = $h->getArray($key);

=head4 Description

Liefere die Liste von Werten des Schlüssels $key. Im Skalarkontext
liefere eine Referenz auf die Liste (der Aufruf hat dann die gleiche
Wirkung wie der Aufruf von $h->L<get|"get() - Werte abfragen">()). Der Wert von $key muss
eine Array-Referenz sein.

=cut

# -----------------------------------------------------------------------------

sub getArray {
    my ($self,$key) = @_;
    my $arr = $self->{$key} || [];
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 try() - Werte abfragen ohne Exception

=head4 Synopsis

    $val = $h->try($key);
    @vals = $h->try(@keys);

=head4 Description

Wie L<get|"get() - Werte abfragen">(), nur dass im Falle eines unerlaubten Schlüssels
keine Exception geworfen, sondern C<undef> geliefert wird.

=cut

# -----------------------------------------------------------------------------

sub try {
    my $self = shift;
    # @_: @keys

    if (wantarray) {
        my @arr;
        while (@_) {
            my $key = shift;
            push @arr,CORE::exists $self->{$key}? $self->{$key}: undef;
        }
        return @arr;
    }

    return CORE::exists $self->{$_[0]}? $self->{$_[0]}: undef
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Schlüssel/Wert-Paare

=head4 Synopsis

    $h->set(@keyVal);

=head4 Description

Setze die angegebenen Schlüssel/Wert-Paare.

Alternative Formulierung:

    $h->{$key} = $val;    # ein Schlüssel/Wert-Paar
    @{$h}{@keys} = @vals; # mehrere Schlüssel/Wert-Paare

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    # @_: @keyVal

    # Hash mit freiem Zugriff

    $SetCount++;
    while (@_) {
        my $key = shift;
        $self->{$key} = shift;
        #eval {$self->{$key} = shift};
        #if ($@) {
        #    $self->throw($@);
        #}
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 add() -  Setze Schlüssel/Wert-Paare ohne Exception

=head4 Synopsis

    $val = $h->add($key=>$val);
    @vals = $h->add(@keyVal);

=head4 Description

Wie L<set|"set() - Setze Schlüssel/Wert-Paare">(), nur dass im Falle eines unerlaubten Schlüssels keine
Exception generiert, sondern der Hash um das Schlüssel/Wert-Paar
erweitert wird.

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: @keyVal

    # Test auf einen gelockten Hash funktioniert erst ab 5.18.0,
    # daher arbeiten wir hier mit eval{}.

    local $@;
    my @arr = eval {$self->set(@_)};
    if ($@) {
        $self->unlockKeys;
        @arr = $self->set(@_);
        $self->lockKeys;
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 memoize() - Cache Wert auf berechnetem Attribut

=head4 Synopsis

    $val = $h->memoize($key,$sub);

=head4 Description

Besitzt das Attribut $key einen Wert, liefere ihn. Andernfalls
berechne den Wert mittels der Subroutine $sub und cache ihn
auf dem Attribut.

Die Methode ist nützlich, um in Objektmethoden eingebettet zu werden,
die einen berechneten Wert liefern, der nicht immer wieder neu
gerechnet werden soll.

Alternative Formulierungen:

    $val = $h->{$key} //= $h->$sub($key);

oder

    $val = $h->{$key} //= do {
        # Implementierung der Subroutine
    };

=cut

# -----------------------------------------------------------------------------

sub memoize {
    my ($self,$key,$sub) = @_;
    return $self->{$key} //= $self->$sub($key);
}

# -----------------------------------------------------------------------------

=head3 memoizeWeaken() - Cache schwache Referenz auf berechnetem Attribut

=head4 Synopsis

    $ref = $h->memoizeWeaken($key,$sub);

=head4 Description

Wie memozize(), nur dass $sub eine Referenz liefert, die
von der Methode automatisch zu einer schwachen Referenz gemacht wird.

Bei nicht-existenter Referenz kann die Methode $sub einen Leerstring
liefern. Dieser wird auf C<undef> abgebildet.

=cut

# -----------------------------------------------------------------------------

sub memoizeWeaken {
    my ($self,$key,$sub) = @_;

    # MEMO: Variable $ref wird hier benötigt, damit die erzeugte
    # Referenz bei Aufruf von weaken() nicht gleich wieder
    # destrukturiert wird!

    my $ref = $self->{$key};
    if (!defined $ref) {
        $ref = $self->$sub($key);
        if ($ref ne '') {
            $self->weaken($key=>$ref);
        }
    }

    return ref $ref? $ref: undef;
}

# -----------------------------------------------------------------------------

=head3 compute() - Wende Subroutine auf Schlüssel/Wert-Paar an

=head4 Synopsis

    $val = $h->compute($key,$sub);

=head4 Description

Wende Subroutine $sub auf den Wert des Schlüssels $key an. Die
Subroutine hat die Struktur:

    sub {
        my ($h,$key) = @_;
        ...
        return $val;
    }

Der Rückgabewert der Subroutine wird an Schlüssel $key zugewiesen.

=head4 Example

Methode L<increment|"increment() - Inkrementiere (Integer-)Wert">() mit apply() realisiert:

    $val = $h->compute($key,sub {
        my ($h,$key) = @_;
        return $h->{$key}+1; # nicht $h->{$key}++!
    });

=cut

# -----------------------------------------------------------------------------

sub compute {
    my ($self,$key,$sub) = @_;
    return $self->{$key} = $sub->($self,$key);
}

# -----------------------------------------------------------------------------

=head2 Automatische Akzessor-Methoden

=head3 AUTOLOAD() - Erzeuge Akzessor-Methode

=head4 Synopsis

    $val = $h->AUTOLOAD;
    $val = $h->AUTOLOAD($val);

=head4 Description

Erzeuge eine Akzessor-Methode für eine Hash-Komponente. Die Methode
AUTOLOAD() wird für jede Hash-Komponente einmal aufgerufen.
Danach gehen alle Aufrufe für die Komponente direkt an die erzeugte
Akzessor-Methode.

Die Methode AUTOLOAD() erweitert ihre Klasse um automatisch
generierte Akzessor-Methoden. D.h. für jede Komponente des Hash
wird bei Bedarf eine Methode erzeugt, durch die der Wert der
Komponente manipuliert werden kann. Dadurch ist es möglich, die
Manipulation von Attributen ohne Programmieraufwand nahtlos
in die Methodenschnittstelle einer Klasse zu integrieren.

Gegenüberstellung:

    Hash-Zugriff           get()/set()               Methoden-Zugriff
    --------------------   -----------------------   --------------------
    $name = $h->{'name'}   $name = $h->get('name')   $name = $h->name
    $h->{'name'} = $name   $h->set(name=>$name)      $h->name($name) -or-
                                                     $h->name = $name

In der letzten Spalte ("Methoden-Zugriff") steht die Syntax der
automatisch generierten Akzessor-Methoden.

Die Akzessor-Methode wird als lvalue-Methode generiert, d.h. die
Hash-Komponente kann per Akzessor-Aufruf manipuliert werden. Beispiele:

    $h->name = $name;
    $h->name =~ s/-//g;

Die Erzeugung einer Akzessor-Methode erfolgt (vom Aufrufer unbemerkt)
beim ersten Aufruf. Danach wird die Methode unmittelbar gerufen.

Der Zugriff über eine automatisch generierte Attributmethode ist ca. 30%
schneller als über $h->L<get|"get() - Werte abfragen">().

=cut

# -----------------------------------------------------------------------------

sub AUTOLOAD :lvalue {
    my $this = shift;
    # @_: Methodenargumente

    my ($key) = our $AUTOLOAD =~ /::(\w+)$/;
    return if $key !~ /[^A-Z]/;

    # Klassenmethoden generieren wir nicht

    if (!ref $this) {
        $this->throw(
            'HASH-00002: Klassen-Methode existiert nicht',
            Method => $key,
        );
    }

    # Methode nur generieren, wenn Attribut existiert

    if (!exists $this->{$key}) {
        $this->throw(
            'HASH-00001: Hash-Schlüssel oder Methode existiert nicht',
            Attribute => $key,
            Class => ref($this)? ref($this): $this,
        );
    }

    # Attribut-Methode generieren. Da $self ein Restricted Hash ist,
    # brauchen wir die Existenz des Attributs nicht selbst prüfen.

    no strict 'refs';
    *{$AUTOLOAD} = sub :lvalue {
        my $self = shift;
        # @_: $val

        if (@_) {
            $self->{$key} = shift;
        }

        return $self->{$key};
    };

    # Methode aufrufen
    return $this->$key(@_);
}

# -----------------------------------------------------------------------------

=head2 Schlüssel

=head3 keys() - Liste der Schlüssel

=head4 Synopsis

    @keys|$keyA = $h->keys;

=head4 Description

Liefere die Liste aller Schlüssel. Die Liste ist unsortiert.
Im Skalarkontext liefere eine Referenz auf die Liste.

Die Reihenfolge der Schlüssel ist undefiniert.

Alternative Formulierung:

    @keys = keys %$h;

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    my @keys = CORE::keys %$self;
    return wantarray? @keys: \@keys;
}

# -----------------------------------------------------------------------------

=head3 hashSize() - Anzahl der Schlüssel

=head4 Synopsis

    $n = $h->hashSize;

=head4 Description

Liefere die Anzahl der Schlüssel/Wert-Paare des Hash.

Alternative Formulierung:

    $n = keys %$h;

=cut

# -----------------------------------------------------------------------------

sub hashSize {
    my $self = shift;
    return scalar CORE::keys %$self;
}

# -----------------------------------------------------------------------------

=head3 validate() - Überprüfe Hash-Schlüssel

=head4 Synopsis

    $class->validate(\%hash,\@keys);
    $class->validate(\%hash,\%keys);

=head4 Description

Prüfe die Schlüssel des Hash %hash gegen die Schlüssel in Array
@keys bzw. Hash %keys. Enthält %hash einen Schlüssel, der nicht in
@keys bzw. %keys vorkommt, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub validate {
    my ($class,$h,$arg) = @_;

    my $refH;
    if (Scalar::Util::reftype($arg) eq 'ARRAY') {
        @$refH{@$arg} = (1) x @$arg;
    }
    else {
        $refH = $arg;
    }
    for my $key (CORE::keys %$h) {
        if (!exists $refH->{$key}) {
            $class->throw(
                'HASH-00099: Unzulässiger Hash-Schlüssel',
                Key => $key,
            );
        }
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head2 Kopieren

=head3 copy() - Kopiere Hash

=head4 Synopsis

    $h2 = $h->copy;
    $h2 = $h->copy(@keyVal);

=head4 Description

Kopiere Hash, d.h. instantiiere einen neuen Hash mit den
gleichen Schlüssel/Wert-Paaren. Es wird I<nicht> rekursiv kopiert,
sondern eine "shallow copy" erzeugt.

Sind Schlüssel/Wert-Paare @keyVal angegeben, werden
diese nach dem Kopieren per L<set|"set() - Setze Schlüssel/Wert-Paare">() auf dem neuen Hash gesetzt.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;
    # @_: @keyVal

    my %hash = %$self;
    my $h = bless \%hash,ref $self;
    if (@_) {
        $h->set(@_);
    }
    if ($self->isLocked) {
        $h->lockKeys;
    }

    return $h;
}

# -----------------------------------------------------------------------------

=head3 join() - Füge Hash hinzu

=head4 Synopsis

    $h = $h->join(\%hash);

=head4 Returns

Hash (für Method Chaining)

=head4 Description

Überschreibe die Schlüssel/Wert-Paare in Hash $h mit den
Schlüssel/Wert-Paaren aus Hash %hash. Schlüssel/Wert-Paare
in Hash $h, die in Hash %hash nicht vorkommen, bleiben bestehen.
Enthält %hash einen Schlüssel, der in $h nicht vorkommt, wird eine
Exception geworfen.

=head4 Example

Ein Hash-Objekt mit vorgegebenen Attributen aus einem anoymen Hash
erzeugen. Der anonyme Hash darf weniger, aber nicht mehr Attribute
enthalten:

    $h = Quiq::Hash->new([qw/
        name
        label
        width
        height
    /])->join(\%hash);

=cut

# -----------------------------------------------------------------------------

sub join {
    my ($self,$hash) = @_;

    for my $key (CORE::keys %$hash) {
        $self->{$key} = $hash->{$key};
    }
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Löschen

=head3 delete() - Entferne Schlüssel/Wert-Paare

=head4 Synopsis

    $h->delete(@keys);

=head4 Description

Entferne die Schlüssel @keys (und ihre Werte) aus dem Hash. An der Menge
der zulässigen Schlüssel ändert sich dadurch nichts!

Alternative Formulierung:

    delete $h->{$key};   # einzelner Schlüssel
    delete @{$h}{@keys}; # mehrere Schlüssel

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    # @_: @keys

    for (@_) {
        CORE::delete $self->{$_};
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 clear() - Leere Hash

=head4 Synopsis

    $h->clear;

=head4 Description

Leere Hash, d.h. entferne alle Schlüssel/Wert-Paare.

Alternative Formulierung:

    %$h = ();

=cut

# -----------------------------------------------------------------------------

sub clear {
    my $self = shift;
    %$self = ();
    return;
}

# -----------------------------------------------------------------------------

=head2 Tests

=head3 exists() - Prüfe Schlüssel auf Existenz

=head4 Synopsis

    $bool = $h->exists($key);

=head4 Description

Prüfe, ob der angegebene Schlüssel im Hash existiert. Wenn ja,
liefere I<wahr>, andernfalls I<falsch>.

Alternative Formulierung:

    $bool = exists $self->{$key};

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;
    return CORE::exists $self->{$key}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 defined() - Prüfe Wert auf Existenz

=head4 Synopsis

    $bool = $h->defined($key);

=head4 Description

Prüfe, ob der angegebene Schlüssel im Hash einen Wert hat. Wenn ja,
liefere I<wahr>, andernfalls I<falsch>.

Alternative Formulierung:

    $bool = defined $h->{$key};

=cut

# -----------------------------------------------------------------------------

sub defined {
    my ($self,$key) = @_;
    return CORE::defined $self->{$key}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isEmpty() - Prüfe auf leeren Hash

=head4 Synopsis

    $bool = $h->isEmpty;

=head4 Description

Prüfe, ob der Hash leer ist. Wenn ja, liefere I<wahr>,
andernfalls I<falsch>.

Alternative Formulierung:

    $bool = %$h;

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    my $self = shift;
    return CORE::keys(%$self) == 0? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Sperren

=head3 isLocked() - Prüfe, ob Hash gesperrt ist

=head4 Synopsis

    $bool = $h->isLocked;

=head4 Description

Prüfe, ob der Hash gelockt ist. Wenn ja, liefere I<wahr>,
andernfalls I<falsch>.

=cut

# -----------------------------------------------------------------------------

sub isLocked {
    my $self = shift;

    if ($] < 5.018) {
        local $@;
        # Ohne $r gibt es eine Warning
        my $r = eval {$self->{'this_key_does_not_exist'}};
        if ($@) {
            return 1;
        }
        delete $self->{'this_key_does_not_exist'};
        return 0;
    }

    return Hash::Util::hashref_unlocked($self)? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 lockKeys() - Sperre Hash

=head4 Synopsis

    $h = $h->lockKeys;

=head4 Description

Sperre den Hash. Anschließend kann kein weiterer Schlüssel zugegriffen
werden. Wird dies versucht, wird eine Exception geworfen.

Alternative Formulierung:

    Hash::Util::lock_keys(%$h);

Die Methode liefert eine Referenz auf den Hash zurück.

=cut

# -----------------------------------------------------------------------------

sub lockKeys {
    my $self = shift;
    Hash::Util::lock_keys(%$self);
    return $self;
}

# -----------------------------------------------------------------------------

=head3 unlockKeys() - Entsperre Hash

=head4 Synopsis

    $h = $h->unlockKeys;

=head4 Description

Entsperre den Hash. Anschließend kann der Hash uneingeschränkt
manipuliert werden. Die Methode liefert eine Referenz auf den Hash
zurück. Damit kann der Hash gleich nach der Instantiierung
entsperrt werden:

    return Quiq::Hash->new(...)->unlockKeys;

Alternative Formulierung:

    Hash::Util::unlock_keys(%$h);

=cut

# -----------------------------------------------------------------------------

sub unlockKeys {
    my $self = shift;
    Hash::Util::unlock_keys(%$self);
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 arraySize() - Größe des referenzierten Arrays

=head4 Synopsis

    $n = $h->arraySize($key);

=cut

# -----------------------------------------------------------------------------

sub arraySize {
    my ($self,$key) = @_;

    if (!defined $self->{$key}) {
        return 0;
    }
    elsif (Scalar::Util::reftype($self->{$key}) eq 'ARRAY') {
        return @{$self->{$key}};
    }
    
    $self->throw(
        'HASH-00005: Keine Array-Referenz',
        Key => $key,
        Class => ref($self),
    );
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Werte zu Arraykomponente hinzu

=head4 Synopsis

    $h->push($key,@values);

=head4 Arguments

=over 4

=item $key

Arraykomponente.

=item @values

Werte, die zum Array hinzugefügt werden.

=back

=head4 Description

Füge Werte @values zur Arraykomponente $key hinzu. Die Methode
liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub push {
    my $self = shift;
    my $key = shift;
    # @_: @values

    CORE::push @{$self->{$key}},@_;

    return;
}

# -----------------------------------------------------------------------------

=head3 unshift() - Füge Element am Anfang zu Arraykomponente hinzu

=head4 Synopsis

    $h->unshift($key,$val);

=head4 Arguments

=over 4

=item $key

Arraykomponente.

=item $val

Wert, der zum Array hinzugefügt wird.

=back

=head4 Description

Füge Wert $val am Anfang zur Arraykomponente $key hinzu. Die
Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unshift {
    my ($self,$key,$val) = @_;
    CORE::unshift @{$self->{$key}},$val;
    return;
}

# -----------------------------------------------------------------------------

=head3 increment() - Inkrementiere (Integer-)Wert

=head4 Synopsis

    $n = $h->increment($key);

=head4 Description

Inkrementiere (Integer-)Wert zu Schlüssel $key und liefere das
Resultat zurück.

Alternative Formulierung:

    $n = ++$h->{$key};

=cut

# -----------------------------------------------------------------------------

sub increment {
    my ($self,$key) = @_;
    return ++$self->{$key};
}

# -----------------------------------------------------------------------------

=head3 addNumber() - Addiere numerischen Wert

=head4 Synopsis

    $y = $h->addNumber($key,$x);

=head4 Description

Addiere numerischen Wert $x zum Wert des Schlüssels $key hinzu und
liefere das Resultat zurück.

Alternative Formulierung:

    $y = $h->{$key} += $x;

=cut

# -----------------------------------------------------------------------------

sub addNumber {
    my ($self,$key,$x) = @_;
    return $self->{$key} += $x;
}

# -----------------------------------------------------------------------------

=head3 weaken() - Erzeuge schwache Referenz

=head4 Synopsis

    $ref = $h->weaken($key);
    $ref = $h->weaken($key=>$ref);

=head4 Description

Mache die Referenz von Schlüssel $key zu einer schwachen Referenz
und liefere sie zurück. Ist eine Referenz $ref als Parameter angegeben,
setze die Referenz zuvor.

=cut

# -----------------------------------------------------------------------------

sub weaken {
    my $self = shift;
    my $key = shift;
    # @_: $ref

    if (@_) {
        $self->{$key} = shift;
    }
    Scalar::Util::weaken($self->{$key});

    return $self->{$key};
}

# -----------------------------------------------------------------------------

=head2 Interna

=head3 buckets() - Ermittele Bucket-Anzahl

=head4 Synopsis

    $n = $h->buckets;

=head4 Description

Liefere die Anzahl der Hash-Buckets.

=cut

# -----------------------------------------------------------------------------

sub buckets {
    my $self = shift;

    # scalar(%hash) liefert 0, wenn der Hash leer ist, andernfalls
    # $x/$n, wobei $n die Anzahl der zur Verfügung stehenden Buckets ist
    # und $x die Anzahl der genutzten Buckets. Um die Bucketanzahl
    # eines leeren Hash zu ermitteln, müssen wir also temporär ein
    # Element hinzufügen.

    my $n;
    unless ($n = scalar %$self) {
        $self->add(this_is_a_pseudo_key=>1);
        $n = scalar %$self;
        $self->delete('this_is_a_pseudo_key');
    }
    $n =~ s|.*/||;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 bucketsUsed() - Anzahl der genutzten Buckets

=head4 Synopsis

    $n = $h->bucketsUsed;

=head4 Description

Liefere die Anzahl der genutzten Hash-Buckets.

=cut

# -----------------------------------------------------------------------------

sub bucketsUsed {
    my $self = shift;

    my $n = scalar %$self;
    if ($n) {
        $n =~ s|/.*||;
    }

    return $n;
}

# -----------------------------------------------------------------------------

=head3 getCount() - Anzahl der get-Aufrufe

=head4 Synopsis

    $n = $this->getCount;

=head4 Description

Liefere die Anzahl der get-Aufrufe seit Start des Programms.

=cut

# -----------------------------------------------------------------------------

sub getCount {
    my $self = shift;
    return $GetCount;
}

# -----------------------------------------------------------------------------

=head3 setCount() - Anzahl der set-Aufrufe

=head4 Synopsis

    $n = $this->setCount;

=head4 Description

Liefere die Anzahl der set-Aufrufe seit Start des Programms.

=cut

# -----------------------------------------------------------------------------

sub setCount {
    my $self = shift;
    return $SetCount;
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 Benchmark

Anzahl Zugriffe pro CPU-Sekunde im Vergleich zwischen verschiedenen
Zugriffsmethoden:

    A - Hash: $h->{$k}
    B - Hash: eval{$h->{$k}}
    C - Restricted Hash: $h->{$k}
    D - Restricted Hash: eval{$h->{$k}}
    E - Quiq::Hash: $h->{$k}
    F - Quiq::Hash: $h->get($k)
    
           Rate    F    D    B    E    C    A
    F 1401111/s   -- -71% -74% -82% -83% -84%
    D 4879104/s 248%   --  -8% -37% -40% -44%
    B 5297295/s 278%   9%   -- -32% -35% -39%
    E 7803910/s 457%  60%  47%   --  -4% -11%
    C 8104988/s 478%  66%  53%   4%   --  -7%
    A 8745272/s 524%  79%  65%  12%   8%   --

Den Hash via $h->L<get|"get() - Werte abfragen">() zuzugreifen (F) ist ca. 85% langsamer
als der einfachste Hash-Lookup (A). Wird auf den Methodenaufruf
verzichtet und per $h->{$key} zugegriffen (E), ist der Zugriff nur
11% langsamer. Es ist also ratsam, intern per $h->{$key}
zuzugreifen. Per $h->get() können immerhin 1.400.000 Lookups pro
CPU-Sekunde ausgeführt werden. Bei nicht-zugriffsintensiven
Anwendungen ist das sicherlich schnell genug.  Die Anzahl der
Aufrufe von $h->get() und $h->set() wird intern gezählt und kann
per $class->L<getCount|"getCount() - Anzahl der get-Aufrufe">() und $class->L<setCount|"setCount() - Anzahl der set-Aufrufe">() abgefragt
werden.

Das Benchmark-Programm (bench-hash):

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    
    use Benchmark;
    use Hash::Util;
    use Quiq::Hash;
    
    my $h1 = {0=>'a',1=>'b',2=>'c',3=>'d',4=>'e',5=>'f'};
    my $h2 = Hash::Util::lock_ref_keys({0=>'a',1=>'b',2=>'c',3=>'d',4=>'e',5=>'f'});
    my $h3 = Quiq::Hash->new({0=>'a',1=>'b',2=>'c',3=>'d',4=>'e',5=>'f'});
    
    my $i = 0;
    Benchmark::cmpthese(-10,{
        A => sub {
            $h1->{$i++%5};
        },
        B => sub {
            eval{$h1->{$i++%5}};
        },
        C => sub {
            $h2->{$i++%5};
        },
        D => sub {
            eval{$h2->{$i++%5}};
        },
        E => sub {
            $h3->{$i++%5};
        },
        F => sub {
            $h3->get($i++%5);
        },
    });

=head1 VERSION

1.147

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
