#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap_document_data.tap") or die "Cannot read t/some_tap_document_data.tap";
        $tap = <TAP>;
        close TAP;
}

my $dom1 = TAP::DOM->new( tap => $tap, lowercase_fieldnames  => 0, document_data_ignore =>   '' );
my $dom2 = TAP::DOM->new( tap => $tap, lowercase_fieldvalues => 0, document_data_ignore =>   'CPU[^ ]' );
my $dom3 = TAP::DOM->new( tap => $tap, lowercase_fieldnames  => 1, document_data_ignore =>   '' );
my $dom4 = TAP::DOM->new( tap => $tap, lowercase_fieldvalues => 1, document_data_ignore =>   'CPU[^ ]' );
my $dom5 = TAP::DOM->new( tap => $tap, lowercase_fieldvalues => 1, document_data_ignore => qr/CPU[^ ]/i );

# ==================== Key/Values ====================

# 1
is  ($dom1->{document_data}{'CPUINFO/processor'}, 3,                                          "no lowercase - no ignore - 1");
is  ($dom1->{document_data}{'CPU family'},        6,                                          "no lowercase - no ignore - 2");
is  ($dom1->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "no lowercase - no ignore - 3");
is  ($dom1->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "no lowercase - no ignore - 4");

# 2
isnt($dom2->{document_data}{'CPUINFO/processor'}, 3,                                          "no lowercase - ignore - 1");
is  ($dom2->{document_data}{'CPU family'},        6,                                          "no lowercase - ignore - 2");
isnt($dom2->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "no lowercase - ignore - 3");
is  ($dom2->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "no lowercase - ignore - 4");

# 3
isnt($dom3->{document_data}{'CPUINFO/processor'}, 3,                                          "lowercase - no ignore - 1");
isnt($dom3->{document_data}{'CPU family'},        6,                                          "lowercase - no ignore - 2");
isnt($dom3->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "lowercase - no ignore - 3");
is  ($dom3->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "lowercase - no ignore - 4");

# 4
isnt($dom4->{document_data}{'CPUINFO/processor'}, 3,                                          "lowercase - ignore - 1");
is  ($dom4->{document_data}{'CPU family'},        6,                                          "lowercase - ignore - 2");
isnt($dom4->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "lowercase - ignore - 3");
is  ($dom4->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "lowercase - ignore - 4");

# 5
isnt($dom5->{document_data}{'CPUINFO/processor'}, 3,                                          "lowercase - ignore case-insensitive - 1");
is  ($dom5->{document_data}{'CPU family'},        6,                                          "lowercase - ignore case-insensitive - 2");
isnt($dom5->{document_data}{'CPU-model'},         'Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz', "lowercase - ignore case-insensitive - 3");
isnt($dom5->{document_data}{'cpuinfo'},           'flags.fpu: 1',                             "lowercase - ignore case-insensitive - 4");

done_testing();
