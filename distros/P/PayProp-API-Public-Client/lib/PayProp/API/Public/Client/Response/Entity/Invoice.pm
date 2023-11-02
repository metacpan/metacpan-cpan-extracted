package PayProp::API::Public::Client::Response::Entity::Invoice;

use strict;
use warnings;

use Mouse;
use Mouse::Util::TypeConstraints;
with qw/ PayProp::API::Public::Client::Role::JSON /;


has id                  => ( is => 'ro', isa => 'Str' );
has tax                 => ( is  => 'ro', isa => 'Maybe[NumOrStr]' );
has amount              => ( is => 'ro', isa => 'Num' );
has has_tax             => ( is => 'ro', isa => 'Bool' );
has end_date            => ( is => 'ro', isa => 'Maybe[Str]' );
has frequency           => ( is => 'ro', isa => 'Maybe[Str]' );
has tenant_id           => ( is => 'ro', isa => 'Maybe[Str]' );
has start_date          => ( is => 'ro', isa => 'Maybe[Str]' );
has deposit_id          => ( is => 'ro', isa => 'Maybe[Str]' );
has tax_amount          => ( is  => 'ro', isa => 'Maybe[NumOrStr]' );
has category_id         => ( is => 'ro', isa => 'Maybe[Str]' );
has customer_id         => ( is => 'ro', isa => 'Maybe[Str]' );
has payment_day         => ( is => 'ro', isa => 'Int' );
has property_id         => ( is => 'ro', isa => 'Maybe[Str]' );
has description         => ( is => 'ro', isa => 'Maybe[Str]' );
has is_direct_debit     => ( is => 'ro', isa => 'Bool' );
has has_invoice_period  => ( is => 'ro', isa => 'Bool' );

__PACKAGE__->meta->make_immutable;
