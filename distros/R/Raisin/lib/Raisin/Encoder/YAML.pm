#!perl
#PODNAME: Raisin::Encoder::YAML
#ABSTRACT: YAML serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::YAML;
$Raisin::Encoder::YAML::VERSION = '0.93';
use Encode qw(encode_utf8 decode_utf8);
use YAML qw(Dump Load);

sub detectable_by { [qw(application/x-yaml application/yaml text/x-yaml text/yaml yaml)] }
sub content_type { 'application/x-yaml' }
sub serialize { encode_utf8( Dump($_[1]) ) }
sub deserialize { Load( decode_utf8($_[1]) ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Encoder::YAML - YAML serialization plugin for Raisin.

=head1 VERSION

version 0.93

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
