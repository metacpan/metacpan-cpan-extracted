use strict;
use warnings;
use lib 't/lib';

use HTML::TreeBuilder;
use Plack::Builder;
use Plack::Recorder::TestUtils;
use Plack::Test;
use Test::More tests => 11;

sub test_panel {
    my ( $res, $expected_active, $expected_start, $expected_stop ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tree    = HTML::TreeBuilder->new_from_content($res->content);
    my $panel   = $tree->look_down(
        _tag  => 'div',
        class => 'panelContent',
        sub {
            my ( $e ) = @_;

            my $title = $e->look_down(_tag => 'div',
                class => 'plDebugPanelTitle');
            $title && $title->look_down(_tag => 'h3')->as_text =~ /Recorder/;
        },
    );
    subtest 'panel test', sub {
        ok $panel, 'debugging panel was found';
        my $content = $panel->look_down(_tag => 'div',
            class => 'plDebugPanelContent');
        my $status = $content->look_down(_tag => 'div',
            class => 'plRecorderStatus');

        like $content->as_HTML, qr/\Q$expected_start\E/, "$expected_start is present in debug panel";
        like $content->as_HTML, qr/\Q$expected_stop\E/, "$expected_stop is present in debug panel";

        ok $status;
        if($expected_active) {
            like $status->as_text, qr/Request recording is ON/;
        } else {
            like $status->as_text, qr/Request recording is OFF/;
        }

        my $start = $content->look_down(_tag => 'button', class => 'plRecorderStart');
        ok $start, 'start recording button was found';
        my $stop = $content->look_down(_tag => 'button', class => 'plRecorderStop');
        ok $stop, 'stop recording button was found';

        like $start->as_text, qr/Start Recording/;
        like $stop->as_text, qr/Stop Recording/;

        done_testing;
    };
    $tree->delete;
}

my $tempfile = File::Temp->new;
close $tempfile;

my $html = <<HTML;
<html>
  <head>
    <title>Plack::Middleware::Recorder Test</title>
  </head>
  <body>
    Hi from PSGI!
  </body>
</html>
HTML

my $app = builder {
    enable 'Debug', panels => [qw/Recorder/];
    enable 'Recorder', output => $tempfile->filename;
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 1, '/recorder/start', '/recorder/stop');
    $cb->(GET '/recorder/stop');
    $res = $cb->(GET '/');
    test_panel($res, 0, '/recorder/start', '/recorder/stop');
};

$app = builder {
    enable 'Recorder', output => $tempfile->filename;
    enable 'Debug', panels => [qw/Recorder/];
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 1, '/recorder/start', '/recorder/stop');
    $cb->(GET '/recorder/stop');
    $res = $cb->(GET '/');
    test_panel($res, 0, '/recorder/start', '/recorder/stop');
};

$app = builder {
    enable 'Debug', panels => [qw/Recorder/];
    enable 'Recorder', output => $tempfile->filename, active => 0;
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 0, '/recorder/start', '/recorder/stop');
    $cb->(GET '/recorder/start');
    $res = $cb->(GET '/');
    test_panel($res, 1, '/recorder/start', '/recorder/stop');
};

$app = builder {
    enable 'Debug', panels => [qw/Recorder/];
    enable 'Recorder',
        output    => $tempfile->filename,
        start_url => '/start-recording',
        stop_url  => '/stop-recording';
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 1, '/start-recording', '/stop-recording');
    $cb->(GET '/stop-recording');
    $res = $cb->(GET '/');
    test_panel($res, 0, '/start-recording', '/stop-recording');
};

$app = builder {
    enable 'Recorder',
        output    => $tempfile->filename,
        start_url => '/start-recording',
        stop_url  => '/stop-recording';
    enable 'Debug', panels => [qw/Recorder/];
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 1, '/start-recording', '/stop-recording');
    $cb->(GET '/stop-recording');
    $res = $cb->(GET '/');
    test_panel($res, 0, '/start-recording', '/stop-recording');
};

$app = builder {
    enable 'Debug', panels => [qw/Recorder/];
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res  = $cb->(GET '/');
    my $tree = HTML::TreeBuilder->new_from_content($res->content);

    my $panel   = $tree->look_down(
        _tag  => 'div',
        class => 'panelContent',
        sub {
            my ( $e ) = @_;

            my $title = $e->look_down(_tag => 'div',
                class => 'plDebugPanelTitle');
            $title && $title->look_down(_tag => 'h3')->as_text =~ /Recorder/;
        },
    );

    ok !$panel, 'no debug panel is found when the recorder middleware is not enabled';
    $tree->delete;
};
