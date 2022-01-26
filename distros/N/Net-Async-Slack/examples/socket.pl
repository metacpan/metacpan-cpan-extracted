#!/usr/bin/env perl
use strict;
use warnings;

=pod

Simple socket-mode example.

Intended to show how you'd build a socket-mode app, doesn't really do anything useful
but should at least show any messages sent to the bot while running.

You will need to set up an app and oauth - you can use a manifest for this, for example:

 _metadata:
   major_version: 1
 display_information:
   name: Slack socketmode example
 features:
   app_home:
     home_tab_enabled: true
     messages_tab_enabled: true
     messages_tab_read_only_enabled: false
   bot_user:
     display_name: slacktest
 settings:
   org_deploy_enabled: false
   socket_mode_enabled: true
   is_hosted: false
   token_rotation_enabled: false
 oauth_config:
   scopes:
     bot:
       - commands
       - chat:write
       - chat:write.public
   redirect_urls:
     - https://slacktest.perl.local/slack/auth

See L<https://api.slack.com/reference/manifests> for more information.

=cut

use experimental qw(signatures);
use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'debug';
use Syntax::Keyword::Try;
use Future::AsyncAwait;
use Net::Async::Slack;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use YAML::XS ();

my $loop = IO::Async::Loop->new;

my ($cfg_path) = @ARGV;
my $cfg = YAML::XS::LoadFile($cfg_path || die 'need config')
    or die 'need a config.yml file';

$loop->add(
    my $slack = Net::Async::Slack->new(
        client_id => ($cfg->{slack}{client_id} // die 'no slack client ID'),
        token     => ($cfg->{slack}{bot_token} // die 'no slack bot token - see https://api.slack.com/apps/' . ($cfg->{slack}{app_id} // 'unknown-app') . '/oauth'),
        app_token => ($cfg->{slack}{app_token} // die 'no app token'),
        debug => 1,
    )
);
my $sock = await $slack->socket_mode;
$loop->add(
    my $timer = IO::Async::Timer::Periodic->new(
        on_tick => sub {
            $log->infof('Last frame received %.2fs ago', $loop->time - $sock->last_frame_epoch);
        },
        interval => 5,
    )
);
$timer->start;

$sock->events->map(async sub ($ev) {
    try {
        $log->infof('Received event %s as %s', $ev->type, $ev);
        if($ev->type eq 'message') {
            my $content = $ev->text;
            $log->infof('Message received: %s', $content);
        } elsif($ev->type eq 'block_actions') {
            $log->infof('Block actions');
        } else {
            $log->warnf('Had event %s and will ignore it', $ev->type, $ev);
        }
        $log->infof('Finished event %s as %s', $ev->type, $ev);
    } catch($e) {
        $log->errorf('Failed to handle %s event - %s', $ev->type, $e);
    }
})->ordered_futures(
    low => 10,
    high => 100,
)->completed->on_ready(sub {
    $log->errorf('done message loop?')
})->on_fail(sub {
    $log->errorf('failed - %s', shift)
})->retain;

$log->infof('Infinite loop');
$loop->run;

