#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Dmp;
use Data::Sah::Normalize qw(normalize_schema);
use Perinci::Sub::GetArgs::Argv;

subtest simple => sub {
    test_is_simple_or_aos_or_hos(
        name => "simple type",
        schema => "int",
        result => [1, 0, 0, "int", {}, undef],
    );
    test_is_simple_or_aos_or_hos(
        name => "based on simple type",
        test_needs => ["Sah::Schema::posint"],
        schema => "posint",
        result => [1, 0, 0, "int", {min=>1, summary=>"Positive integer (1, 2, ...)"}, undef],
    );
    test_is_simple_or_aos_or_hos(
        name => "non-simple type",
        schema => "obj",
        result => [0, 0, 0, "obj", {}, undef],
    );
    test_is_simple_or_aos_or_hos(
        name => "coercible from simple type",
        test_needs => ["Data::Sah::Coerce::perl::array::str_comma_sep"],
        schema => ["array", 'x.perl.coerce_rules' => ['str_comma_sep']],
        result => [1, 0, 0, "array", {'x.perl.coerce_rules'=>['str_comma_sep']}, undef],
    );
};

subtest "array of simple" => sub {
    test_is_simple_or_aos_or_hos(
        name => "array without element schema",
        schema => "array",
        result => [0, 0, 0, "array", {}, undef],
    );
    test_is_simple_or_aos_or_hos(
        name => "based on simple types",
        test_needs => ["Sah::Schema::aos"],
        schema => "aos",
        result => [0, 1, 0, "array", {of=>["str",{},{}], summary=>"Array of strings"}, "str"],
    );
    test_is_simple_or_aos_or_hos(
        name => "array of (simple types)",
        schema => ["array", of=>"date"],
        result => [0, 1, 0, "array", {of=>"date"}, "date"],
    );
    test_is_simple_or_aos_or_hos(
        name => "array of (based on simple types)",
        test_needs => ["Sah::Schema::posint"],
        schema => ["array", of=>"posint"],
        result => [0, 1, 0, "array", {of=>"posint"}, "int"],
    );
    test_is_simple_or_aos_or_hos(
        name => "array of (non-simple types)",
        schema => ["array", of=>"obj"],
        result => [0, 0, 0, "array", {of=>"obj"}, "obj"],
    );
    test_is_simple_or_aos_or_hos(
        name => "array of (coercible from simple type)",
        test_needs => ["Data::Sah::Coerce::perl::array::str_comma_sep"],
        schema => ["array", of=>["array", 'x.perl.coerce_rules' => ['str_comma_sep']]],
        result => [0, 1, 0, "array", {of=>["array", 'x.perl.coerce_rules'=>['str_comma_sep']]}, "array"],
    );
};

subtest "hash of simple" => sub {
    test_is_simple_or_aos_or_hos(
        name => "hash without element schema",
        schema => ["hash"],
        result => [0, 0, 0, "hash", {}, undef],
    );
    test_is_simple_or_aos_or_hos(
        name => "based on simple types",
        test_needs => ["Sah::Schema::hos"],
        schema => "hos",
        result => [0, 0, 1, "hash", {of=>["str",{},{}], summary=>"Hash of strings"}, "str"],
    );
    test_is_simple_or_aos_or_hos(
        name => "hash of (simple types)",
        schema => ["hash", of=>"duration"],
        result => [0, 0, 1, "hash", {of=>"duration"}, "duration"],
    );
    test_is_simple_or_aos_or_hos(
        name => "hash of (based on simple types)",
        test_needs => ["Sah::Schema::posint"],
        schema => ["hash", of=>"posint"],
        result => [0, 0, 1, "hash", {of=>"posint"}, "int"],
    );
    test_is_simple_or_aos_or_hos(
        name => "hash of (non-simple types)",
        schema => ["hash", of=>"obj"],
        result => [0, 0, 0, "hash", {of=>"obj"}, "obj"],
    );
    test_is_simple_or_aos_or_hos(
        name => "hash of (coercible from simple type)",
        test_needs => ["Data::Sah::Coerce::perl::array::str_comma_sep"],
        schema => ["hash", of=>["array", 'x.perl.coerce_rules' => ['str_comma_sep']]],
        result => [0, 0, 1, "hash", {of=>["array", 'x.perl.coerce_rules'=>['str_comma_sep']]}, "array"],
    );
};

DONE_TESTING:
done_testing;

sub test_is_simple_or_aos_or_hos {
    my %args = @_;

    subtest $args{name} // dmp($args{schema}) => sub {
        if ($args{test_needs}) {
            test_needs $_ for @{ $args{test_needs} };
        }
        my $nsch = normalize_schema($args{schema});
        my @res = Perinci::Sub::GetArgs::Argv::_is_simple_or_array_of_simple_or_hash_of_simple($nsch);

        # remove description first
        delete $res[4]{description};

        is_deeply(\@res, $args{result}, "result")
            or diag explain \@res;
    };
}
