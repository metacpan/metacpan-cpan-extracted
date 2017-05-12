#!/usr/bin/perl -w
use strict;

use Test::More  tests => 116;
use Test::CPAN::Meta::JSON::Version;
use IO::File;
use JSON;

# Version 1.3 Tests

my $vers = '1.3';
my @tests = (
    { file => 't/samples/00-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/01-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/02-META.json', fail => 1, errors => 2, bad => 1, faults => 10 },
    { file => 't/samples/03-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/04-META.json', fail => 1, errors => 1, bad => 1, faults => 1 },
    { file => 't/samples/05-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/06-META.json', fail => 1, errors => 3, bad => 1, faults => 3 },
    { file => 't/samples/07-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/08-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/09-META.json', fail => 1, errors => 1, bad => 1, faults => 1 },
    { file => 't/samples/10-META.json', fail => 1, errors => 1, bad => 1, faults => 1 },
    { file => 't/samples/11-META.json', fail => 1, errors => 2, bad => 1, faults => 1 },
    { file => 't/samples/12-META.json', fail => 1, errors => 1, bad => 1, faults => 9 },
    { file => 't/samples/13-META.json', fail => 1, errors => 1, bad => 0, faults => 0 },
    { file => 't/samples/14-META.json', fail => 1, errors => 1, bad => 0, faults => 0 },
    { file => 't/samples/15-META.json', fail => 1, errors => 1, bad => 0, faults => 0 },
    { file => 't/samples/16-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/multibyte.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/Template-Provider-Unicode-Japanese.json', fail => 0, errors => 0, bad => 0, faults => 0 },
);

runtests($vers,\@tests);

# Version 2 tests

$vers = '2';
@tests = (
    { file => 't/samples/20-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
    { file => 't/samples/21-META.json', fail => 1, errors => 2, bad => 1, faults => 2 },
    { file => 't/samples/22-META.json', fail => 1, errors => 1, bad => 1, faults => 1 },
    { file => 't/samples/23-META.json', fail => 1, errors => 1, bad => 1, faults => 1 },
    { file => 't/samples/24-META.json', fail => 0, errors => 0, bad => 0, faults => 0 },
);

runtests($vers,\@tests);

# Version 2.0 tests

$vers = '2.0';
runtests($vers,\@tests);

sub runtests {
    my ($vers,$tests) = @_;
    my @tests = @$tests;

    for my $test (@tests) {
        my $meta = _readdata($test->{file});

        unless($meta) {
            ok(0,"Cannot load file - $test->{file}");
            ok(0,"Cannot load file - $test->{file}");
            next;
        }

        my $spec = Test::CPAN::Meta::JSON::Version->new(spec => $vers, data => $meta);

        my $result = $spec->parse();
        my @errors = $spec->errors();

        is($result,         $test->{fail},   "'fail' check for $test->{file}");
        is(scalar(@errors), $test->{errors}, "'errors' check for $test->{file}");

        if(scalar(@errors) != $test->{errors}) {
            diag("failed: $test->{file}");
            diag("errors: " . join("\n",@errors));
        }
    }

    for my $test (@tests) {
        my $meta = _readdata($test->{file});
        unless($meta) {
            ok(0,"Cannot load file - $test->{file}");
            ok(0,"Cannot load file - $test->{file}");
            next;
        }

        my $spec = Test::CPAN::Meta::JSON::Version->new(data => $meta);

        my $result = $spec->parse();
        my @errors = $spec->errors();

        is($result,         $test->{bad},    "'bad' check for $test->{file}");
        is(scalar(@errors), $test->{faults}, "'faults' check for $test->{file}");

        if(scalar(@errors) != $test->{faults}) {
            diag("failed: $test->{file}");
            diag("errors: " . join("\n",@errors));
        }
    }
}

sub _readdata {
    my $file = shift;
    my $data;
    my $fh = IO::File->new($file,'r') or die "Cannot open file [$file]: $!";
    while(<$fh>) { $data .= $_ }
    $fh->close;
    return decode_json($data);
}
