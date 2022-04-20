use warnings;
use strict;

use JSON;
use Tesla::API;
use Test::More;

my $tesla = Tesla::API->new(unauthenticated => 1);

my $known_options;
{
    local $/;
    open my $fh, '<', 't/test_data/option_codes.json' or die $!;
    my $json = <$fh>;
    $known_options = decode_json($json);
}

my $api_options = $tesla->option_codes;

is
    keys %$api_options,
    keys %$known_options,
    "option_codes() returns the proper number of option codes ok";

for my $option (keys %$known_options) {
    is
        $api_options->{$option},
        $known_options->{$option},
        "Value for option $option is correct";

    is
        $tesla->option_codes($option),
        $known_options->{$option},
        "Value for option $option is correct via option_codes($option)";
}

my $missing_opt_code_succeeded = eval {
    $tesla->option_codes('NON_EXIST');
    1;
};

is
    $missing_opt_code_succeeded,
    undef,
    "If an option code doesn't exist, we croak ok";

like $@, qr/does not exist/, "...and error message is sane";


done_testing();