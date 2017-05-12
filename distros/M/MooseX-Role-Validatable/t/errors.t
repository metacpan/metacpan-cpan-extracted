#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use MooseX::Role::Validatable::Error;

my $error = MooseX::Role::Validatable::Error->new({
    message           => 'Internal debug message.',    # Required
    message_to_client => 'Client-facing message',      # Required
    set_by            => 'Source of the error',        # Required; MAY default to caller(1)
    severity          => 5,                            # For ordering, bigger is worse. Defaults to 1.
    transient         => 1,                            # Boolean, defaults to false
    alert             => 1,                            # Boolean, defaults to false
    info_link         => 'https://example.com/',       # Client-facing URI for additional info on this error.
});

is($error->message,           'Internal debug message.');
is($error->message_to_client, 'Client-facing message');
ok($error->as_html =~ /Client-facing message/);
ok($error->as_html =~ /example.com/);

done_testing();

1;
