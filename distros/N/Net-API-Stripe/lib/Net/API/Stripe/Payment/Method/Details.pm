##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Method/Details.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Method::Details;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Payment::Method::Options );
    use vars qw( $VERSION );
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

sub acss_debit { return( shift->_set_get_class( 'acss_debit',
{
  bank_name => { type => "scalar" },
  fingerprint => { type => "scalar" },
  institution_number => { type => "scalar" },
  last4 => { type => "scalar" },
  mandate => { type => "scalar" },
  transit_number => { type => "scalar" },
}, @_ ) ); }

sub alipay { return( shift->_set_get_class( 'alipay',
{
  buyer_id       => { type => "scalar" },
  fingerprint    => { type => "scalar" },
  transaction_id => { type => "scalar" },
}, @_ ) ); }

sub au_becs_debit { return( shift->_set_get_object( 'au_becs_debit', 'Net::API::Stripe::Billing::PortalSession', @_ ) ); }

sub blik { return( shift->_set_get_class( 'blik',
{
  expires_after => { type => "datetime" },
  off_session => { package => "Net::API::Stripe::Billing::Plan", type => "object" },
  type => { type => "scalar" },
}, @_ ) ); }

sub boleto { return( shift->_set_get_object( 'boleto', 'Net::API::Stripe::Customer::TaxInfo', @_ ) ); }

sub klarna { return( shift->_set_get_class( 'klarna',
{
  payment_method_category => { type => "scalar" },
  preferred_locale        => { type => "scalar" },
}, @_ ) ); }

sub konbini { return( shift->_set_get_class( 'konbini',
{
  store => { definition => { chain => { type => "scalar" } }, type => "class" },
}, @_ ) ); }

sub link { return( CORE::shift->_set_get_hash( 'link', @_ ) ); }

sub paynow { return( CORE::shift->_set_get_object( 'paynow', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub promptpay { return( CORE::shift->_set_get_object( 'promptpay', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub us_bank_account { return( shift->_set_get_object( 'us_bank_account', 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ ) ); }

sub wechat_pay { return( CORE::shift->_set_get_class( 'wechat_pay',
{
  fingerprint    => { type => "scalar" },
  transaction_id => { type => "scalar" },
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Payment::Method::Details - Stripe API

=head1 SYNOPSIS

    use Net::API::Stripe::Payment::Method::Details;
    my $this = Net::API::Stripe::Payment::Method::Details->new || 
        die( Net::API::Stripe::Payment::Method::Details->error, "\n" );

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

This package is called in Stripe api, but is really an alias for L<Net::API::Stripe::Payment::Method::Options> and inherits everything from it.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
