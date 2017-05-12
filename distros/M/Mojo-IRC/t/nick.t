use strict;
use warnings;
use Mojo::IRC;
use Test::More;

my $irc = Mojo::IRC->new(user => 'foo.man', stream => dummy_stream());

$irc->irc_nick({prefix => 'what!ever@host', params => ['newnick']});
is $irc->nick, 'foo_man', 'nick() did not change to newnick';

$irc->irc_nick({prefix => 'foo_man!foo.man@host', params => ['foowoman']});
is $irc->nick, 'foowoman', 'nick() changed to foowoman';

my %nicks = qw( ~ tilde & and @ at % percent + plus );
my $old   = $irc->nick;
while (my ($prefix, $new) = each %nicks) {
  $irc->irc_nick({prefix => "$prefix$old!user\@host", params => [$new]});
  is $irc->nick, $new, "nick() changed to $new";
  $old = $irc->nick;
}

sub dummy_stream {
  eval "package Dummy::Stream; sub write { shift; push \@main::buf, shift; shift->() } 1";
  bless {}, "Dummy::Stream";
}

done_testing;
