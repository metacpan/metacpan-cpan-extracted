use utf8;

package SemanticWeb::Schema::CurrencyConversionService;

# ABSTRACT: A service to convert funds from one currency to another currency.

use Moo;

extends qw/ SemanticWeb::Schema::FinancialProduct /;


use MooX::JSON_LD 'CurrencyConversionService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CurrencyConversionService - A service to convert funds from one currency to another currency.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A service to convert funds from one currency to another currency.

=head1 SEE ALSO

L<SemanticWeb::Schema::FinancialProduct>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
