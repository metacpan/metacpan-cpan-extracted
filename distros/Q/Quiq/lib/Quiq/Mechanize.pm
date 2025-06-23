# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Mechanize - Überlagerung von WWW::Mechanize

=head1 BASE CLASSES

=over 2

=item *

WWW::Mechanize

=item *

L<Quiq::Object>

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Mechanize;
use base qw/WWW::Mechanize Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $mech = $class->new(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Attributwerte von WWW::Mechnize und LWP::UserAgent.

=back

=head4 Returns

Object

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    return $class->SUPER::new(
        autocheck => 1,
        stack_depth => 0,
        strict_forms => 1,
        onerror => sub {
            my $msg = join '',@_;                
            $class->throw(
                'MECHANIZE-00001: Fatal error',
                Error => $msg,
            );
        },
        @_,
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
