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



# test from line 1 in button_group-1.stencil

my $expected_button_group_1_1 = qq{    <div class="btn-group">
        <button class="btn btn-default" type="button">Button 1</button>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>};

get '/button_group_1_1' => 'button_group_1_1';

$test->get_ok('/button_group_1_1')->status_is(200)->trimmed_content_is($expected_button_group_1_1, 'Matched trimmed content in button_group-1.stencil, line 1');

# test from line 20 in button_group-1.stencil

my $expected_button_group_1_20 = qq{    <div class="btn-group btn-group-sm">
        <button class="btn btn-default" type="button">Button 1</button>
        <div class="btn-group btn-group-sm">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>};

get '/button_group_1_20' => 'button_group_1_20';

$test->get_ok('/button_group_1_20')->status_is(200)->trimmed_content_is($expected_button_group_1_20, 'Matched trimmed content in button_group-1.stencil, line 20');

# test from line 59 in button_group-1.stencil

my $expected_button_group_1_59 = qq{    <div class="btn-group-vertical">
        <button class="btn btn-default" type="button">Button 1</button>
        <div class="btn-group">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>};

get '/button_group_1_59' => 'button_group_1_59';

$test->get_ok('/button_group_1_59')->status_is(200)->trimmed_content_is($expected_button_group_1_59, 'Matched trimmed content in button_group-1.stencil, line 59');

# test from line 97 in button_group-1.stencil

my $expected_button_group_1_97 = qq{    <div class="btn-group btn-group-justified">
        <div class="btn-group">
            <button class="btn btn-default" type="button">Button 1</button>
        </div>
        <div class="btn-group">
            <button class="btn btn-default" type="button">Button 2</button>
        </div>
        <div class="btn-group">
            <button class="btn btn-default" type="button">Button 3</button>
        </div>
    </div>};

get '/button_group_1_97' => 'button_group_1_97';

$test->get_ok('/button_group_1_97')->status_is(200)->trimmed_content_is($expected_button_group_1_97, 'Matched trimmed content in button_group-1.stencil, line 97');

# test from line 124 in button_group-1.stencil

my $expected_button_group_1_124 = qq{    <div class="btn-group btn-group-justified">
        <a class="btn btn-default" href="http://www.example.com/">Link 1</a>
        <a class="btn btn-default" href="http://www.example.com/">Link 2</a>
        <div class="btn-group dropup">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropup 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>};

get '/button_group_1_124' => 'button_group_1_124';

$test->get_ok('/button_group_1_124')->status_is(200)->trimmed_content_is($expected_button_group_1_124, 'Matched trimmed content in button_group-1.stencil, line 124');

# test from line 160 in button_group-1.stencil

my $expected_button_group_1_160 = qq{    <div class="btn-group">
        <a class="btn btn-default" href="http://www.example.com/">Link 1</a>
        <div class="btn-group">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown"><span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>};

get '/button_group_1_160' => 'button_group_1_160';

$test->get_ok('/button_group_1_160')->status_is(200)->trimmed_content_is($expected_button_group_1_160, 'Matched trimmed content in button_group-1.stencil, line 160');

# test from line 194 in button_group-1.stencil

my $expected_button_group_1_194 = qq{    <div class="btn-group">
        <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Default <span class="caret"></span>
        </button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
            <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
        </ul>
    </div>

    <div class="btn-group">
        <button class="btn btn-danger btn-lg dropdown-toggle" type="button" data-toggle="dropdown">Big danger <span class="caret"></span>
        </button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
            <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
        </ul>
    </div>};

get '/button_group_1_194' => 'button_group_1_194';

$test->get_ok('/button_group_1_194')->status_is(200)->trimmed_content_is($expected_button_group_1_194, 'Matched trimmed content in button_group-1.stencil, line 194');

done_testing();

__DATA__

@@ button_group_1_1.html.ep

    <%= buttongroup

        buttons => [

            ['Button 1'],

            ['Button 2'],

            ['Button 3'],

        ]

    %>

@@ button_group_1_20.html.ep

    <%= buttongroup small,

        buttons => [

            ['Button 1'],

            ['Dropdown 1', caret, items => [

                ['Item 1', ['item1'] ],

                ['Item 2', ['item2'] ],

                [],

                ['Item 3', ['item3'] ],

            ] ],

            ['Button 2'],

            ['Button 3'],

        ],

    %>

@@ button_group_1_59.html.ep

    <%= buttongroup vertical,

        buttons => [

            ['Button 1'],

            ['Dropdown 1', caret, items => [

                  ['Item 1', ['item1'] ],

                  ['Item 2', ['item2'] ],

                  [],

                  ['Item 3', ['item3'] ],

            ] ],

            ['Button 2'],

            ['Button 3'],

        ],

    %>

@@ button_group_1_97.html.ep

    <%= buttongroup justified,

        buttons => [

            ['Button 1'],

            ['Button 2'],

            ['Button 3'],

        ]

    %>

@@ button_group_1_124.html.ep

    <%= buttongroup justified,

        buttons => [

            ['Link 1', ['http://www.example.com/'] ],

            ['Link 2', ['http://www.example.com/'] ],

            ['Dropup 1', caret, dropup, items => [

                ['Item 1', ['item1'] ],

                ['Item 2', ['item2'] ],

                [],

                ['Item 3', ['item3'] ],

            ] ],

        ]

    %>

@@ button_group_1_160.html.ep

    <%= buttongroup

        buttons => [

            ['Link 1', ['http://www.example.com/'] ],

            [undef, caret, items => [

                ['Item 1', ['item1'] ],

                ['Item 2', ['item2'] ],

                [],

                ['Item 3', ['item3'] ],

            ] ],

        ]

    %>

@@ button_group_1_194.html.ep

    <%= buttongroup ['Default', caret, items  => [

                        ['Item 1', ['item1'] ],

                        ['Item 2', ['item2'] ],

                        [],

                        ['Item 3', ['item3'] ],

                    ] ]

    %>

    <%= buttongroup ['Big danger', caret, large, danger, items => [

                          ['Item 1', ['item1'] ],

                          ['Item 2', ['item2'] ],

                          [],

                          ['Item 3', ['item3'] ],

                    ] ]

    %>

