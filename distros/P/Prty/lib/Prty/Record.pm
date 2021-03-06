package Prty::Record;
use base qw/Prty::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.128;

use Prty::String;
use Prty::Option;
use Prty::Path;
use Prty::String;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Record - Verarbeitung von Text-Records

=head1 BASE CLASS

L<Prty::Object>

=head1 DESCRIPTION

Ein Text-Record ist eine Folge von Schlüssel/Wert-Paaren
in Textform, wobei

=over 2

=item *

ein Schlüssel eine Folge von alphanumerischen Zeichen oder
Unterstrich ('_') oder Bindestrich ('-') ist, und

=item *

ein Wert ein beliebiger einzeiliger oder mehrzeiliger Text ist.

=back

Stringrepräsentation:

    Schlüssel1:
        Wert1
    Schlüssel2:
        Wert2
    ...

oder

    Schlüssel1: Wert1
    Schlüssel2: Wert2
    ...

oder ein Mischung aus beidem.

=head1 METHODS

=head2 Klassenmethoden

=head3 fromString() - Lies Schlüssel/Wert-Paare aus String

=head4 Synopsis

    @keyVal | $keyValA = $class->fromString($str);
    @keyVal | $keyValA = $class->fromString(\$str);

=head4 Description

Lies Text-Record aus Zeichenkette $str, zerlege ihn in
Schlüssel/Wert-Paare und liefere die Liste der
Schlüssel/Wert-Paare zurück. Im Skalarkontext liefere eine
Referenz auf die Liste.

=over 2

=item *

NEWLINEs am Anfang und am Ende eines Werts werden entfernt.

=item *

Eine Einrückung innerhalb eines mehrzeiligen Werts wird entfernt.
Eine Einrückung ist die längste Folge von Leerzeichen oder Tabs, die
allen Zeilen eines mehrzeiligen Werts gemeinsam ist.

=back

=cut

# -----------------------------------------------------------------------------

sub fromString {
    my $class = shift;
    # @_: $str -or- \$str

    my $ref;
    if (!defined $_[0]) { # undef
        $ref = \'';
    }
    elsif (ref $_[0]) {   # String-Ref
        $ref = $_[0];
    }
    else {
        $ref = \$_[0];    # String
    }

    my @keys = $$ref =~ /^([\w-]+) *[:=] */gm;
    my @vals = split /^[\w-]+ *[:=] */m,$$ref;
    shift @vals;

    my @arr;
    $#arr = @keys*2-1;

    for (my $i = 0; $i < @keys; $i++) {
        $arr[$i*2] = $keys[$i];
        my $val = Prty::String->removeIndentation($vals[$i]);
        $arr[$i*2+1] = $val;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 fromFile() - Lies Schlüssel/Wert-Paare aus Datei

=head4 Synopsis

    @keyVal | $keyValA = $class->fromFile($file,@opt);

=head4 Arguments

=over 4

=item $file

Datei, die den Record enthält.

=back

=head4 Options

=over 4

=item -encoding => $encoding

Character Encoding, z.B. 'UTF-8'.

=back

=head4 Description

Wie L</fromString>, nur dass der Record aus Datei $file gelesen wird.

=cut

# -----------------------------------------------------------------------------

sub fromFile {
    my ($class,$file) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $encoding = undef;

    Prty::Option->extract(\@_,
        -encoding => \$encoding,
    );

    return $class->fromString(Prty::Path->read($file,-decode=>$encoding));
}

# -----------------------------------------------------------------------------

=head3 toString() - Schreibe Schlüssel/Wert-Paare auf String

=head4 Synopsis

    $str = $class->toString(@keyVal,@opt);
    $str = $class->toString(\@keyVal,@opt);

=head4 Options

=over 4

=item -indent => $n (Default: 4)

Tiefe der Einrückung.

=item -ignoreNull => $bool (Default: 0)

Ignoriere Schlüssel/Wert-Paare, bei denen der Wert null ist.

=item -space => $n (Default: 0)

Anzahl Leerzeilen zwischen den Einträgen.

=item -strip => $bool (Default: 1)

Entferne Leerzeilen am Anfang und Whitespace am Ende des Werts.

=back

=head4 Description

Generiere für die Schlüssel/Wert-Paare @keyVal eine Text-Record
Repräsentation und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub toString {
    my $class = shift;
    my $arr = ref $_[0]? shift: \@_;
    # @_: Argumente

    my $indent = 4;
    my $ignoreNull = 0;
    my $space = 0;
    my $strip = 1;

    Prty::Option->extract(\@_,
        -indent=>\$indent,
        -ignoreNull=>\$ignoreNull,
        -space=>\$space,
        -strip=>\$strip,
    );

    $indent = ' ' x $indent;
    $space = "\n" x $space;

    my $str = '';
    for (my $i = 0; $i < @$arr; $i += 2) {
        my $key = $arr->[$i];
        my $val = $arr->[$i+1];

        if (!defined $val) {
            $val = '';
        }
        if ($strip) {
            $val =~ s/^\n+//;
            $val =~ s/\s+$//;
        }
        if ($val eq '' && $ignoreNull) {
            next;
        }
        if ($indent) {
            Prty::String->indent(\$val,$indent);
        }
        if ($space && $str) {
            $str .= $space;
        }
        
        $str .= sprintf "%s:\n%s\n",$key,$val;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 toFile() - Schreibe Schlüssel/Wert-Paare auf Datei

=head4 Synopsis

    $class->toFile($file,@keyVal,@opt);
    $class->toFile($file,\@keyVal,@opt);

=head4 Options

Siehe L</toString>

=head4 Description

Wie L</toString>, nur dass der Record auf eine Datei geschrieben wird.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub toFile {
    my $class = shift;
    my $file = shift;
    # @_: siehe toString()

    Prty::Path->write($file,$class->toString(@_));    
    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.128

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
