package PayProp::API::Public::Client::Response::Export::Tenant::Address;

use strict;
use warnings;

use Mouse;


has id           => ( is => 'ro', isa => 'Str' );
has created      => ( is => 'ro', isa => 'Str' );
has modified     => ( is => 'ro', isa => 'Str' );
has fax          => ( is => 'ro', isa => 'Maybe[Str]' );
has city         => ( is => 'ro', isa => 'Maybe[Str]' );
has email        => ( is => 'ro', isa => 'Maybe[Str]' );
has phone        => ( is => 'ro', isa => 'Maybe[Str]' );
has state        => ( is => 'ro', isa => 'Maybe[Str]' );
has zip_code     => ( is => 'ro', isa => 'Maybe[Str]' );
has latitude     => ( is => 'ro', isa => 'Maybe[Str]' );
has longitude    => ( is => 'ro', isa => 'Maybe[Str]' );
has first_line   => ( is => 'ro', isa => 'Maybe[Str]' );
has third_line   => ( is => 'ro', isa => 'Maybe[Str]' );
has postal_code  => ( is => 'ro', isa => 'Maybe[Str]' );
has second_line  => ( is => 'ro', isa => 'Maybe[Str]' );
has country_code => ( is => 'ro', isa => 'Maybe[Str]' );

__PACKAGE__->meta->make_immutable;
