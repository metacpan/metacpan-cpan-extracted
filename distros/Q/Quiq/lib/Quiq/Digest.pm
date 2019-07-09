package Quiq::Digest;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Digest::MD5 ();

# -----------------------------------------------------------------------------

=head1 NAME

Quiq::Digest - Erzeuge Digest

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 md5() - MD5 Digest

=head4 Synopsis

    $md5 = $class->md5($str);

=cut

# -----------------------------------------------------------------------------

sub md5 {
    my $class = shift;
    # @_: $str
    return Digest::MD5::md5_hex($_[0]);
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
