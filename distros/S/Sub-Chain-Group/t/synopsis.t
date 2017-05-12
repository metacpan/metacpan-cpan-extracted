# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.88;

use Sub::Chain::Group ();
my $pm = $INC{'Sub/Chain/Group.pm'};
my ($synopsis) = do {
  open my $fh, '<', $pm or die "failed to open $pm: $!";
  do { local $/; <$fh>; } =~ /\n=head1 SYNOPSIS\n(.+?)\n=\w+/s;
};

$synopsis = join ";\n",
  'sub trim { local $_ = shift; s/^\s+//; s/\s+$//; $_ }',
  $synopsis;

my @tests = split /\n/, <<'TESTS';
is( $trimmed, '123 Street Rd.', 'filtered field' );
is_deeply( $fruit, {apple => 'GREEN', orange => 'YTRID'}, 'filtered group with multiple chains' );
TESTS

plan tests => scalar @tests;

eval join("\n", $synopsis, @tests);
die "$@\ncode:\n\n$synopsis\n\n" if $@;
