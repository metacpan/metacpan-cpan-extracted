#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan skip_all =>
  'set LEANKIT_EMAIL, LEANKIT_PASSWORD, LEANKIT_ACCOUNT to enable these tests'
  unless $ENV{LEANKIT_EMAIL}
  && $ENV{LEANKIT_PASSWORD}
  && $ENV{LEANKIT_ACCOUNT};

diag("Testing LeanKit Boards API");

use_ok('Net::LeanKit');

my $email = $ENV{LEANKIT_EMAIL};
my $password = $ENV{LEANKIT_PASSWORD};
my $account = $ENV{LEANKIT_ACCOUNT};

my $lk = Net::LeanKit->new(
    email => $email,
    password => $password,
    account  => $account
);

my $boards = $lk->getBoards;
my $boardId = $boards->{content}->[0]->{Id};
my $board = $lk->getBoard($boardId);

ok(!$board->{IsArchived}, 'Test Board boolean');

ok(length $boards, "Found some boards.");
ok($board, "Got board");
ok(length $board->{content}->{Lanes}, "Board lanes exists");
ok(length $lk->getBoardIdentifiers($boardId), "Got identifiers: ".$boardId);
ok(length $lk->getBoardBacklogLanes($boardId), "got backlog lanes");
ok(length $lk->getBoardArchiveLanes($boardId), "got archive lanes");
ok(length $lk->getBoardArchiveCards($boardId), "got archive cards");
my $getBoardByName = $lk->getBoardByName($board->{content}->{Title});
ok($getBoardByName->{Title} eq $board->{content}->{Title}, "Matched board title");


done_testing();
