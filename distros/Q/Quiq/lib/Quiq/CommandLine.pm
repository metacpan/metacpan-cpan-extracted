package Quiq::CommandLine;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::CommandLine - Konstruiere eine Unix-Kommandozeile

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    use Quiq::CommandLine;
    
    my $c = Quiq::CommandLine->new('iconv');
    $c->addOption(
        -f => 'utf-8',
        -t => 'latin1',
    );
    $c->addString('|','enscript');
    $c->addBoolOption(
        '--no-header' => 1,
        '--landscape' => 1,
    );
    $c->addLongOption(
        '--font' => 'Courier8',
    );
    $c->addString('2>/dev/null','|','ps2pdf','-');
    $c->addArgument('/tmp/test.pdf');
    
    my $cmd = $c->command;
    __END__
    iconv -f utf-8 -t latin1 | enscript --no-header --landscape --font=Courier8 2>/dev/null | ps2pdf - /tmp/test.pdf

=head1 DESCRIPTION

Die Klasse stellt Methoden zur Verfügung, um eine
Unix-Kommandozeile zu konstruieren. Die Klasse ist hilfreich, wenn
einzelne Bestandteile der Kommandozeile nicht statisch sind,
sondern variieren können.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $c = $class->new;
    $c = $class->new($str);

=head4 Arguments

=over 4

=item $str

Anfang der Kommandozeile.

=back

=head4 Returns

Kommandozeilen-Objekt

=head4 Description

Instantiiere ein Kommandozeilen-Objekt und liefere eine Referenz
auf dieses Objekt zurück. Mit $str kann der Anfang der Kommandozeile
festgelegt werden.

=head4 Example

Erzeuge eine Kommandozeile für das Kommando C<enscript>:

    $c = Quiq::CommandLine->new('enscript');

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $cmd = shift // '';

    # Instantiiere Objekt
    
    return $class->SUPER::new(
        cmd => $cmd,
    );
}
    

# -----------------------------------------------------------------------------

=head2 Kommandozeilenbestandteile hinzufügen

=head3 addArgument() - Ergänze Argumente

=head4 Synopsis

    $cmd->addArgument(@args);

=head4 Arguments

=over 4

=item @args

Liste von Kommandozeilenargumenten.

=back

=head4 Returns

nichts

=head4 Description

Ergänze die Kommandozeile um 0, 1 oder mehr Argumente. Leerzeichen
werden vor jedem Argument hinzugefügt. Enthält ein Argument
Leerzeichen oder Shell-Metazeichen, wird es Quotes eingefasst.
Ist ein Argument leer (undef oder ''), wird ein Leerstring zur
Kommandozeile hinzugefügt.

=head4 Example

    $c->addArgument("/tmp/preview-$$.pdf",'',"Dies ist ein Test");

ergänzt die Kommandozeile um die drei Argumente

    ... /tmp/preview-4711.pdf '' 'Dies ist ein Test'

=cut

# -----------------------------------------------------------------------------

sub addArgument {
    my $self = shift;
    # @_: @args

    my $ref = $self->getRef('cmd');
        
    while (@_) {
        my $arg = $self->value(shift);

        # Leere Argumente sind erlaubt

        if (!defined($arg) || $arg eq '') {
            $arg = "''";
        }

        if (length $$ref) {
            $$ref .= ' ';
        }
        $$ref .= $arg;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 addBoolOption() - Ergänze boolsche Optionen

=head4 Synopsis

    $cmd->addBoolOption(@boolOptions);

=head4 Arguments

=over 4

=item @boolOptions

Liste von boolschen Optionen, bestehend jeweils aus der Option und
zugehörigem Prädikat.

=back

=head4 Returns

nichts

=head4 Description

Ergänze die Kommandozeile um 0, 1 oder mehr boolsche Optionen.
Eine boolsche Option ist eine Option, die keinen Wert hat,
sondern vorhanden ist oder nicht, was durch das zugeörige
Prädikat bestimmt wird (siehe Beispiel).

=head4 Example

    $c->addBoolOption(
        '--no-header' => 1,
        '--landscape' => 0,
        '--truncate-lines' => 1,
    );

ergänzt die Kommandozeile um die Optionen C<--no-header> und
C<--truncate-lines>, aber nicht um die Option C<--landscape>

    ... --no-header --truncate-lines

=cut

# -----------------------------------------------------------------------------

sub addBoolOption {
    my $self = shift;
    # @_: @optBool

    my $ref = $self->getRef('cmd');
        
    while (@_) {
        my $opt = shift;
        if (shift) {
            if (length $$ref) {
                $$ref .= ' ';
            }
            $$ref .= $opt;
        }
    }    

    return;
}

# -----------------------------------------------------------------------------

=head3 addOption() - Ergänze Option und ihre Werte

=head4 Synopsis

    $cmd->addOption(@optVal);

=head4 Arguments

=over 4

=item @optVal

Liste von Optionen, bestehend jeweils aus der Option und
zugehörigem Wert.

=back

=head4 Returns

nichts

=head4 Description

Ergänze die Kommandozeile um 0, 1 oder mehr Optionen mit
zugehörigem Wert. Option und Wert werden durch ein Leerzeichen
getrennt.

=cut

# -----------------------------------------------------------------------------

sub addOption {
    my $self = shift;
    # @_: @optVal

    my $ref = $self->getRef('cmd');
        
    while (@_) {
        my $opt = shift;
        my $val = shift;

        # Wir fügen das Option/Wert-Paar nur hinzu, wenn der Wert
        # definiert und kein Leerstring ist

        if (defined($val) && $val ne '') {
            if (length $$ref) {
                $$ref .= ' ';
            }
            $$ref .= $opt.' '.$self->value($val);
        }
    }    

    return;
}

# -----------------------------------------------------------------------------

=head3 addEqOption() - Ergänze Option und ihre Werte

=head4 Synopsis

    $cmd->addEqOption(@optVal);

=head4 Alias

addLongOption()

=head4 Arguments

=over 4

=item @optVal

Liste von Optionen, bestehend jeweils aus der Option und
zugehörigem Wert.

=back

=head4 Returns

nichts

=head4 Description

Ergänze die Kommandozeile um 0, 1 oder mehr Optionen mit
zugehörigem Wert. Option und Wert werden durch ein
Gleichheitszeichen (=) getrennt.

=head4 Example

    $c->addEqOption(
        '--columns' => 2,
        '--font' => 'Courier10',
        '--margins' => '0:0:0:0',
    );

ergänzt die Kommandozeile um die Optionen

    ... --columns=2 --font=Courier10 --margins=0:0:0:0

=cut

# -----------------------------------------------------------------------------

sub addEqOption {
    my $self = shift;
    # @_: @optVal

    my $ref = $self->getRef('cmd');
        
    while (@_) {
        my $opt = shift;
        my $val = $self->value(shift);

        # Wir fügen das Option/Wert-Paar nur hinzu, wenn der Wert
        # definiert und kein Leerstring ist

        if (defined($val) && $val ne '') {
            if (length $$ref) {
                $$ref .= ' ';
            }
            $$ref .= $opt.'='.$val;
        }
    }    

    return;
}

{
    no warnings 'once';
    *addLongOption = \&addEqOption;
}

# -----------------------------------------------------------------------------

=head3 addString() - Ergänze Zeichenketten

=head4 Synopsis

    $cmd->addString(@strings);

=head4 Arguments

=over 4

=item @strings

Liste von Zeichenketten.

=back

=head4 Returns

nichts

=head4 Description

Ergänze die Kommandozeile um 0, 1 oder mehr Zeichenketten.
Diese werden, mit Whitespace getrennt, unverändert zur
Kommandozeile hinzugefügt.

=head4 Example

    $c->addString('2>/dev/null','|','ps2pdf','-','-');

ergänzt die Kommandozeile um

    ... 2>/dev/null | ps2pdf - -

=cut

# -----------------------------------------------------------------------------

sub addString {
    my $self = shift;
    # @_: @strings

    my $ref = $self->getRef('cmd');
        
    while (@_) {
        my $str = shift;
    
        # Wir fügen den String nur hinzu, wenn der Wert
        # definiert und kein Leerstring ist

        if (defined($str) && $str ne '') {
            if (length $$ref) {
                $$ref .= ' ';
            }
            $$ref .= $str;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Kommandozeile

=head3 command() - Liefere Kommandozeile

=head4 Synopsis

    $cmd = $c->command;

=head4 Returns

Kommandozeile (String)

=head4 Description

Liefere die Kommandozeile als Zeichenkette, wie sie z.B. von der
Shell ausgeführt werden kann.

=cut

# -----------------------------------------------------------------------------

sub command {
    return shift->{'cmd'};
}

# -----------------------------------------------------------------------------

=head2 Hilfsmethoden

=head3 value() - Liefere Options- oder Argumentwert

=head4 Synopsis

    $str2 = $this->value($str1);

=head4 Arguments

=over 4

=item $str1

Zeichenkette.

=back

=head4 Returns

Shellverträglichen Wert (String)

=head4 Description

Analysiere Zeichenkette $str1 auf Whitespace und Shell-Metazeichen
hin und liefere einen Wert, der gefahrlos als Optionswert oder
Programmargument zur Kommandozeile hinzugefügt werden kann.

=head4 Examples

Undef:

    $c->value(undef);
    =>
    undef

Leerstring:

    $c->value("");
    =>
    ''

Zeichenkette ohne Whitespace oder Shell-Metazeichen:

    $c->value("/tmp/test.pdf");
    =>
    /tmp/test.pdf

Zeichenkette mit Whitespace und/oder Shell-Metazeichen:

    $c->value("Dies ist ein Test");
    =>
    'Dies ist ein Test'

=cut

# -----------------------------------------------------------------------------

sub value {
    my ($this,$str) = @_;

    if (!defined($str) || $str =~ m|^([\w/:+-.]+)$|) {
        return $str;
    }
    
    return "'$str'";
}

# -----------------------------------------------------------------------------

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
