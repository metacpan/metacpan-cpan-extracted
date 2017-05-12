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



# test from line 1 in input_group-1.stencil

my $expected_input_group_1_1 = qq{    <div class="input-group">
        <span class="input-group-addon"><input name="agreed" type="checkbox" /></span>
        <input class="form-control" id="username" type="text" name="username" />
    </div>};

get '/input_group_1_1' => 'input_group_1_1';

$test->get_ok('/input_group_1_1')->status_is(200)->trimmed_content_is($expected_input_group_1_1, 'Matched trimmed content in input_group-1.stencil, line 1');

# test from line 15 in input_group-1.stencil

my $expected_input_group_1_15 = qq{    <div class="input-group input-group-lg">
        <span class="input-group-addon"><input name="yes" type="radio" /></span>
        <input class="form-control" id="username" type="text" name="username" />
        <span class="input-group-addon">@</span>
    </div>};

get '/input_group_1_15' => 'input_group_1_15';

$test->get_ok('/input_group_1_15')->status_is(200)->trimmed_content_is($expected_input_group_1_15, 'Matched trimmed content in input_group-1.stencil, line 15');

# test from line 33 in input_group-1.stencil

my $expected_input_group_1_33 = qq{    <div class="input-group">
        <input class="form-control" id="username" type="text" name="username" />
        <span class="input-group-btn"><button class="btn btn-default" type="button">Click me!</button></span>
    </div>};

get '/input_group_1_33' => 'input_group_1_33';

$test->get_ok('/input_group_1_33')->status_is(200)->trimmed_content_is($expected_input_group_1_33, 'Matched trimmed content in input_group-1.stencil, line 33');

# test from line 49 in input_group-1.stencil

my $expected_input_group_1_49 = qq{    <div class="input-group">
        <input class="form-control" id="username" type="text" name="username" />
        <div class="input-group-btn">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">The button <span class="caret"></span>
            </button>
            <ul class="dropdown-menu dropdown-menu-right">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>};

get '/input_group_1_49' => 'input_group_1_49';

$test->get_ok('/input_group_1_49')->status_is(200)->trimmed_content_is($expected_input_group_1_49, 'Matched trimmed content in input_group-1.stencil, line 49');

# test from line 79 in input_group-1.stencil

my $expected_input_group_1_79 = qq{    <div class="input-group">
        <div class="input-group-btn">
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
        </div>
        <input class="form-control" id="username" type="text" name="username" />
    </div>};

get '/input_group_1_79' => 'input_group_1_79';

$test->get_ok('/input_group_1_79')->status_is(200)->trimmed_content_is($expected_input_group_1_79, 'Matched trimmed content in input_group-1.stencil, line 79');

done_testing();

__DATA__

@@ input_group_1_1.html.ep

    <%= input input => { text_field => ['username'] },

              prepend => { check_box => ['agreed'] }

    %>

@@ input_group_1_15.html.ep

    <%= input large,

              prepend => { radio_button => ['yes'] },

              input => { text_field => ['username'] },

              append => '@'

    %>

@@ input_group_1_33.html.ep

    <%= input input => { text_field => ['username'] },

              append => { button => ['Click me!'] },

    %>

@@ input_group_1_49.html.ep

    <%= input input  => { text_field => ['username'] },

              append => { buttongroup => [['The button', caret, right, items => [

                                  ['Item 1', ['item1'] ],

                                  ['Item 2', ['item2'] ],

                                  [],

                                  ['Item 3', ['item3'] ],

                              ] ] ]

                        }

    %>

@@ input_group_1_79.html.ep

    <%= input input   => { text_field => ['username'] },

              prepend => { buttongroup => [

                              buttons => [

                                ['Link 1', ['http://www.example.com/'] ],

                                [undef, caret, items => [

                                      ['Item 1', ['item1'] ],

                                      ['Item 2', ['item2'] ],

                                      [],

                                      ['Item 3', ['item3'] ],

                                  ],

                               ],

                            ],

                         ],

                      },

    %>

