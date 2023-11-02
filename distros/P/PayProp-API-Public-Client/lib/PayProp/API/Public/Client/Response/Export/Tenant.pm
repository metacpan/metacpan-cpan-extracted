package PayProp::API::Public::Client::Response::Export::Tenant;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::JSON /;


has id                => (is => 'ro', isa => 'Str' );
has notify_sms        => (is => 'ro', isa => 'Bool');
has notify_email      => (is => 'ro', isa => 'Bool');
has invoice_lead_days => (is => 'ro', isa => 'Maybe[Int]' );
has comment           => (is => 'ro', isa => 'Maybe[Str]' );
has status            => (is => 'ro', isa => 'Maybe[Str]' );
has reference         => (is => 'ro', isa => 'Maybe[Str]' );
has id_reg_no         => (is => 'ro', isa => 'Maybe[Str]' );
has customer_id       => (is => 'ro', isa => 'Maybe[Str]' );
has display_name      => (is => 'ro', isa => 'Maybe[Str]' );
has date_of_birth     => (is => 'ro', isa => 'Maybe[Str]' );
has business_name     => (is => 'ro', isa => 'Maybe[Str]' );
has email_address     => (is => 'ro', isa => 'Maybe[Str]' );
has email_cc_address  => (is => 'ro', isa => 'Maybe[Str]' );
has first_name        => (is => 'ro', isa => 'Maybe[Str]' );
has id_type_id        => (is => 'ro', isa => 'Maybe[Str]' );
has last_name         => (is => 'ro', isa => 'Maybe[Str]' );
has mobile_number     => (is => 'ro', isa => 'Maybe[Str]' );
has vat_number        => (is => 'ro', isa => 'Maybe[Str]' );
has id_reg_number     => (is => 'ro', isa => 'Maybe[Str]' );
has address           => (is => 'ro', isa => 'Maybe[PayProp::API::Public::Client::Response::Export::Tenant::Address]');
has properties        => (is => 'ro', isa => 'ArrayRef[PayProp::API::Public::Client::Response::Export::Tenant::Property]');

__PACKAGE__->meta->make_immutable;
