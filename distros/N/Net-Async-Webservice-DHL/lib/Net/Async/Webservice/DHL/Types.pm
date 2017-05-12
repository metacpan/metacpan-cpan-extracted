package Net::Async::Webservice::DHL::Types;
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( Address RouteType CountryCode RegionCode );
use Type::Utils -all;
use Types::Standard -types;
use namespace::autoclean;
our $VERSION = '1.2.2'; # VERSION

# ABSTRACT: type library for DHL


class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

enum RouteType, [qw(O D)];

declare CountryCode, as Str, where { length == 2 };

enum RegionCode, [qw(AP EU AM)];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Types - type library for DHL

=head1 VERSION

version 1.2.2

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::DHL>.

=head1 TYPES

=head2 C<Address>

Instance of L<Net::Async::Webservice::DHL::Address>.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
