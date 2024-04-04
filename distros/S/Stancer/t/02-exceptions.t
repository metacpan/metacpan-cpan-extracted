#! /usr/bin/env perl

use 5.020;
use strict;
use warnings;

use lib './t/unit';

use Stancer::Exceptions::Throwable::Test; # Base exception

use Stancer::Exceptions::BadMethodCall::Test;
use Stancer::Exceptions::InvalidArgument::Test;

# Bad method call relative
use Stancer::Exceptions::MissingApiKey::Test;
use Stancer::Exceptions::MissingPaymentId::Test;
use Stancer::Exceptions::MissingPaymentMethod::Test;
use Stancer::Exceptions::MissingReturnUrl::Test;

# Invalid argument relative
use Stancer::Exceptions::InvalidAmount::Test;
use Stancer::Exceptions::InvalidAuthInstance::Test;
use Stancer::Exceptions::InvalidBic::Test;
use Stancer::Exceptions::InvalidCardExpiration::Test;
use Stancer::Exceptions::InvalidCardInstance::Test;
use Stancer::Exceptions::InvalidCardNumber::Test;
use Stancer::Exceptions::InvalidCardVerificationCode::Test;
use Stancer::Exceptions::InvalidCurrency::Test;
use Stancer::Exceptions::InvalidCustomerInstance::Test;
use Stancer::Exceptions::InvalidDescription::Test;
use Stancer::Exceptions::InvalidDeviceInstance::Test;
use Stancer::Exceptions::InvalidEmail::Test;
use Stancer::Exceptions::InvalidExpirationMonth::Test;
use Stancer::Exceptions::InvalidExpirationYear::Test;
use Stancer::Exceptions::InvalidExternalId::Test;
use Stancer::Exceptions::InvalidIban::Test;
use Stancer::Exceptions::InvalidIpAddress::Test;
use Stancer::Exceptions::InvalidMethod::Test;
use Stancer::Exceptions::InvalidMobile::Test;
use Stancer::Exceptions::InvalidName::Test;
use Stancer::Exceptions::InvalidOrderId::Test;
use Stancer::Exceptions::InvalidPaymentInstance::Test;
use Stancer::Exceptions::InvalidPort::Test;
use Stancer::Exceptions::InvalidRefundInstance::Test;
use Stancer::Exceptions::InvalidSepaInstance::Test;
use Stancer::Exceptions::InvalidSepaCheckInstance::Test;
use Stancer::Exceptions::InvalidUniqueId::Test;
use Stancer::Exceptions::InvalidUrl::Test;

# Search relative
use Stancer::Exceptions::InvalidSearchFilter::Test;
use Stancer::Exceptions::InvalidSearchCreation::Test;
use Stancer::Exceptions::InvalidSearchLimit::Test;
use Stancer::Exceptions::InvalidSearchOrderId::Test;
use Stancer::Exceptions::InvalidSearchStart::Test;
use Stancer::Exceptions::InvalidSearchUniqueId::Test;
use Stancer::Exceptions::InvalidSearchUntilCreation::Test;

# HTTP relative
use Stancer::Exceptions::Http::Test;
use Stancer::Exceptions::Http::ClientSide::Test;           # 4xx
use Stancer::Exceptions::Http::BadRequest::Test;           # 400
use Stancer::Exceptions::Http::Unauthorized::Test;         # 401
use Stancer::Exceptions::Http::NotFound::Test;             # 404
use Stancer::Exceptions::Http::Conflict::Test;             # 409
use Stancer::Exceptions::Http::ServerSide::Test;           # 5xx
use Stancer::Exceptions::Http::InternalServerError::Test;  # 500


Test::Class->runtests;
