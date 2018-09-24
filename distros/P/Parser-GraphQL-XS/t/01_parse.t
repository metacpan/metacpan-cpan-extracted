use strict;
use warnings;

use Data::Dumper;
use JSON::XS;
use Path::Tiny;
use Test::More;

my $CLASS = 'Parser::GraphQL::XS';

sub save_tmp_file {
    my ($contents) = @_;

    my $path = Path::Tiny->tempfile();
    $path->spew_utf8($contents);
    return $path;
}

sub check_parse {
    my ($json, $name) = @_;

    ok($json, sprintf("parsed GraphQL %s", defined $name ? "file '$name'" : "string"));

    my $data = JSON::XS::decode_json($json);
    ok($data, "converted from JSON");

    my $expected = [ sort qw/ kind definitions loc /];
    my $got = [ sort keys %$data ];
    is_deeply($got, $expected, "got all expected keys from parsed GraphQL");
}

sub test_parse {
    my $source = << "EOS";
    type Query {
        findPerson(name: String) : [Person]
    }

    type BirthEvent {
        year  : Int
        place : String
    }

    type DeathEvent {
        year  : Int
        place : String
    }

    type Person {
        name        : String
        nationality : String
        gender      : String
        birth       : BirthEvent
        death       : DeathEvent
    }
EOS
    my $gql = $CLASS->new;

    check_parse($gql->parse_string($source));

    my $tmp = save_tmp_file($source);
    my $name = $tmp->stringify();
    check_parse($gql->parse_file($name), $name);
}

sub main {
    use_ok($CLASS);
    test_parse();

    done_testing;
    return 0;
}

exit main();
