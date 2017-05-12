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



# test from line 1 in badge-1.stencil

my $expected_badge_1_1 = qq{    <span class="badge">3</span></a>};

get '/badge_1_1' => 'badge_1_1';

$test->get_ok('/badge_1_1')->status_is(200)->trimmed_content_is($expected_badge_1_1, 'Matched trimmed content in badge-1.stencil, line 1');

# test from line 10 in badge-1.stencil

my $expected_badge_1_10 = qq{    <span class="badge pull-right" data-custom="yes">4</span>};

get '/badge_1_10' => 'badge_1_10';

$test->get_ok('/badge_1_10')->status_is(200)->trimmed_content_is($expected_badge_1_10, 'Matched trimmed content in badge-1.stencil, line 10');

# test from line 21 in badge-1.stencil

my $expected_badge_1_21 = qq{    <span class="badge pull-right">Badge 2</span>};

get '/badge_1_21' => 'badge_1_21';

$test->get_ok('/badge_1_21')->status_is(200)->trimmed_content_is($expected_badge_1_21, 'Matched trimmed content in badge-1.stencil, line 21');

done_testing();

__DATA__

@@ badge_1_1.html.ep

    <%= badge '3' %>

@@ badge_1_10.html.ep

    <%= badge '4', data => { custom => 'yes' }, right %>

@@ badge_1_21.html.ep

    %= badge 'Badge 2', right

