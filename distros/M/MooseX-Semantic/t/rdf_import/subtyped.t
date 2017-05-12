use Test::More tests => 13;
use Test::Moose;
use RDF::Trine;
use Data::Dumper;
use MooseX::Semantic::Test::Person;

{ 
    package PersonWithSubtypes;
    use Moose;
    use Moose::Util::TypeConstraints;
    with ( 'MooseX::Semantic::Role::RdfImport', 'MooseX::Semantic::Util::TypeConstraintWalker',) ;
    subtype 'LevelOne', as 'MooseX::Semantic::Test::Person';
    subtype 'LevelTwo', as 'LevelOne';
    subtype 'LevelThree', as 'LevelTwo';
    subtype 'LevelFour', as 'LevelThree';
    subtype 'ArrayOfLevelFour', as 'ArrayRef[LevelFour]';
    subtype 'ArrayTooDeep', as 'ArrayRef[ArrayOfLevelFour]';
    # subtype '
    has semantic => (
        is => 'rw',
        isa => 'ArrayOfLevelFour'
    );
    has not_semantic => (
        is => 'rw',
        isa => 'ArrayTooDeep',
    );
    has also_semantic => (
        is => 'rw',
        isa => 'ArrayTooDeep',
    );
    1;
}
my $pkg = 'MooseX::Semantic::Test::Person';
my $dontcare = $pkg->new;
my $p = PersonWithSubtypes->new(
    semantic=> [$dontcare],
    not_semantic => [[$dontcare]],
);
ok( !$p->_find_parent_type( 'semantic', $pkg ),
    'fail: without look_vertically' );
ok( $p->_find_parent_type( 'semantic', $pkg,
        look_vertically => 1 
    ), 'win:  look_vertically => 1' 
);
ok( ! $p->_find_parent_type( 'semantic', $pkg,
        look_vertically => 0,
        max_depth => 5 
    ), "fail: max_depth = 5, look_vertically = 0"
);
ok( $p->_find_parent_type( 'semantic', $pkg,
        look_vertically => 1,
        max_depth => 6 
    ), "win: max depth = 6"
);
ok( ! $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 0,
    ), "fail: look_vertically = 0"
);
ok( ! $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 0,
    ), "fail: look_vertically = 1"
);
ok( $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 1,
        max_depth => 8 
    ), "win: max_depth = 2, look_vertically = 1"
);
ok( $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 1,
    ), "win: look_vertically = 1"
);
ok( ! $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 1,
        max_width => 1,
    ), "fail: look_vertically = 1"
);
ok( $p->_find_parent_type( 'not_semantic', $pkg,
        look_vertically => 1,
        max_width => 2,
    ), "win: look_vertically = 2"
);
ok( $p->_find_parent_type( 'semantic', [qw(LevelTwo LevelThree)],
        look_vertically => 1,
        match_all => 1
    ), "win: array matched all"
);
ok( ! $p->_find_parent_type( 'semantic', [qw(LevelTwo LevelThree NOFOUND)],
        look_vertically => 1,
        # max_width => 2,
        match_any => 0,
    ), "win array matched"
);
ok( $p->_find_parent_type( 'semantic', [qw(LevelTwo LevelThree NOFOUND)],
        look_vertically => 1,
        match_any => 1,
    ), "win: array not all matched, but match_any = 1"
);
