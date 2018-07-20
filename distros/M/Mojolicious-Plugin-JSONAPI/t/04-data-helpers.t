#! perl -w

use Test::Most;
use Test::MockObject;
use Mojolicious::Lite;
use Test::Mojo;

my $mock_obj = Test::MockObject->new();
$mock_obj->fake_module(
    'ResultSource',
    new               => sub { return bless {}, shift; },
    source_name       => sub { return 'post' },
    relationships     => sub { return ('author') },
    relationship_info => sub { return { attrs => { accessor => '' } } });
$mock_obj->fake_module(
    'DBIx::Result',
    new                  => sub { return bless {}, shift; },
    id                   => sub { 123 },
    result_source        => sub { ResultSource->new() },
    get_inflated_columns => sub { return (title => 'test post'); },
    has_relationship     => sub { return 1; },
    author               => sub { return DBIx::Result->new(); });

use_ok('Mojolicious::Plugin::JSONAPI');

plugin 'JSONAPI';

get '/' => sub {
    my ($c) = @_;
    my $doc = $c->resource_document(DBIx::Result->new(), { includes => [qw/author/] });
    is($doc->{id},   123);
    is($doc->{type}, 'posts');
    is_deeply($doc->{attributes}, { title => 'test post' });
    is_deeply($doc->{relationships}->{author}->{data}, { id => 123, type => 'authors' });
    like($doc->{relationships}->{author}->{links}->{related}, qr|http://127.0.0.1:\d+/posts/123/relationships/author|);
    $c->render(status => 200, json => {});
};

my $t = Test::Mojo->new();

$t->get_ok('/');

done_testing;
