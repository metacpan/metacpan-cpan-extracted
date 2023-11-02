package PayProp::API::Public::Client::Response::Entity::Payment;

use strict;
use warnings;

use Mouse;
use Mouse::Util::TypeConstraints;
with qw/ PayProp::API::Public::Client::Role::JSON /;

subtype 'NumOrStr' => as 'Num | Str';

has id                    => ( is => 'ro', isa => 'Str' );
has tax                   => ( is  => 'ro', isa => 'Maybe[NumOrStr]' );
has amount                => ( is => 'ro', isa => 'Num' );
has enabled               => ( is => 'ro', isa => 'Bool' );
has has_tax               => ( is => 'ro', isa => 'Bool' );
has end_date              => ( is => 'ro', isa => 'Maybe[Str]' );
has reference             => ( is => 'ro', isa => 'Str' );
has tenant_id             => ( is => 'ro', isa => 'Maybe[Str]' );
has frequency             => ( is => 'ro', isa => 'Str' );
has tax_amount            => ( is  => 'ro', isa => 'Maybe[NumOrStr]' );
has start_date            => ( is => 'ro', isa => 'Str' );
has percentage            => ( is  => 'ro', isa => 'Maybe[NumOrStr]' );
has payment_day           => ( is => 'ro', isa => 'Int' );
has customer_id           => ( is => 'ro', isa => 'Maybe[Str]' );
has description           => ( is => 'ro', isa => 'Maybe[Str]' );
has property_id           => ( is => 'ro', isa => 'Str' );
has category_id           => ( is => 'ro', isa => 'Str' );
has use_money_from        => ( is => 'ro', isa => 'Str' );
has beneficiary_id        => ( is => 'ro', isa => 'Str' );
has beneficiary_type      => ( is => 'ro', isa => 'Str' );
has global_beneficiary    => ( is => 'ro', isa => 'Maybe[Str]' );
has no_commission_amount  => ( is => 'ro', isa => 'Maybe[Num]' );
has maintenance_ticket_id => ( is => 'ro', isa => 'Maybe[Str]' );

__PACKAGE__->meta->make_immutable;
