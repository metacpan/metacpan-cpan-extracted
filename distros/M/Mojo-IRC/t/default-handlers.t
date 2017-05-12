use warnings;
use strict;
use Test::More;
use Mojo::IRC;

plan skip_all => 'MSWin32' if $^O eq 'MSWin32';

my $irc = Mojo::IRC->new(nick => 'batman', stream => dummy_stream());

$irc->register_default_event_handlers;

for my $event (qw( irc_ping irc_nick irc_notice irc_rpl_welcome err_nicknameinuse )) {
  ok $irc->has_subscribers($event), "registered $event";
}

$irc->irc_notice({params => ['yikes!']});
is_deeply \@main::buf, [], 'no pass notice';

$irc->irc_notice({params => ['Ident broken stuff and other things QUOTE PASS S3creT']});
is_deeply \@main::buf, ["QUOTE PASS S3creT\r\n"], 'pass notice';

@main::buf = ();
$irc->irc_ping({params => [123]});
is_deeply \@main::buf, ["PONG 123\r\n"], 'ping/pong';

my @args;
no warnings 'redefine';
local *Mojo::IOLoop::recurring = sub { shift; @args = @_; 123; };
@main::buf = ();
$irc->irc_rpl_welcome({prefix => 'irc.whaterver.org', params => ['diffnick']});
is $irc->nick, 'diffnick', 'set new nick';
is $irc->real_host, 'irc.whaterver.org', 'got real_host';
is $irc->{ping_tid}, 123, 'recurring ping/pong is set up';
is $args[0], 60, '...every 60 second';
$args[1]->();
is_deeply \@main::buf, ["PING irc.whaterver.org\r\n"], 'ping irc.whaterver.org';

@main::buf = ();
$irc->err_nicknameinuse(
  {
    params          => ['currnick', 'newnick', 'Nickname is already in use.'],
    command_name_lc => 'err_nicknameinuse',
    raw_line     => ':some.irc.server 433 currnick newnick :Nickname is already in use.',
    command_name => 'ERR_NICKNAMEINUSE',
    command      => '433',
    prefix       => 'astral.shadowcat.co.uk'
  }
);

is $irc->nick, 'newnick_', 'nick changed on err_nicknameinuse';
is_deeply \@main::buf, ["NICK newnick_\r\n"], 'NICK newnick_';

done_testing;

sub dummy_stream {
  eval "package Dummy::Stream; sub write { shift; push \@main::buf, shift; shift->() } 1";
  bless {}, "Dummy::Stream";
}
