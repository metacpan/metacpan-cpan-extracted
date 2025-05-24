#!/usr/bin/env perl -T
use Carp::Always;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Test::More;
use URI;
use strict;

require_ok 'Net::RDAP';

my $result = Net::RDAP->new->fetch(URI->new('file://'.File::Spec->catfile(abs_path(dirname(__FILE__)), q{redacted.json})));

isa_ok($result, q{Net::RDAP::Object});

isnt(ref($result), q{Net::RDAP::Error}, 'result is not an error');

my @fields = $result->redactions;

cmp_ok(scalar(@fields), '>', 0, 'result contains redactions');

is(scalar(grep {'Net::RDAP::Redaction' eq ref($_) } @fields), scalar(@fields), 'all array members are Net::RDAP::Redaction objects');

foreach my $field (@fields) {
    isnt($field->name, undef, 'name is defined');
    isnt($field->method, undef, 'method is defined');
    isnt($field->pathLang, undef, 'pathLang is defined');
    isnt($field->reasonLang, undef, 'reasonLang is defined');
}

done_testing;
