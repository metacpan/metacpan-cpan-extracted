#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

use_ok('Parse::IRCLog');

ok(
  (my $patterns = Parse::IRCLog->patterns),
  "patterns retrieved"
);

my @ok_nicks = qw( rjbs lathos nwp_ {KM} q[lamech] _james_ BenC` []\\`_^{|}- _01 );
my @ko_nicks = qw( -nick (nick) 01 );

my @ok_chans = ( '+irchelp', '&', '#_secret', '#racecar#', '!CH4N3l\xFE\xFF' );
my @ko_chans = ( 'channel',  "#\a", "+\r", '&,', '# ', '#::' );

my @ok_brack = ( '<@rjbs:#kwiki>', '< rjbs >', '< @q[uri]>', '< @ rjbs:&#&>',
                 '<%halfop>', '<+voiced>' );

# the regexes in $patterns aren't ^$ anchored, so we can't use like()
# and unlike() directly.

sub valid   { like  ( $_, qr/^$_[0]$/, $_[1] ) }
sub invalid { unlike( $_, qr/^$_[0]$/, $_[1] ) }

valid  ($patterns->{nick},           "$_ is an ok nick")           for (@ok_nicks);
invalid($patterns->{nick},           "$_ is not an ok nick")       for (@ko_nicks);
valid  ($patterns->{chan},           "$_ is an ok chan")           for (@ok_chans);
invalid($patterns->{chan},           "$_ is not an ok chan")       for (@ko_chans);
valid  ($patterns->{nick_container}, "$_ is an ok nick container") for (@ok_brack);
