package Salvation::UpdateGvFLAGS;

=head1 NAME

Salvation::UpdateGvFLAGS - Modifies GvFLAGS of a given SV

=head1 SYNOPSIS

    Salvation::UpdateGvFLAGS::toggle( *asd::qwe, 0x80 );

=cut

use strict;
use warnings;

use B 'svref_2object';

our $VERSION = 0.01;

require XSLoader;

XSLoader::load( 'Salvation::UpdateGvFLAGS', $VERSION );

=head1 FUNCTIONS

=cut

=head2 toggle( sv, flag )

Toggles given flag within GvFLAGS of an SV.

=cut

=head2 toggle_glob_flag_by_name( name, flag )

An alias for C<toggle>.

Example usage:
    package asd;
    sub qwe {}
    package main;
    Salvation::UpdateGvFLAGS::toggle_glob_flag_by_name( 'asd::qwe', 0x80 );

=cut

sub toggle_glob_flag_by_name {

    my ( $name, $flag ) = @_;
    my $ref = do {

        no strict 'refs';
        \*$name;
    };

    return toggle_glob_flag_by_globref( $ref, $flag );
}

=head2 toggle_glob_flag_by_globref( ref, flag )

An alias for C<toggle>.

Example usage:
    package asd;
    sub qwe {}
    package main;
    Salvation::UpdateGvFLAGS::toggle_glob_flag_by_globref( \*asd::qwe, 0x80 );

=cut

sub toggle_glob_flag_by_globref {

    my ( $ref, $flag ) = @_;

    return Salvation::UpdateGvFLAGS::toggle( *$ref, $flag );
}

=head2 toggle_glob_flag_by_coderef( ref, flag )

An alias for C<toggle>.

Example usage:
    package asd;
    sub qwe {}
    package main;
    Salvation::UpdateGvFLAGS::toggle_glob_flag_by_coderef( \&asd::qwe, 0x80 );

=cut

sub toggle_glob_flag_by_coderef {

    my ( $ref, $flag ) = @_;
    my $o = svref_2object( $ref );
    my $gv = $o -> GV();

    return toggle_glob_flag_by_name( sprintf( '%s::%s', (
        $gv -> STASH() -> NAME(),
        $gv -> NAME(),

    ) ), $flag );
}

1;

__END__
