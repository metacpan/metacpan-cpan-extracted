package Quiq::Test::Class::Method;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Test::Class::Method - Testmethode

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse Quiq::Test::Class::Method repräsentiert eine
Testmethode. Das Objekt kapselt Paketnamen, Methodennamen,
Codereferenz, Anzahl der Tests, den Type der Testmethode
und den Gruppen-Regex, sofern vorhanden.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Testmethodenobjekt

=head4 Synopsis

    $meth = $class->new($pkg,$ref,$type,$n,$group);

=head4 Description

Instantiiere Testmethodenobjekt für Klasse $pkg, Methode $ref
(Codereferenz), Methodentyp $type (Init, Foreach, Startup, Setup, Test,
Teardown, Shutdown), Anzahl Tests $n und Gruppenregex $group.
Liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $pkg = shift;
    my $ref = shift;
    my $type = shift;
    my $n = shift;
    my $group = shift; # nur Setup, Teardown

    $group = qr/$group/ if $group;

    return bless [$pkg,$ref,$type,$n,$group,undef],$class;
}

# -----------------------------------------------------------------------------

=head2 Methoden

=head3 class() - Liefere Name der getesteten Klasse

=head4 Synopsis

    $class = $meth->class;

=head4 Description

Liefere den Namen der getesteten Klasse.

=cut

# -----------------------------------------------------------------------------

sub class {
    return shift->[0];
}

# -----------------------------------------------------------------------------

=head3 code() - Liefere Codereferenz

=head4 Synopsis

    $ref = $meth->code;

=head4 Description

Liefere Codereferenz.

=cut

# -----------------------------------------------------------------------------

sub code {
    return shift->[1];
}

# -----------------------------------------------------------------------------

=head3 group() - Liefere Gruppen-Regex

=head4 Synopsis

    $regex = $meth->group;

=head4 Description

Liefere Gruppen-Regex.

=cut

# -----------------------------------------------------------------------------

sub group {
    return shift->[4];
}

# -----------------------------------------------------------------------------

=head3 name() - Liefere Methodennamen

=head4 Synopsis

    $name = $meth->name;

=head4 Description

Liefere den Methodennamen.

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;

    unless ($self->[5]) {
        my $pkg = $self->class;
        my $ref = $self->code;

        no strict 'refs';
        for my $sym (values %{$pkg.'::'})
        {
            if (*{$sym}{'CODE'} && *{$sym}{'CODE'} == $ref)
            {
                $sym =~ /([^:]+)$/; # Paketnamen entfernen
                return $self->[5] = $1;
            }
        }
        $self->throw(
            'TEST-00001: Test-Subroutine nicht gefunden',
            Package => $pkg,
            Reference => $ref,
        );
    }

    return $self->[5];
}

# -----------------------------------------------------------------------------

=head3 tests() - Liefere Anzahl Tests

=head4 Synopsis

    $n = $meth->tests;

=head4 Description

Liefere die Anzahl der Tests in der Testmethode.

=cut

# -----------------------------------------------------------------------------

sub tests {
    return shift->[3];
}

# -----------------------------------------------------------------------------

=head3 type() - Liefere Typ der Testmethode

=head4 Synopsis

    $type = $meth->type;

=head4 Description

Liefere den Type der Testmethode.

=cut

# -----------------------------------------------------------------------------

sub type {
    return shift->[2];
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
