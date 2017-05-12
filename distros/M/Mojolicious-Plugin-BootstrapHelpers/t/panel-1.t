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



# test from line 1 in panel-1.stencil

my $expected_panel_1_1 = qq{    <div class="panel panel-default">
        <div class="panel-body">
        </div>
    </div>};

get '/panel_1_1' => 'panel_1_1';

$test->get_ok('/panel_1_1')->status_is(200)->trimmed_content_is($expected_panel_1_1, 'Matched trimmed content in panel-1.stencil, line 1');

# test from line 16 in panel-1.stencil

my $expected_panel_1_16 = qq{    <div class="panel panel-default">
        <div class="panel-body">
            <p>A short text.</p>
        </div>
    </div>};

get '/panel_1_16' => 'panel_1_16';

$test->get_ok('/panel_1_16')->status_is(200)->trimmed_content_is($expected_panel_1_16, 'Matched trimmed content in panel-1.stencil, line 16');

# test from line 34 in panel-1.stencil

my $expected_panel_1_34 = qq{    <div class="panel panel-default">
        <div class="panel-heading">
            <h3 class="panel-title">
                <div class="btn-group pull-right">
                    <a class="btn btn-default" data-holder="claw" href="#">Click me</a>
                    <div class="btn-group">
                        <a type="button" href="#" data-toggle="dropdown" class="btn btn-default dropdown-toggle">Tap-tap <span class="caret"></span></a>
                        <ul class="dropdown-menu">
                            <li><a tabindex="-1" href="#" class="menuitem">Me too</a></li>
                        </ul>
                    </div>
                </div>The Header</h3>
        </div>
        <div class="panel-body">
            <p>A short text.</p>
        </div>
    </div>};

get '/panel_1_34' => 'panel_1_34';

$test->get_ok('/panel_1_34')->status_is(200)->trimmed_content_is($expected_panel_1_34, 'Matched trimmed content in panel-1.stencil, line 34');

# test from line 67 in panel-1.stencil

my $expected_panel_1_67 = qq{    <div class="panel panel-success">
        <div class="panel-heading">
            <h3 class="panel-title">Panel 5</h3>
        </div>
        <div class="panel-body">
            <p>A short text.</p>
        </div>
    </div>};

get '/panel_1_67' => 'panel_1_67';

$test->get_ok('/panel_1_67')->status_is(200)->trimmed_content_is($expected_panel_1_67, 'Matched trimmed content in panel-1.stencil, line 67');

done_testing();

__DATA__

@@ panel_1_1.html.ep

    %= panel

@@ panel_1_16.html.ep

    %= panel undef ,=> begin

        <p>A short text.</p>

    %  end

@@ panel_1_34.html.ep

    <%= panel 'The Header', -header => [

                            buttongroup => [buttons => [

                                ['Click me', ['#'], data => { holder => 'claw'}],

                                ['Tap-tap', ['#'], caret, items => [

                                    ['Me too', ['#']]

                                ]],

                            ]]] => begin %>

        <p>A short text.</p>

    %  end

@@ panel_1_67.html.ep

    %= panel 'Panel 5', success, begin

        <p>A short text.</p>

    %  end

