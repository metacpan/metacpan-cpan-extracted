use Test::More tests=>10;
use Test::Moose;
use Carp::Always;
use RDF::Trine qw(blank literal iri statement);
use Data::Dumper;
use MooseX::Semantic::Test::Person;
use File::Temp qw( tempfile );

sub basic_export {
    my $toby = MooseX::Semantic::Test::Person->new(
        rdf_about => 'http://tobyinkster.co.uk/#i',
        name => 'Toby Inkster',
        country => 'UK',
        subjects => ['perl'],
    );
    my $greg = MooseX::Semantic::Test::Person->new(
        rdf_about => 'http://kasei.us/about/foaf.xrdf#greg',
        name => 'Gregory Williams',
        country => 'USA',
        favorite_numer => 3,
        friends => [ $toby ],
    );
    my $model = $greg->export_to_model;
    isa_ok($model, 'RDF::Trine::Model');
    is($model->size, 11, 'generated 9 statments');
    # warn Dumper $greg->export_to_string;
    # warn Dumper $model->size;
    # warn Dumper $model;
    ok(my $model_as_string = $greg->export_to_string(format=>'ntriples'), 'export_to_string works');
    # warn Dumper $model_as_string;

    my ( $fh, $fname ) = tempfile;
    ok( $greg->export_to_file( $fh, format=>'ntriples' ), 'export_to_file works');
    close $fh;
    # open $fh, "<", $fname;
    my $fh_contents = do { local $/; open $fh, "<$fname"; <$fh> };
    # close $fh;
    is( $fh_contents, $model_as_string, 'File export and String export match');
}

sub basic_blank_node {
    my $bob = MooseX::Semantic::Test::Person->new(
        rdf_about => blank,
        name => 'Bob',
    );
    my $alice = MooseX::Semantic::Test::Person->new(
        rdf_about => blank,
        name => 'Alice',
    );
    $bob->add_friend( $alice );
    ok($bob->rdf_about->is_blank, 'Bob is blank');
    ok($alice->rdf_about->is_blank, 'Alice is blank');
    is($bob->get_friend(0), $alice, "Alice is Bob's friend");
    ok(my $model = $bob->export_to_model, 'Can export Bob to model');
    is($model->size, 5, 'Correct number of statements exported');
}

sub basic_to_turtle {
    {
        package My::Model::Person;
        use Moose;
        with qw(MooseX::Semantic::Role::RdfExport);
        has name => (
            traits => ['Semantic'],
            is => 'rw',
            isa => 'Str',
            uri => 'http://xmlns.com/foaf/0.1/name',
            uri_writer => ['http://myont.org/onto#name'],
        );
    }
    my $p = My::Model::Person->new(
        rdf_about => 'http://myont.org/data/John',
        name      => 'John'
    );
    print $p->export_to_string(format=>'turtle');
}

sub model_export {
    {
        package My::Model::Person;
        use Moose;
        with qw(MooseX::Semantic::Role::RdfExport);
        has bucket => (
            traits => ['Semantic'],
            is => 'rw',
            isa => 'RDF::Trine::Model',
            uri => 'http://xmlns.com/foaf/0.1/dataBucket',
            uri_writer => ['http://myont.org/onto#name'],
        );
    }
    my $dummy_model = RDF::Trine::Model->temporary_model;
    $dummy_model->add_statement(statement(
        iri('Someone'),
        iri('is'),
        literal('bored'),
    ));
    my $p = My::Model::Person->new(
        rdf_about => 'http://myont.org/data/John',
        bucket      => $dummy_model
    );
    print $p->export_to_string(format=>'turtle');
}

&basic_export;
&basic_blank_node;
&basic_to_turtle;
&model_export;
# done_testing;
