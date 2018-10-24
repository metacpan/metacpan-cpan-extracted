use utf8;

package SemanticWeb::Schema::TaxiService;

# ABSTRACT: A service for a vehicle for hire with a driver for local travel

use Moo;

extends qw/ SemanticWeb::Schema::Service /;


use MooX::JSON_LD 'TaxiService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TaxiService - A service for a vehicle for hire with a driver for local travel

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A service for a vehicle for hire with a driver for local travel. Fares are
usually calculated based on distance traveled.

=head1 SEE ALSO

L<SemanticWeb::Schema::Service>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
