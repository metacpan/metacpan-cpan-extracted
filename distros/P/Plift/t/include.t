use strict;
use Test::More 0.98;
use FindBin;
use Plift;
use Test::Exception;

my $engine = Plift->new(
    paths => ["$FindBin::Bin/templates", "$FindBin::Bin/other_templates"],
);


subtest 'include' => sub {

    my $ctx = $engine->template('layout');
    my $doc = $ctx->render({
        skip_section => 1,
        include_all  => 1
    });

    # note $doc->as_html;
    # note "IF SECTION:".$doc->find('if section')->as_html.')';
    is $doc->find('header, footer')->size, 2;
    is $doc->find('x-include, *[data-plift-include]')->size, 0;
    is $doc->find('if.true section')->size, 1, 'if true';
    is $doc->find('if.false section')->size, 0, 'if false';
    is $doc->find('unless.true section')->size, 0, 'unless true';
    is $doc->find('unless.false section')->size, 1, 'unless false';
};

dies_ok { $engine->process('include-error') } 'missing template name';



done_testing;
