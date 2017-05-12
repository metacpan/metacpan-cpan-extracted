use Test::More;
use Test::Moose;
use RDF::Trine;
use Data::Dumper;
use MooseX::Semantic::Test::Person;
use MooseX::Semantic::Test qw(ser ser_dump diff_models);


sub import_from_ttl {
    my $base_uri = 'http://tobyinkster.co.uk/#i';
    my $test_model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser::Turtle->parse_file_into_model(
        $base_uri,
        't/data/toby_inkster.ttl',
        $test_model,
    );
    my $person = MooseX::Semantic::Test::Person->new_from_model( $test_model, $base_uri );
    ok (! $person->is_blank, "Toby isn't a blank node");
    # warn Dumper $person;
    ok(! ref $person->name, 'Single Value -> Str');
    ok($person->name eq 'Toby Inkster', 'name attribute is set ');

    is(ref $person->topic_interest, 'ARRAY', 'Multiple Values -> ArrayRef');
    is(scalar(@{$person->topic_interest}), 2, 'All values are imported');

    ok(! ref $person->country, 'Multiple values -> Str');
    is($person->country, 'USA', 'country set to last value in Turtle syntax (weakly defined behaviour here)');

    ok( ref $person->subjects eq 'ARRAY', 'Single Value -> ArrayRef');
    is( $person->subjects->[0], 'homepage', 'subjects imported');

    is( ref $person->friends,  'ARRAY', 'Single URI -> ArrayRef' );
    is( $person->get_friend(0)->rdf_about->value, 'http://kasei.us/about/foaf.xrdf#greg', 'friends correctly detected');
    ok( $person->get_friend(0)->is_resource, "Greg isn't a blank node");

    isa_ok( ref $person->generic_one_to_one_relation,  'MooseX::Semantic::Test::Person', 'Single URI -> Resource Object' );
    is( $person->generic_one_to_one_relation->rdf_about->uri, 'http://kasei.us/about/foaf.xrdf#greg', 'Object created');
    ok( !  $person->generic_one_to_one_relation->is_blank,, "Greg isn't a blank node");

    ok(my $got_model = $person->export_to_model);

    my $test_model_str = ser_dump($test_model);
    # my $got_model_str = ser->serialize_model_to_string($got_model);
    # warn Dumper [$test_model_str, $got_model_str];
    # diff_models($test_model, $got_model);
    my $old_size = $test_model->size;
    my $new_size = $got_model;
    TODO: {
        cmp_ok($new_size, '>=', $old_size, 'Same number of statements after round-trip (sans information lost on multiple values)');
    }
}

sub import_from_web {
    my $base_uri = 'http://kasei.us/about/foaf.xrdf#greg';
    my $model = MooseX::Semantic::Test::Person->new_from_web( $base_uri );
}

sub symmetrical_property {
    my $base_uri = 'http://example.org/';
    my $test_model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser::Turtle->parse_file_into_model(
        $base_uri,
        't/data/symmetrical_property.ttl',
        $test_model,
    );
    ok( my $alice = MooseX::Semantic::Test::Person->new_from_model( $test_model, $base_uri . 'F' )
        , 'Alice can be loaded from RDF');
    ok( my $alice_model_str = $alice->export_to_string(format=>'ntriples') );
    # warn Dumper $alice_model_str;
}

sub import_instance_hash {
    my $base_uri = 'http://tobyinkster.co.uk/#i';
    my $test_model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser::Turtle->parse_file_into_model(
        $base_uri,
        't/data/toby_inkster.ttl',
        $test_model,
    );
    my $hash = MooseX::Semantic::Test::Person->get_instance_hash( $test_model, $base_uri );
    is(keys %{$hash}, 7, 'correct number of keys');
    # warn Dumper $hash;
}

&import_from_ttl;
&symmetrical_property;
&import_instance_hash;
# &import_from_web;
done_testing;
