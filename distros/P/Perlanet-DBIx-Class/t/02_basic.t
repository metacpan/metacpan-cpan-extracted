use strict;
use warnings;
use Test::More;
use FindBin '$Bin';

use Perlanet::DBIx::Class;

{
    package Test::Schema::PostResultSet;
    use Moose;
    extends qw( DBIx::Class::ResultSet Moose::Object );
    with 'Perlanet::DBIx::Class::Role::PostResultSet';
}

{
    package Test::Schema::Post;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('post');
    __PACKAGE__->add_columns(qw(
        feed_id author url title posted_on summary body
    ));
    __PACKAGE__->resultset_class('Test::Schema::PostResultSet');
}

{
    package Test::Schema::FeedResultSet;
    use Moose;
    extends qw( DBIx::Class::ResultSet Moose::Object );
    with 'Perlanet::DBIx::Class::Role::FeedResultSet';
}

{
    package Test::Schema::Feed;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('feed');
    __PACKAGE__->add_columns(qw(
        id url link title owner
    ));
    __PACKAGE__->resultset_class('Test::Schema::FeedResultSet');
}

{
    package Test::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw(
        Post
        Feed
    ));
}

my $schema = Test::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;
$schema->resultset('Feed')->create({
    id    => 'Test Feed',
    url   => "file:$Bin/var/test.xml",
    link  => 'http://test.data',
    title => 'Test feed',
    owner => 'Test demons',
});

my $perlanet = Perlanet::DBIx::Class->new(
    post_resultset => $schema->resultset('Post'),
    feed_resultset => $schema->resultset('Feed'),
);
$perlanet->run;

is($schema->resultset('Post')->count, 1);

done_testing;
