use strict;
use Test::More 0.98;
use FindBin;
use Plift;
use Test::Exception;

my $engine = Plift->new(
    paths => ["$FindBin::Bin/templates", "$FindBin::Bin/other_templates"],
);


isa_ok $engine->template('index'), "Plift::Context", 'template()';
isa_ok $engine->process('index'), 'XML::LibXML::jQuery', 'process()';
like $engine->render('index'), qr/Hello Plift/, 'render()';


subtest 'has_template' => sub {

    is $engine->has_template('index'), 1;
    is $engine->has_template('unknown'), '';
};


subtest 'relative' => sub {

    my $c = $engine->template('relative');
    my $doc = $c->render();

    # note $doc->as_html;
    is $doc->find('body > header')->size, 1;
    is $doc->find('body > section')->size, 1;
    is $doc->find('body > footer')->size, 1;
    is $doc->find('body > inner > deep')->size, 1;
    is $doc->find('body > inner > section')->size, 1;
};


subtest '_load_template' => sub {

    my $c = $engine->template('index');

    is $engine->_load_template('index', $engine->paths, $c)->find('h1')->text, 'Hello Plift';
    is $c->{current_file}, "$FindBin::Bin/templates/index.html";
    is $c->{current_path}, "$FindBin::Bin/templates";

    my $document = $c->document->get(0);
    isa_ok $document, 'XML::LibXML::Document', 'ctx->document';

    # import nodes to existing document
    ok $engine->_load_template('layout', $engine->paths, $c)->document->get(0)
                                                            ->isSameNode($document);

    # inline
    is $engine->_load_template(\'<div/>', $engine->paths, $c)->filter('div')->size, 1;
    ok $engine->_load_template(\'<div/>', $engine->paths, $c)
              ->document->get(0)
              ->isSameNode($document);
};


subtest 'data-plift-template' => sub {

    my $doc = $engine->process('layout/header');
    # note $doc->as_html;
    is $doc->find('body')->size, 0;
    is $doc->find('header')->size, 1;


};

subtest 'get_handler' => sub {

    my $include_handler = $engine->get_handler('include');
    is $include_handler->{xpath}, './/x-include | .//*[@data-plift-include]';
};


subtest 'add_handler' => sub {

    my $foo_handler = sub {};
    my $bar_handler = sub {};

    $engine->add_handler({
        name => 'foo',
        tag => 'foo',
        attribute => 'data-foo',
        handler => $foo_handler

    })->add_handler({
        name => 'bar',
        tag => ['x-bar', 'bar'],
        attribute => [qw/ data-bar bar /],
        handler => $bar_handler
    });

    is $engine->get_handler('foo')->{xpath}, './/foo | .//*[@data-foo]';
    is $engine->get_handler('foo')->{sub}, $foo_handler;
    is $engine->get_handler('bar')->{xpath}, './/x-bar | .//bar | .//*[@data-bar] | .//*[@bar]';
    is $engine->get_handler('bar')->{sub}, $bar_handler;
};





done_testing;
