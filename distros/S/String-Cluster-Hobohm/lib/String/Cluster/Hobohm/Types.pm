package String::Cluster::Hobohm::Types;
$String::Cluster::Hobohm::Types::VERSION = '0.141020';
use strict;
use warnings;

# ABSTRACT: Specific types for String::Cluster::Hobohm;

use MouseX::Types -declare => ['Quotient'];
use MouseX::Types::Mouse 'Num';

subtype Quotient, as Num, where { $_ >= 0 && $_ <= 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Cluster::Hobohm::Types - Specific types for String::Cluster::Hobohm;

=head1 VERSION

version 0.141020

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
