# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM code


package SIRTX::VM;

use v5.16;
use strict;
use warnings;

use Carp;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.05;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM - module for interacting with SIRTX VM code

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use SIRTX::VM;

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
