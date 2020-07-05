#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap_with_key_values_insensitive.tap") or die "Cannot read t/some_tap_with_key_values_insensitive.tap";
        $tap = <TAP>;
        close TAP;
}

my $dom  = TAP::DOM->new( tap => $tap, lowercase_fieldnames  => 1 );
my $dom2 = TAP::DOM->new( tap => $tap, lowercase_fieldnames  => 1, lowercase_fieldvalues => 1 );
my $dom3 = TAP::DOM->new( tap => $tap, lowercase_fieldvalues => 1 );

# ==================== Basic TAP data ====================
is($dom->{tests_run},         2, "case-insensitive - tests_run");
is($dom->{tests_planned},     2, "case-insensitive - tests_planned");
is($dom->{version},          13, "case-insensitive - version");
is($dom->{plan},         "1..2", "case-insensitive - plan");

# ==================== Key/Values ====================

# no original uppercases
isnt($dom->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "no uppercase - hash - key contains dashes");
isnt($dom->{document_data}{'flags.FPU'},         1,                                          "no uppercase - hash - key contains dots");
isnt($dom->{document_data}{'Elapsed-Time[ms]'},  13,                                         "no uppercase - hash - key contains brackets");
isnt($dom->{document_data}{'CPUINFO/processor'}, 3,                                          "no uppercase - hash - key contains slashes");
isnt($dom->{document_data}{'CPU family'},        6,                                          "no uppercase - hash - key contains whitespace (inner whitespace only)");

is($dom->{document_data}{'cpu-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "case-insensitive - hash - key contains dashes");
is($dom->{document_data}{'flags.fpu'},         1,                                          "case-insensitive - hash - key contains dots");
is($dom->{document_data}{'elapsed-time[ms]'},  13,                                         "case-insensitive - hash - key contains brackets");
is($dom->{document_data}{'cpuinfo/processor'}, 3,                                          "case-insensitive - hash - key contains slashes");
is($dom->{document_data}{'cpu family'},        6,                                          "case-insensitive - hash - key contains whitespace (inner whitespace only)");
is($dom->{document_data}{'vendor_id'},         'GenuineIntel',                             "case-insensitive - hash - key contains underscore");
is($dom->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "case-insensitive - hash - key can not contain colons");

# lowercase field values
is($dom2->{document_data}{'cpu-model'},         'intel(r) core(tm) i7-3667u cpu @ 2.00ghz', "lowercase - hash - key contains dashes");
is($dom2->{document_data}{'vendor_id'},         'genuineintel',                             "lowercase - hash - key contains underscore");
is($dom2->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "lowercase - hash - key can not contain colons");

# ==================== Accessor functions ====================

# getters
is($dom->{document_data}->get('cpu-model'),         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "case-insensitive - accessor - key contains dashes");
is($dom->{document_data}->get('flags.fpu'),         1,                                          "case-insensitive - accessor - key contains dots");
is($dom->{document_data}->get('cpuinfo/processor'), 3,                                          "case-insensitive - accessor - key contains slashes");
is($dom->{document_data}->get('cpu family'),        6,                                          "case-insensitive - accessor - key contains whitespace (inner whitespace only)");
is($dom->{document_data}->get('vendor_id'),         'GenuineIntel',                             "case-insensitive - accessor - key contains underscore");
is($dom->{document_data}->get('cpuinfo'),           'flags.fpu: 1',                             "case-insensitive - accessor - key can not contain colons");

# lowercase
is($dom2->{document_data}->get('cpu-model'),         'intel(r) core(tm) i7-3667u cpu @ 2.00ghz', "lowercase - accessor - key contains dashes");
is($dom2->{document_data}->get('vendor_id'),         'genuineintel',                             "lowercase - accessor - key contains underscore");
is($dom2->{document_data}->get('cpuinfo'),           'flags.fpu: 1',                             "lowercase - accessor - key can not contain colons");

# original key names, lowercase values only
is($dom3->{document_data}{'CPU-model'},         'intel(r) core(tm) i7-3667u cpu @ 2.00ghz',      "uppercase key, lowercase value - hash - key contains dashes");

done_testing();
