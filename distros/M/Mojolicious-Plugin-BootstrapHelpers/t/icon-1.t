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



# test from line 1 in icon-1.stencil

my $expected_icon_1_1 = qq{    <span class="glyphicon glyphicon-copyright-mark"></span>
    <span class="glyphicon glyphicon-sort-by-attributes-alt"></span>};

get '/icon_1_1' => 'icon_1_1';

$test->get_ok('/icon_1_1')->status_is(200)->trimmed_content_is($expected_icon_1_1, 'Matched trimmed content in icon-1.stencil, line 1');

# test from line 12 in icon-1.stencil

my $expected_icon_1_12 = qq{    <span class="glyphicon glyphicon-copyright-mark"></span>};

get '/icon_1_12' => 'icon_1_12';

$test->get_ok('/icon_1_12')->status_is(200)->trimmed_content_is($expected_icon_1_12, 'Matched trimmed content in icon-1.stencil, line 12');

# test from line 21 in icon-1.stencil

my $expected_icon_1_21 = qq{    <span class="glyphicon glyphicon-sort-by-attributes-alt"></span>};

get '/icon_1_21' => 'icon_1_21';

$test->get_ok('/icon_1_21')->status_is(200)->trimmed_content_is($expected_icon_1_21, 'Matched trimmed content in icon-1.stencil, line 21');

done_testing();

__DATA__

@@ icon_1_1.html.ep

    <%= icon 'copyright-mark' %>

    %= icon 'sort-by-attributes-alt'

@@ icon_1_12.html.ep

    <%= icon 'copyright-mark' %>

@@ icon_1_21.html.ep

    %= icon 'sort-by-attributes-alt'

