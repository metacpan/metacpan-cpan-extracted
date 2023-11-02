package PayProp::API::Public::Client::Response::Export::Tenant::Property;

use strict;
use warnings;

use Mouse;


has id                               => ( is => 'ro', isa => 'Str' );
has property_name                    => ( is => 'ro', isa => 'Str' );
has allow_payments                   => ( is => 'ro', isa => 'Bool' );
has approval_required                => ( is => 'ro', isa => 'Bool' );
has hold_all_owner_funds             => ( is => 'ro', isa => 'Bool' );
has comment                          => ( is => 'ro', isa => 'Maybe[Str]' );
has listed_from                      => ( is => 'ro', isa => 'Maybe[Str]' );
has listed_until                     => ( is => 'ro', isa => 'Maybe[Str]' );
has account_balance                  => ( is => 'ro', isa => 'Maybe[Num]' );
has responsible_agent                => ( is => 'ro', isa => 'Maybe[Str]' );
has customer_reference               => ( is => 'ro', isa => 'Maybe[Str]' );
has responsible_agent_id             => ( is => 'ro', isa => 'Maybe[Str]' );
has monthly_payment_required         => ( is => 'ro', isa => 'Maybe[Num]' );
has responsible_user                 => ( is => 'ro', isa => 'Maybe[Int]' );
has property_account_minimum_balance => ( is => 'ro', isa => 'Maybe[Str]' );

__PACKAGE__->meta->make_immutable;
