use Test::Spec;

use ObjectDB::Util qw/merge/;

describe 'merge' => sub {

    it 'merges hashes' => sub {
        is_deeply({with => ['table']}, merge {with => 'table'}, {with => []});
    };

};

runtests unless caller;
