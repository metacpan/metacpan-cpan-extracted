use strict;
use warnings;
use Capture::Tiny 'capture';
use Test::More;

use System::Explain 'verbose, sys, dsys';

my ($stdout, $stderr, $exit) = capture {
  sys $^X, '-e1';
};

is $exit, 0, "$^X ran OK";
like $stdout, qr{ran with normal exit}, 'expected stdout';
is $stderr, '', 'no stderr';

eval { dsys $^X, qw(-e die); };
like $@, qr{failed}, 'dsys died with a message';

done_testing;
