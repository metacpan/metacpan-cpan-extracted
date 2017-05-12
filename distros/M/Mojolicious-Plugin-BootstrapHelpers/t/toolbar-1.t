use Mojo::Base -strict;

BEGIN {
    $ENV{'MOJO_NO_IPV6'} = 1;
    $ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Test::Mojo::Trim;

plugin 'BootstrapHelpers', {
    icons => {
        class => 'glyphicon',
        formatter => 'glyphicon-%s',
    },
};

ok 1;

my $test = Test::Mojo::Trim->new;



# test from line 1 in toolbar-1.stencil

my $expected_toolbar_1_1 = qq{    <div class="btn-toolbar" id="my-toolbar">
        <div class="btn-group">
            <button class="btn btn-default" type="button">Button 1</button>
            <button class="btn btn-default" type="button">Button 2</button>
            <button class="btn btn-default" type="button">Button 3</button>
        </div>
        <div class="btn-group">
            <button class="btn btn-primary" type="button">Button 4</button>
            <button class="btn btn-default" type="button">Button 5</button>
            <button class="btn btn-default" type="button">Button 6</button>
        </div>
    </div>};

get '/toolbar_1_1' => 'toolbar_1_1';

$test->get_ok('/toolbar_1_1')->status_is(200)->trimmed_content_is($expected_toolbar_1_1, 'Matched trimmed content in toolbar-1.stencil, line 1');

done_testing();

__DATA__

@@ toolbar_1_1.html.ep

    <%= toolbar id => 'my-toolbar',

                groups => [

                    { buttons => [

                        ['Button 1'],

                        ['Button 2'],

                        ['Button 3'],

                      ],

                    },

                    { buttons => [

                        ['Button 4', primary],

                        ['Button 5'],

                        ['Button 6'],

                      ],

                    },

                ]

    %>

