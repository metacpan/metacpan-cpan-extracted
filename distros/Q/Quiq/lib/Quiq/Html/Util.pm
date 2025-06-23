# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Util - Hilfsmethoden für die HTML-Generierung

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Util;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Time::HiRes ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 insertDurationBytes() - Füge Ausführungszeit und Byteanzahl ein

=head4 Synopsis

  $class->insertDurationBytes(\$html,$t0);
  $html2 = $class->insertDurationBytes($html1,$t0);

=cut

# -----------------------------------------------------------------------------

sub insertDurationBytes {
    my ($class,$arg,$t0) = @_;

    my $ref = ref $arg? $arg: \$arg;

    my $duration = sprintf '%.3f',Time::HiRes::gettimeofday-$t0;
    if ($duration < 0.001) {
        $duration = 0.001;
    }
    $$ref =~ s/__DURATION__/$duration/g;

    require bytes;
    my $bytes = bytes::length($$ref);
    $bytes += length($bytes)-length('__BYTES__');
    $$ref =~ s/__BYTES__/$bytes/g;

    return ref $arg? (): $$ref;
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
