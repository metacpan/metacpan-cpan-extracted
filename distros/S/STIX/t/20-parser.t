#!perl

use strict;
use warnings;
use v5.10;

use Cpanel::JSON::XS qw(decode_json encode_json);
use File::Spec;
use STIX::Parser;
use STIX::Util qw(file_read);
use Test::More;

my $test_file = File::Spec->catfile('t', 'examples-bundle.json');

BAIL_OUT('file not found') if (!-e $test_file);

my $json = decode_json(file_read($test_file));

foreach my $object (@{$json}) {

    my $content = encode_json($object);
    my $p       = STIX::Parser->new(content => $content);
    my $stix    = $p->parse;

    isnt "$stix", '';

    if ($stix->can('type')) {

        my @errors = $stix->validate;
        diag $content, "$stix", "@errors" if @errors;

        is @errors, 0;

    }

}

done_testing();
