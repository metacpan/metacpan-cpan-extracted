use Test::More;
use strict;
use warnings;

use Parser::FIT;

my $parser = Parser::FIT->new();

subtest "handling semicircles", sub {
    subtest "positive semicircles", sub {
        my $expectedValue = 48.217529;

        my $rawValue = 575257540;
        my $fieldDescriptor = {
            type => "sint32",
            offset => undef,
            scale => undef,
            unit => "semicircles"
        };

        my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

        # truncate computed value to 6 decimals places without rounding
        $result = int($result * 10**6)/10**6;

        is($result, $expectedValue, "conversion is ok");
    };

    subtest "negative semicricles", sub {
        my $expectedValue = -74.016499;

        my $rawValue = -883051241;
        my $fieldDescriptor = {
            type => "sint32",
            offset => undef,
            scale => undef,
            unit => "semicircles"
        };

        my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

        # truncate computed value to 6 decimals places without rounding
        $result = int($result * 10**6)/10**6;

        is($result, $expectedValue, "conversion is ok");
    };
};

subtest "handle date_time", sub {
    my $fieldDescriptor = {
        type => "date_time",
        offset => undef,
        scale => undef,
        unit => "s"
    };

    my $rawValue = 0;
    my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

    is($result, 631065600, "correct fit epoche offset");
};

subtest "offset gets subtracted", sub {
    my $fieldDescriptor = {
        type => "uint32",
        offset => 100,
        scale => undef,
        unit => "m"
    };

    my $rawValue = 200;
    my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

    is($result, 100, "offest gets subtracted");
};

subtest "divided by scale", sub {
    my $fieldDescriptor = {
        type => "uint32",
        offset => undef,
        scale => 10,
        unit => "m"
    };

    my $rawValue = 200;
    my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

    is($result, 20, "divided by scale");
};

subtest "first scale than offset is applied", sub {
    my $fieldDescriptor = {
        type => "uint32",
        offset => 10,
        scale => 10,
        unit => "m"
    };

    my $rawValue = 200;
    my $result = $parser->postProcessRawValue($rawValue, $fieldDescriptor);

    is($result, 10, "first scale than offset is applied");
};

done_testing;