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



# test from line 1 in button-1.stencil

my $expected_button_1_1 = qq{    <button class="btn btn-lg btn-warning" type="button">The example 5</button>};

get '/button_1_1' => 'button_1_1';

$test->get_ok('/button_1_1')->status_is(200)->trimmed_content_is($expected_button_1_1, 'Matched trimmed content in button-1.stencil, line 1');

# test from line 14 in button-1.stencil

my $expected_button_1_14 = qq{    <a class="btn btn-default btn-sm" href="http://www.example.com/">The example 1</a>};

get '/button_1_14' => 'button_1_14';

$test->get_ok('/button_1_14')->status_is(200)->trimmed_content_is($expected_button_1_14, 'Matched trimmed content in button-1.stencil, line 14');

# test from line 27 in button-1.stencil

my $expected_button_1_27 = qq{    <button class="btn btn-primary" type="submit">Save 2</button>};

get '/button_1_27' => 'button_1_27';

$test->get_ok('/button_1_27')->status_is(200)->trimmed_content_is($expected_button_1_27, 'Matched trimmed content in button-1.stencil, line 27');

# test from line 40 in button-1.stencil

my $expected_button_1_40 = qq{    <button class="btn btn-primary" disabled="disabled" type="submit">Save 2</button>};

get '/button_1_40' => 'button_1_40';

$test->get_ok('/button_1_40')->status_is(200)->trimmed_content_is($expected_button_1_40, 'Matched trimmed content in button-1.stencil, line 40');

# test from line 50 in button-1.stencil

my $expected_button_1_50 = qq{    <a class="btn btn-default" href="/button_1_50">The example 2</a>};

get '/button_1_50' => 'button_1_50';

$test->get_ok('/button_1_50')->status_is(200)->trimmed_content_is($expected_button_1_50, 'Matched trimmed content in button-1.stencil, line 50');

# test from line 58 in button-1.stencil

my $expected_button_1_58 = qq{    <a class="btn btn-default" href="panel_1">The example 3</a>};

get '/button_1_58' => 'button_1_58';

$test->get_ok('/button_1_58')->status_is(200)->trimmed_content_is($expected_button_1_58, 'Matched trimmed content in button-1.stencil, line 58');

# test from line 67 in button-1.stencil

my $expected_button_1_67 = qq{    <button class="btn btn-default" type="button">The example 4</button>};

get '/button_1_67' => 'button_1_67';

$test->get_ok('/button_1_67')->status_is(200)->trimmed_content_is($expected_button_1_67, 'Matched trimmed content in button-1.stencil, line 67');

# test from line 76 in button-1.stencil

my $expected_button_1_76 = qq{    <a class="btn btn-default disabled" href="/button_1_76"> The Example 6 </a>};

get '/button_1_76' => 'button_1_76';

$test->get_ok('/button_1_76')->status_is(200)->trimmed_content_is($expected_button_1_76, 'Matched trimmed content in button-1.stencil, line 76');

# test from line 87 in button-1.stencil

my $expected_button_1_87 = qq{    <button class="btn btn-default" type="submit">Save 1</button>};

get '/button_1_87' => 'button_1_87';

$test->get_ok('/button_1_87')->status_is(200)->trimmed_content_is($expected_button_1_87, 'Matched trimmed content in button-1.stencil, line 87');

# test from line 99 in button-1.stencil

my $expected_button_1_99_active = qq{    <button class="active btn btn-default" type="button">Loop</button>};

get '/button_1_99_active' => 'button_1_99_active';

$test->get_ok('/button_1_99_active')->status_is(200)->trimmed_content_is($expected_button_1_99_active, 'Matched trimmed content in button-1.stencil, line 99');

# test from line 99 in button-1.stencil

my $expected_button_1_99_block = qq{    <button class="block btn btn-default" type="button">Loop</button>};

get '/button_1_99_block' => 'button_1_99_block';

$test->get_ok('/button_1_99_block')->status_is(200)->trimmed_content_is($expected_button_1_99_block, 'Matched trimmed content in button-1.stencil, line 99');

done_testing();

__DATA__

@@ button_1_1.html.ep

    %= button 'The example 5' => large, warning

@@ button_1_14.html.ep

    %= button 'The example 1' => ['http://www.example.com/'], small

@@ button_1_27.html.ep

    %= submit_button 'Save 2', primary

@@ button_1_40.html.ep

    %= submit_button 'Save 2', primary, disabled

@@ button_1_50.html.ep

    %= button 'The example 2' => [url_for]

@@ button_1_58.html.ep

    %= button 'The example 3' => ['panel_1']

@@ button_1_67.html.ep

    %= button 'The example 4'

@@ button_1_76.html.ep

    %= button [url_for], disabled, begin

       The Example 6

    %  end

@@ button_1_87.html.ep

    %= submit_button 'Save 1'

@@ button_1_99_active.html.ep

    %= button 'Loop', active

@@ button_1_99_block.html.ep

    %= button 'Loop', block

