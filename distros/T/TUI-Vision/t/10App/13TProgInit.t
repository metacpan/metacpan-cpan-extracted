use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App::ProgInit';
}

isa_ok(
  TProgInit->new(
    cStatusLine => sub { },
    cMenuBar    => sub { },
    cDeskTop    => sub { },
  ),
  TProgInit
);

lives_ok {
  my $progInit = TProgInit->new(
    cStatusLine => sub { pass 'cStatusLine called without errors' },
    cMenuBar    => sub { pass 'cMenuBar called without errors' },
    cDeskTop    => sub { pass 'cDeskTop called without errors' },
  );
  $progInit->createStatusLine( bless {} );
  $progInit->createMenuBar( bless {} );
  $progInit->createDeskTop( bless {} );
} 'createStatusLine, createMenuBar and createDeskTop works correctly';

done_testing();
