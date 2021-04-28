#!perl
#PODNAME: Raisin::Decoder
#ABSTRACT: A helper for L<Raisin::Middleware::Formatter> over decoder modules

use strict;
use warnings;

package Raisin::Decoder;
$Raisin::Decoder::VERSION = '0.91';
use parent 'Raisin::Encoder';

sub builtin {
    {
        json => 'Raisin::Encoder::JSON',
        yaml => 'Raisin::Encoder::YAML',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Decoder - A helper for L<Raisin::Middleware::Formatter> over decoder modules

=head1 VERSION

version 0.91

=head1 SYNOPSIS

    my $dec = Raisin::Decoder->new;
    $dec->register(xml => 'Some::XML::Parser');
    $dec->for('json');
    $dec->media_types_map_flat_hash;

=head1 DESCRIPTION

Provides an easy interface to use and register decoders.

The interface is identical to L<Raisin::Encoder>.

=head1 METHODS

=head2 builtin

Returns a list of encoders which are bundled with L<Raisin>.
They are: L<Raisin::Encoder::JSON>, L<Raisin::Encoder::YAML>.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
