use Test::More qw/no_plan/;
use Test::Chado;

use_ok 'Test::Chado::FixtureManager::Flatfile';
subtest 'default path for default fixtures' => sub {
    my $manager = new_ok 'Test::Chado::FixtureManager::Flatfile';
    is( $manager->default_fixture_path, $manager->fixture_path,
        'should have default fixture
	 		path'
    );
    like( $manager->organism_fixture, qr/organism/,
        'should have default organism fixture' );
    like(
        $manager->rel_fixture, qr/relationship/,
        'should have default relationship
	 		ontology fixture'
    );
    like( $manager->so_fixture, qr/sofa/,
        'should have default sequence ontology fixture' );

};
