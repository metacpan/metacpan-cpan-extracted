use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App::DeskInit';
}

isa_ok( TDeskInit->new( cBackground => sub { } ), TDeskInit );

lives_ok {
  my $deskInit = TDeskInit->new(
    cBackground => sub { pass 'called without errors' } 
  );
  $deskInit->createBackground( bless {} );
} 'createBackground works correctly';

done_testing();
