package Stancer::Core::Types::Bank::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::Bank qw(:all);

has an_amount => (
    is => 'ro',
    isa => Amount,
);

has a_bic => (
    is => 'ro',
    isa => Bic,
);

has a_card_number => (
    is => 'ro',
    isa => CardNumber,
);

has a_card_verification_code => (
    is => 'ro',
    isa => CardVerificationCode,
);

has a_currency => (
    is => 'ro',
    isa => Currency,
);

has an_iban => (
    is => 'ro',
    isa => Iban,
);

1;
