use warnings;
use strict;

use File::Copy;
use FindBin qw($RealBin);

my $endpoints_file;
my $optcodes_file;

BEGIN {
    $endpoints_file = "$RealBin/test_data/endpoints_new.json";
    $optcodes_file = "$RealBin/test_data/optcodes_new.json";

    for ($endpoints_file, $optcodes_file) {
        open my $fh, '>', $_ or die $!;
        print $fh "{}";
    }

    $ENV{TESLA_API_ENDPOINTS_FILE} = $endpoints_file;
    $ENV{TESLA_API_OPTIONCODES_FILE} = $optcodes_file;
}

use lib 't/';

use Data::Dumper;
use JSON;
use Mock::Sub;
use Tesla::API;
use Test::More;
use TestSuite;

my $t = Tesla::API->new(unauthenticated => 1);
my $ts = TestSuite->new;
my $ms = Mock::Sub->new;

my $endpoints = $ts->file_data('t/test_data/endpoints.json');
my $optcodes = $ts->file_data('t/test_data/option_codes.json');

my $api_sub = $ms->mock('Tesla::API::_tesla_api_call');

for my $type ('endpoints', 'option_codes') {
    is keys %{ $t->$type }, 0, "$type has no entries ok";

    my $return = $type eq 'endpoints'
        ? encode_json($endpoints)
        : encode_json($optcodes);

    $api_sub->return_value(
        1,
        200,
        $return
    );

    $t->update_data_files($type);

    my $api_endpoints = $t->endpoints;
    my $api_options = $t->option_codes;


    if ($type eq 'endpoints') {
        is keys %{ $api_endpoints } > 0, 1, "Updated $type file has entries ok";

        is
            keys %$api_endpoints,
            keys %$endpoints,
            "endpoints() returns the proper number of endpoints ok";

        for my $endpoint (keys %$endpoints) {
            for (keys %{$endpoints->{$endpoint}}) {
                is
                    $api_endpoints->{$endpoint}{$_},
                    $endpoints->{$endpoint}{$_},
                    "Attribute $_ for endpoint $endpoint is $endpoints->{$endpoint}{$_} ok";
            }
        }
    }
    else {
        is keys %{ $api_options } > 0, 1, "Updated $type file has entries ok";

        is
            keys %$api_options,
            keys %$optcodes,
            "option_codes() returns the proper number of option codes ok";

        for my $option (keys %$optcodes) {
            is
                $api_options->{$option},
                $optcodes->{$option},
                "Value for option $option is correct";

            is
                $t->option_codes($option),
                $optcodes->{$option},
                "Value for option $option is correct via option_codes($option)";
        }
    }
}

# Files all updated
{
    for my $type ('endpoints', 'option_codes') {
        if ($type eq 'endpoints') {
            my $api_endpoints = $t->endpoints;

            my $return = encode_json($endpoints);

            $api_sub->return_value(
                1,
                200,
                $return
            );

            $t->update_data_files($type);

            $api_endpoints = $t->endpoints;
            is keys %{$endpoints}, keys %$api_endpoints, "$type has proper entries ok";
        }
        else {
            my $api_optcodes = $t->option_codes;

            my $return = encode_json($optcodes);

            $api_sub->return_value(
                1,
                200,
                $return
            );

            $t->update_data_files($type);

            $api_optcodes = $t->option_codes;
            is keys %{$optcodes}, keys %$api_optcodes, "$type has proper entries ok";
        }
    }
}

# Individual element changed (new)
{
    my $api_endpoints = $t->endpoints;

    delete $endpoints->{TRIGGER_HOMELINK};
    $endpoints->{TRIGGER_NONHOMELINK} = {};

    is exists $api_endpoints->{TRIGGER_HOMELINK}, 1, "existing elem exist in endpoints()";
    is exists $endpoints->{TRIGGER_HOMELINK}, '', "existing elem doesn't exist in new data";

    is exists $api_endpoints->{TRIGGER_NONHOMELINK}, '', "New elem doesn't exist in endpoints()";
    is exists $endpoints->{TRIGGER_NONHOMELINK}, 1, "New elem exists in new data";

    my $return = encode_json($endpoints);

    $api_sub->return_value(
        1,
        200,
        $return
    );

    $t->update_data_files('endpoints');

    $api_endpoints = $t->endpoints;
    is keys %{$endpoints}, keys %$api_endpoints, "new data has proper entries ok";

    for (keys %{ $api_endpoints }) {
        is exists $endpoints->{$_}, 1, "new data has $_ ok";
    }

    for (keys %{ $endpoints }) {
        is exists $api_endpoints->{$_}, 1, "endpoints() has $_ ok" ;
    }
}

my $endpoints_end = $ts->file_data($endpoints_file);
my $optcodes_end = $ts->file_data($optcodes_file);

is keys %{$endpoints_end} > 0, 1, "Updated endpoints file has entries ok";
is keys %{$optcodes_end} > 0, 1, "Updated optcodes file has entries ok";

unlink $endpoints_file or die $!;
unlink $optcodes_file or die $!;

my @files = glob 't/test_data/*.json.*';

is scalar @files > 1, 1, "Proper number of file backups ok";

my $delete_count = 0;

for (@files) {
    unlink $_ or die $!;
    $delete_count++;
}

is $delete_count, scalar @files, "Proper number of backup files deleted ok";

done_testing();