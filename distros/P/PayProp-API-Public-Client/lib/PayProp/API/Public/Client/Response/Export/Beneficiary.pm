package PayProp::API::Public::Client::Response::Export::Beneficiary;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::JSON /;


has id                 => (is => 'ro', isa => 'Str' );
has is_owner           => (is => 'ro', isa => 'Bool');
has owner_app          => (is => 'ro', isa => 'Bool');
has international      => (is => 'ro', isa => 'Bool');
has notify_email       => (is => 'ro', isa => 'Bool');
has notify_sms         => (is => 'ro', isa => 'Bool');
has is_active_owner    => (is => 'ro', isa => 'Bool');
has customer_id        => (is => 'ro', isa => 'Maybe[Str]' );
has comment            => (is => 'ro', isa => 'Maybe[Str]' );
has business_name      => (is => 'ro', isa => 'Maybe[Str]' );
has email_address      => (is => 'ro', isa => 'Maybe[Str]' );
has email_cc_address   => (is => 'ro', isa => 'Maybe[Str]' );
has customer_reference => (is => 'ro', isa => 'Maybe[Str]' );
has first_name         => (is => 'ro', isa => 'Maybe[Str]' );
has id_type_id         => (is => 'ro', isa => 'Maybe[Str]' );
has last_name          => (is => 'ro', isa => 'Maybe[Str]' );
has mobile_number      => (is => 'ro', isa => 'Maybe[Str]' );
has vat_number         => (is => 'ro', isa => 'Maybe[Str]' );
has id_reg_number      => (is => 'ro', isa => 'Maybe[Str]' );
has billing_address    => (is => 'ro', isa => 'Maybe[PayProp::API::Public::Client::Response::Export::Beneficiary::Address]');
has properties         => (is => 'ro', isa => 'ArrayRef[PayProp::API::Public::Client::Response::Export::Beneficiary::Property]');

__PACKAGE__->meta->make_immutable;
