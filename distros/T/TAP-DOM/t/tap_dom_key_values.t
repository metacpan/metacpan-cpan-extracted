#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap_with_key_values.tap") or die "Cannot read t/some_tap_with_key_values.tap";
        $tap = <TAP>;
        close TAP;
}

my $dom = TAP::DOM->new( tap => $tap);

# ==================== Basic TAP data ====================
is($dom->{tests_run},     2,     "tests_run");
is($dom->{tests_planned},  2,     "tests_planned");
is($dom->{version},       13,     "version");
is($dom->{plan},          "1..2", "plan");
is($dom->{summary}{passed},       2,      "summary passed");
is($dom->{summary}{failed},       0,      "summary failed");
is($dom->{summary}{exit},         0,      "summary exit");
is($dom->{summary}{wait},         0,      "summary wait");
is($dom->{summary}{status},       "PASS", "summary status");
is($dom->{summary}{all_passed},   1,      "summary all_passed");
is($dom->{summary}{has_problems}, 0,      "summary has_problems");

# ==================== Key/Values ====================

is($dom->{document_data}{'cpu-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "hash - key contains dashes");
is($dom->{document_data}{'flags.fpu'},         1,                                          "hash - key contains dots");
is($dom->{document_data}{'elapsed-time[ms]'},  13,                                         "hash - key contains brackets");
is($dom->{document_data}{'cpuinfo/processor'}, 3,                                          "hash - key contains slashes");
is($dom->{document_data}{'cpu family'},        6,                                          "hash - key contains whitespace (inner whitespace only)");
is($dom->{document_data}{'vendor_id'},         'GenuineIntel',                             "hash - key contains underscore");
is($dom->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "hash - key can not contain colons");

# ==================== Accessor functions ====================

# getters
is($dom->{document_data}->get('cpu-model'),         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "accessor - key contains dashes");
is($dom->{document_data}->get('flags.fpu'),         1,                                          "accessor - key contains dots");
is($dom->{document_data}->get('cpuinfo/processor'), 3,                                          "accessor - key contains slashes");
is($dom->{document_data}->get('cpu family'),        6,                                          "accessor - key contains whitespace (inner whitespace only)");
is($dom->{document_data}->get('vendor_id'),         'GenuineIntel',                             "accessor - key contains underscore");
is($dom->{document_data}->get('cpuinfo'),           'flags.fpu: 1',                             "accessor - key can not contain colons");

# hash.set/get
$dom->{document_data}->set('cpuinfo', 'zomtec');
is($dom->{document_data}->get('cpuinfo'), 'zomtec', "hash.setter/getter - change value");

# get.set/get
$dom->document_data->set('cpuinfo', 'affe tiger birne');
is($dom->document_data->get('cpuinfo'), 'affe tiger birne', "getter.setter/getter - change value");

done_testing();
