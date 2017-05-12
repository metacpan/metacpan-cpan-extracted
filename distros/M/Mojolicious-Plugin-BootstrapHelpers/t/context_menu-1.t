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



# test from line 1 in context_menu-1.stencil

my $expected_context_menu_1_1 = qq{    <ul class="dropdown-menu" id="my-context-menu">
        <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
        <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
        <li class="divider"></li>
        <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
    </ul>};

get '/context_menu_1_1' => 'context_menu_1_1';

$test->get_ok('/context_menu_1_1')->status_is(200)->trimmed_content_is($expected_context_menu_1_1, 'Matched trimmed content in context_menu-1.stencil, line 1');

done_testing();

__DATA__

@@ context_menu_1_1.html.ep

        <%= context_menu id => 'my-context-menu', items => [

                ['Item 1', ['item1'] ],

                ['Item 2', ['item2'] ],

                [],

                ['Item 3', ['item3'] ]

             ] %>

    </div>

