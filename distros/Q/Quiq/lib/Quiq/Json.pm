# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Json - Operationen auf JSON Code

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Json;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use JSON ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 pretty() - Verschönere JSON Code

=head4 Synopsis

  $json = $class->pretty($file);
  $json = $class->pretty($jsonIn);

=head4 Arguments

=over 4

=item $file

(String) Datei mit JSON Code, der verschönert werden soll

=item $jsonIn

(String) JSON Code, der verschönert werden soll

=back

=head4 Returns

(String) Verschönerter JSON Code

=head4 Description

Verschönere den JSON Code $jsonIn und liefere de resultierenden JSON Code
zurück.

Enthält der Parameter der Methode weder Doppelpunkt (:) noch geschweifte
Klammer auf ({}, wird er als Dateiname angesehen.

=cut

# -----------------------------------------------------------------------------

sub pretty {
    my $class = shift;

    my $json = $_[0] =~ /[{:]/? shift:
        Quiq::Path->read(shift,-decode=>'utf-8');

    my $j = JSON->new->allow_nonref;
    my $h = $j->decode($json);

    return $j->pretty->encode($h);
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
