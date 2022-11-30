package t::lib::Test;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;
use Test::Differences;

use OpenTelemetry::TraceContext::W3C ':all';

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::Differences::EXPORT,
    @OpenTelemetry::TraceContext::W3C::EXPORT_OK,
);

sub import {
    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

1;
