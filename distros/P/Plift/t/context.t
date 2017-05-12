use strict;
use Test::More 0.98;
use FindBin;
use Plift;
use Test::Exception;
use XML::LibXML::jQuery;

my $engine = Plift->new(
    paths => ["$FindBin::Bin/templates", "$FindBin::Bin/other_templates"],
);

subtest 'set()' => sub {

    my $ctx = $engine->template('index');

    $ctx->set('name', 'Carlos Fernando')
        ->set({
            foo => 'foo value',
            bar => 'bar value',
        })
        ->set('items', [
            { name => 'Item 1', description => 'Item 1 description' },
            { name => 'Item 2', description => 'Item 2 description' },
            { name => 'Item 3', description => 'Item 3 description' },
        ]);

    is_deeply $ctx->data, {
        name => 'Carlos Fernando',
        foo => 'foo value',
        bar => 'bar value',
        items => [
            { name => 'Item 1', description => 'Item 1 description' },
            { name => 'Item 2', description => 'Item 2 description' },
            { name => 'Item 3', description => 'Item 3 description' },
        ]
    }, 'data';
};


subtest 'get()' => sub {

    my $ctx = $engine->template('index');

    my $object = Some::Class->new;
    $object->{plain_key} = 'foo';

    $ctx->set({
        value => 'foo',
        hash => { value => 'foo' },
        deep => { hash => { value => 'foo' } },
        array => [qw/ foo bar baz /],
        complex => {
            array_of_hash => [{ value => 'foo' }],
            hash_of_array => { items => ['foo']},
        },
        object => $object,
        code => sub { 'foo' },
        user => {
            name => sub { "$_[1]->{first_name} $_[1]->{last_name}"},
            alt_name => sub { $_[0]->get('user.first_name') .' '. $_[0]->get('user.last_name') },
            first_name => 'First',
            last_name => 'Last',
        },
        hash_from_code => sub { +{ value => 'foo' } },
        object_from_code => sub { $object }
    });

    is $ctx->get('value'), 'foo', 'value';
    is $ctx->get('hash.value'), 'foo', 'hash.value';
    is $ctx->get('deep.hash.value'), 'foo', 'deep.hash.value';
    is $ctx->get('array.0'), 'foo', 'array.0';
    is $ctx->get('array.1'), 'bar', 'array.1';
    dies_ok { $ctx->get('array.foo'), 'bar', 'array.1' } 'array.foo';
    is $ctx->get('complex.array_of_hash.0.value'), 'foo', 'complex.array_of_hash.0.value';
    is $ctx->get('complex.hash_of_array.items.0'), 'foo', 'complex.hash_of_array.items.0.value';
    is $ctx->get('object.plain_key'), $object->{plain_key}, 'object.plain_key';
    is $ctx->get('object.foo_method'), $object->foo_method, 'object.method';
    dies_ok { $ctx->get('object.invalid') } 'object.invalid';
    is $ctx->get('code'), 'foo', 'code';
    dies_ok { $ctx->get('code.foo') } 'traverse thru code';
    is $ctx->get('user.name'), 'First Last', 'code with data args';
    is $ctx->get('user.alt_name'), 'First Last', 'code with data args';
    is $ctx->get('hash_from_code.value'), 'foo', 'hash_from_code.value';
    is $ctx->get('object_from_code.foo_method'), $object->foo_method, 'object_from_code.method';
};


subtest 'at' => sub {

    my $c = $engine->template('index');

    $c->at(one => '1')
      ->at([ two => 2, three => 3 ])
      ->push_at('article', 'posts')
      ->at('.title' => 'title')
      ->at(['.content' => 'content', '.author' => 'author'])
      ->pop_at
      ->at(four => 4);

    is_deeply $c->directives->{directives}, [
        one => 1,
        two => 2,
        three => 3,
        article => {
            posts => [
                '.title' => 'title',
                '.content' => 'content',
                '.author' => 'author'
            ]
        },
        four => 4
    ];
};


subtest 'selector_for' => sub {

    my $c = $engine->template('index');
    my $div = j('<div />');

    is $c->selector_for($div), sprintf('*[%s="%s"]', $c->internal_id_attribute, $div->get(0)->unique_key);
};


subtest 'render' => sub {

    my $c = $engine->template('index');

    my $doc = $c->render;
    isa_ok $doc->get(0), 'XML::LibXML::Document';
    is $doc->find('h1')->size, 1;
};


subtest 'active_handlers' => sub {

    my $c = $engine->template('wrap/wrap', {
        active_handlers => ['include']
    });

    my $doc = $c->render;
    is $doc->find('x-wrap')->size, 1;
    is $doc->find('section')->size, 1;
};


subtest 'inactive_handlers' => sub {

    my $c = $engine->template('wrap/wrap', {
        inactive_handlers => ['wrap']
    });

    my $doc = $c->render;
    is $doc->find('x-wrap')->size, 1;
    is $doc->find('section')->size, 1;
};

subtest 'helper' => sub {

    my $engine = Plift->new(
        paths  => ["$FindBin::Bin/templates"],
        helper => Some::Class->new
    );

    $engine->add_handler({
        name => 'test_helper',
        tag => 'section',
        handler => sub {
            my ($el, $ctx) = @_;
            $el->text($ctx->foo_method);
        }
    });

    my $ctx = $engine->template('section');
    my $doc = $ctx->render;
    is $doc->find('section')->text, 'foo', 'context helper';
};


subtest 'abort()' => sub {


    my $c = $engine->template(\'<foo/><bar/>');


    $c->set( msg => 'must not render' )
      ->at(
        foo => sub {
            my ($e, $c) = @_;
            $e->text('OK');
            $c->abort;
        },
        bar => 'msg'
    );

    my $doc = $c->render;

    is $doc->find('foo')->text, 'OK';
    is $doc->find('bar')->text, '';


};

done_testing;


{
    package Some::Class;
    use Moo;

    sub foo_method { 'foo' }
}
