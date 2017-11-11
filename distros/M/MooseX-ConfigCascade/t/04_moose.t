use strict;
use warnings;
use lib 't/lib';
use File::Spec;
use Cwd 'abs_path';
use Test::More;
use ConfigCascade::Test::HasBUILD;
use ConfigCascade::Test::Novel;
use ConfigCascade::Test::HasRole;


BEGIN { use_ok('MooseX::ConfigCascade::Util') };

MooseX::ConfigCascade::Util->conf({
    'ConfigCascade::Test::HasBUILD' => {
        string_att => 'string_att from conf',
        hash_att => {
            'hash_att key from conf' => 'hash_att value from conf'
        },
        array_att => [ 'array_att value from conf' ],
        num_att => 35.7
    }
});

my $has_build = ConfigCascade::Test::HasBUILD->new;

is_deeply( $has_build->array_att, [ 'array_att value from conf' ], 'HasBUILD test: attribute "array_att" correctly gets value from conf' );
is( $has_build->string_att, 'string_att from conf', 'HasBUILD test: attribute "string_att" correctly gets value from conf' );
is_deeply( $has_build->hash_att, { 'hash_att key from conf' => 'hash_att value from conf' }, 'HasBUILD test: attribute "hash_att" correctly gets value from conf' );
is( $has_build->num_att, 74.9, 'HasBUILD test: attribute "num_att" correctly gets value from "after BUILD"');


MooseX::ConfigCascade::Util->conf({
    'ConfigCascade::Test::Novel' => {
        pages => [ 'page from conf' ],
        author => 'author from conf'
    }
});

my $novel = ConfigCascade::Test::Novel->new;


is( $novel->author, 'author from conf', 'Inheritance test: attribute from child class "author" set correctly');
is_deeply( $novel->pages, [ 'page from conf' ], 'Inheritance test: attribute from parent class set correctly');


$novel = ConfigCascade::Test::Novel->new( 
    author => 'author from constructor',
);
is( $novel->author, 'author from constructor', 'Constructor args test 1: attribute "author" correctly takes value from constructor args');
is_deeply( $novel->pages, [ 'page from conf' ], 'Constructor args test 1: attribute "pages" correctly takes value from conf');


$novel = ConfigCascade::Test::Novel->new( 
    pages => [ 'page from constructor' ]
);
is( $novel->author, 'author from conf', 'Constructor args test 2: attribute "author" correctly takes value from conf');
is_deeply( $novel->pages, [ 'page from constructor' ], 'Constructor args test 2: attribute "pages" correctly takes value from constructor args');


$novel = ConfigCascade::Test::Novel->new( 
    author => 'author from constructor',
    pages => [ 'page from constructor' ]
);
is ( $novel->author, 'author from constructor', 'Constructor args test 3: attribute "author" correctly takes value from constructor args');
is_deeply( $novel->pages, [ 'page from constructor' ], 'Constructor args test 3: attribute "pages" correctly takes value from constructor args');

MooseX::ConfigCascade::Util->conf({
    'ConfigCascade::Test::HasRole' => {
        non_role_att => { 'non_role_att from conf key' => 'non_role_att from conf value' },
        role_att => 'role_att from conf'
    }
});

my $has_role = ConfigCascade::Test::HasRole->new;
is( $has_role->role_att, 'role_att from conf', 'Role test: attribute "role_att" correctly takes value from conf');
is_deeply( $has_role->non_role_att, { 'non_role_att from conf key' => 'non_role_att from conf value' }, 'Role test: attribute "non_role_att correctly takes value from conf' );


done_testing();
