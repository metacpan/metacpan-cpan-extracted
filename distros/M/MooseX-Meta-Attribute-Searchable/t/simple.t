use Test::More;

use lib qw(t/lib);

use MyObject;

my $obj = MyObject->new(name => 'user', fieldless_name => 'user2' );
ok(defined($obj), 'got an object');

my $href = $obj->get_searchable_hashref;

is_deeply($href, {
    name => 'user',
    name_ngram => 'user',
    fieldless_name => 'user2'
}, 'got hashref');

done_testing;