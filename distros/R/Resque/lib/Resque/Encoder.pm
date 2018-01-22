package Resque::Encoder;
# ABSTRACT: Moose role for encoding Resque structures
$Resque::Encoder::VERSION = '0.35';
use Moose::Role;
use JSON;

has encoder => ( is => 'ro', default => sub { JSON->new->utf8 } );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Resque::Encoder - Moose role for encoding Resque structures

=head1 VERSION

version 0.35

=head1 ATTRIBUTES

=head2 encoder

JSON encoder by default.

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
