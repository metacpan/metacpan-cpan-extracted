use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Views::WindowInit';
}

isa_ok( TWindowInit->new( cFrame => sub { } ), TWindowInit );

lives_ok {
  my $windowInit = TWindowInit->new(
    cFrame => sub { pass 'called without errors' } 
  );
  $windowInit->createFrame( bless {} );
} 'createFrame works correctly';

done_testing();
