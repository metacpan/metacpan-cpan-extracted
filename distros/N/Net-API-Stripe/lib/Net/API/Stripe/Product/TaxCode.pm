##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Product/TaxCode
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/24
## Modified 2022/01/24
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Product::TaxCode;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product::TaxCode - The tax code object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<Tax codes|Tax codes> classify goods and services for tax purposes.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 description string

A detailed description of which types of products the tax code represents.

=head2 name string

A short name for the tax code.

=head1 API SAMPLE

    {
      "id": "txcd_99999999",
      "object": "tax_code",
      "description": "Any tangible or physical good. For jurisdictions that impose a tax, the standard rate is applied.",
      "name": "General - Tangible Goods"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api#tax_code_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
