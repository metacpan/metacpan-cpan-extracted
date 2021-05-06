#!perl
#PODNAME: Raisin::Encoder::JSON
#ABSTRACT: JSON serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::JSON;
$Raisin::Encoder::JSON::VERSION = '0.93';
use JSON::MaybeXS qw();

my $json = JSON::MaybeXS->new(utf8 => 1);

sub detectable_by { [qw(application/json text/x-json text/json json)] }

sub content_type { 'application/json; charset=utf-8' }

sub serialize { $json->allow_blessed->convert_blessed->encode($_[1]) }

sub deserialize { $json->allow_blessed->convert_blessed->decode($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Encoder::JSON - JSON serialization plugin for Raisin.

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
