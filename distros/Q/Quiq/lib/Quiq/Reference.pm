package Quiq::Reference;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Reference - Operationen auf Referenzen

=head1 DESCRIPTION

Die Klasse stellt Methoden auf Referenzen zur Verfügung, insbesondere,
um den Grundtyp einer Referenz zu ermitteln.

=head1 METHODS

=head2 Klassenmethoden

=head3 refType() - Liefere Grundtyp der Referenz

=head4 Synopsis

    $refType = $class->refType($ref);

=head4 Alias

reftype()

=head4 Description

Ist $ref eine Referenz, liefere den Grundtyp der Referenz. Ist $ref
keine Referenz, liefere einen Leerstring.

Grundtypen sind:

    SCALAR
    ARRAY
    HASH
    CODE
    GLOB
    IO
    REF

Details siehe: C<perldoc -f ref>.

=cut

# -----------------------------------------------------------------------------

sub refType {
    return Scalar::Util::reftype($_[1]) // '';
}

{
    no warnings 'once';
    *reftype = \&refType;
}

# -----------------------------------------------------------------------------

=head3 isBlessedRef() - Test, ob Referenz geblesst ist

=head4 Synopsis

    $bool = $class->isBlessedRef($ref);

=head4 Alias

isBlessed()

=cut

# -----------------------------------------------------------------------------

sub isBlessedRef {
    my ($class,$ref) = @_;
    return Scalar::Util::blessed($ref)? 1: 0;
}

{
    no warnings 'once';
    *isBlessed = \&isBlessedRef;
}

# -----------------------------------------------------------------------------

=head3 isArrayRef() - Teste auf Array-Referenz

=head4 Synopsis

    $bool = $class->isArrayRef($ref);

=cut

# -----------------------------------------------------------------------------

sub isArrayRef {
    my ($class,$ref) = @_;
    $ref = Scalar::Util::reftype($ref);
    return defined $ref && $ref eq 'ARRAY'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isHashRef() - Teste auf Hash-Referenz

=head4 Synopsis

    $bool = $class->isHashRef($ref);

=cut

# -----------------------------------------------------------------------------

sub isHashRef {
    my ($class,$ref) = @_;
    $ref = Scalar::Util::reftype($ref);
    return defined $ref && $ref eq 'HASH'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isCodeRef() - Teste auf Code-Referenz

=head4 Synopsis

    $bool = $class->isCodeRef($ref);

=cut

# -----------------------------------------------------------------------------

sub isCodeRef {
    my ($class,$ref) = @_;
    $ref = Scalar::Util::reftype($ref);
    return defined $ref && $ref eq 'CODE'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isRegexRef() - Teste auf Regex-Referenz

=head4 Synopsis

    $bool = $class->isRegexRef($ref);

=head4 Caveats

Wenn die Regex-Referenz umgeblesst wurde, muss sie auf
eine Subklasse von Regex geblesst worden sein, sonst schlägt
der Test fehl. Aktuell gibt es nicht den Grundtyp REGEX, der
von reftype() geliefert würde, sondern eine Regex-Referenz gehört
standardmäßig zu der Klasse Regex.

=cut

# -----------------------------------------------------------------------------

sub isRegexRef {
    my ($class,$ref) = @_;
    return Scalar::Util::blessed($ref) && $ref->isa('Regexp')? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
