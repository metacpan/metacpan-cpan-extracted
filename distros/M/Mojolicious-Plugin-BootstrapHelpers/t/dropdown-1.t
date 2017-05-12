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



# test from line 1 in dropdown-1.stencil

my $expected_dropdown_1_1 = qq{    <div class="text-right">
        <div class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="a_custom_id" data-toggle="dropdown">Dropdown 1</button>
            <ul class="dropdown-menu dropdown-menu-right">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>};

get '/dropdown_1_1' => 'dropdown_1_1';

$test->get_ok('/dropdown_1_1')->status_is(200)->trimmed_content_is($expected_dropdown_1_1, 'Matched trimmed content in dropdown-1.stencil, line 1');

# test from line 31 in dropdown-1.stencil

my $expected_dropdown_1_31 = qq{    <div class="dropdown">
        <button class="btn btn-lg btn-primary dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 2 <span class="caret"></span></button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1" data-attr="2">Item 1</a></li>
            <li class="disabled"><a class="menuitem" href="item2" tabindex="-1" data-attr="4">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1" data-attr="7">Item 3</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item4" tabindex="4">Item 4</a></li>
            <li class="dropdown-header">This is a header</li>
            <li><a class="menuitem" href="item5" tabindex="-1">Item 5</a></li>
        </ul>
    </div>};

get '/dropdown_1_31' => 'dropdown_1_31';

$test->get_ok('/dropdown_1_31')->status_is(200)->trimmed_content_is($expected_dropdown_1_31, 'Matched trimmed content in dropdown-1.stencil, line 31');

done_testing();

__DATA__

@@ dropdown_1_1.html.ep

    <div class="text-right">

        <%= dropdown

             ['Dropdown 1', id => 'a_custom_id', right, items => [

                ['Item 1', ['item1'] ],

                ['Item 2', ['item2'] ],

                [],

                ['Item 3', ['item3'] ]

             ] ] %>

    </div>

@@ dropdown_1_31.html.ep

    <%= dropdown

         ['Dropdown 2', caret, large, primary, items => [

            ['Item 1', ['item1'], data => { attr => 2 } ],

            ['Item 2', ['item2'], disabled, data => { attr => 4 } ],

            [],

            ['Item 3', ['item3'], data => { attr => 7 } ],

            [],

            ['Item 4', ['item4'], tabindex => 4 ],

            'This is a header',

            ['Item 5', ['item5'] ],

         ] ] %>

