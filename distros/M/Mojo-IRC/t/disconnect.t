use warnings;
use strict;
use Test::More;
use Mojo::IRC;

plan skip_all => 'MSWin32' if $^O eq 'MSWin32';

our (@buf, $close);

my $irc = Mojo::IRC->new(nick => 'test123', stream => dummy_stream());
my @args;

$irc->disconnect(sub { @args = @_ });
is_deeply \@buf, ["QUIT\r\n"], 'QUIT is sent';
is $close, 1, 'stream was closed';
is $args[0], $irc, 'callback was called';

is $irc->disconnect, $irc, 'disconnect without callback';

delete $irc->{stream};
is $irc->disconnect, $irc, 'disconnect without callback';

done_testing;

sub dummy_stream {
  eval
    "package Dummy::Stream; sub close { \$main::close++; } sub write { shift; push \@main::buf, shift; shift->() } 1";
  bless {}, "Dummy::Stream";
}
