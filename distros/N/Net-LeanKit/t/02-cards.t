#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan skip_all =>
  'set LEANKIT_EMAIL, LEANKIT_PASSWORD, LEANKIT_ACCOUNT to enable these tests'
  unless $ENV{LEANKIT_EMAIL}
  && $ENV{LEANKIT_PASSWORD}
  && $ENV{LEANKIT_ACCOUNT};

diag("Testing LeanKit Cards API");

use_ok('Net::LeanKit');

my $email    = $ENV{LEANKIT_EMAIL};
my $password = $ENV{LEANKIT_PASSWORD};
my $account  = $ENV{LEANKIT_ACCOUNT};

my $lk = Net::LeanKit->new(
    email    => $email,
    password => $password,
    account  => $account
);

my $boards = $lk->getBoards;
my $boardId = $boards->{content}->[0]->{Id};
my $identifiers = $lk->getBoardIdentifiers($boardId);

my $cards = $lk->searchCards(
    $boardId,
    {   Page       => 1,
        MaxResults => 3,
        OrderBy    => "CreatedOn"
    }
);

ok($cards->{content}->{TotalResults} > 0, "Found Cards");

ok(defined($cards->{content}->{Results}->[0]->{Title}), "A title exists in cards");

my $cardType = $identifiers->{content}->{CardTypes}->[0]->{Id};
my $laneId = $identifiers->{content}->{Lanes}->[2]->{Id};

my $newCard = {
    Title          => 'API Test',
    TypeId         => $cardType,
    Priority       => 1,
    ExternalCardId => time
};

my $res = $lk->addCard($boardId, $laneId, 0, $newCard);
ok($res->{code} == 201, sprintf("Card (%s) added.", $res->{content}->{CardId}));

$newCard = $lk->getCard($boardId, $res->{content}->{CardId});

ok($newCard->{content}->{Id} == $res->{content}->{CardId}, 'Card created');
ok($newCard->{content}->{Title} eq 'API Test', 'Card created with proper title');
ok($lk->deleteCard($boardId, $newCard->{content}->{Id}), "Deleted card");

done_testing();
