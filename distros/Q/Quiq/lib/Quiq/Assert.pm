package Quiq::Assert;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Option;
use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Assert - Zusicherungen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 isNumber() - Prüfe auf dezimale Zahldarstellung

=head4 Synopsis

    $class->isNumber($val,@opt);

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

=head4 Description

Prüfe den Wert $val daraufhin, dass er eine dezimale Zahl
darstellt. Ist dies nicht der Fall, wirf eine Exception.  Ein
leerer Wert wird übergangen.

=cut

# -----------------------------------------------------------------------------

sub isNumber {
    my ($class,$val) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $name = undef;
    
    Quiq::Option->extract(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '') {
        return;
    }

    if (!Quiq::Math->isNumber($val)) {
        $class->throw(
            'ASSERT-00001: Not a number',
            defined $name? (Name => $name): (),
            Value => $val,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 notNull() - Prüfe auf nichtleeren Wert

=head4 Synopsis

    $class->notNull($val,@opt);

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

=head4 Description

Prüfe den Wert $val daraufhin, dass er nichtleer, also weder
undefiniert noch ein Leerstring ist. Ist er leer, wirf
eine Exception.

=cut

# -----------------------------------------------------------------------------

sub notNull {
    my ($class,$val) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $name = undef;
    
    Quiq::Option->extract(\@_,
        -name => \$name,
    );

    # Prüfung

    if (!defined($val) || $val eq '') {
        $class->throw(
            defined $name? (Name => $name): (),
            'ASSERT-00002: Value is null',
        );
    }

    return;
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
