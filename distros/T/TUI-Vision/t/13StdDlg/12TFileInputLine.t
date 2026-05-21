use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::StdDlg::Const', qw( cmFileFocused FA_DIREC );
  use_ok 'TUI::Views::Const', qw( sfSelected );
  use_ok 'TUI::StdDlg::FileInputLine';
}

# Minimal methods used by the code under test; no real UI needed
BEGIN {
  package Local::Owner;
  sub wildCard { $_[0]->{wildCard} }

  package Local::InfoPtr;
  sub name { $_[0]->{name} }
  sub attr { $_[0]->{attr} }

  package Local::Event;
  1;
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 1 );
isa_ok( $bounds, TRect );

subtest 'constructor' => sub {
  my $obj = TFileInputLine->new( bounds => $bounds, maxLen => 255 );
  isa_ok( $obj, TFileInputLine );
  is( $obj->{eventMask}, evBroadcast, 'eventMask set to evBroadcast' );
};

subtest 'handleEvent: ignore when selected' => sub {
  my $obj = TFileInputLine->new( bounds => $bounds, maxLen => 255 );
  isa_ok( $obj, TFileInputLine );

  $obj->{state} = sfSelected;
  $obj->{data}  = 'KEEP';

  # Owner is accessed only if directory branch runs; but we stay selected, 
  # so not needed.
  my $ev = bless {
    what    => evBroadcast,
    message => {
      command => cmFileFocused,
      infoPtr => bless({ name => 'X', attr => FA_DIREC }, 'Local::InfoPtr'),
    },
  }, 'Local::Event';

  lives_ok { $obj->handleEvent($ev); } "handleEvent lives";
  is( $obj->{data}, 'KEEP', 'data unchanged when sfSelected' );
};

subtest 'handleEvent: file focused' => sub {
  my $obj = TFileInputLine->new( bounds => $bounds, maxLen => 255 );
  isa_ok( $obj, TFileInputLine );

  $obj->{state} = 0;
  $obj->{data}  = 'OLD';

  my $ev = bless {
    what    => evBroadcast,
    message => {
      command => cmFileFocused,
      infoPtr => bless({ name => 'main.pl', attr => 0 }, 'Local::InfoPtr'),
    },
  }, 'Local::Event';

  lives_ok { $obj->handleEvent($ev); } "handleEvent lives";
  is( $obj->{data}, 'main.pl', 'data becomes file name' );
};

subtest 'handleEvent: dir focused + simple wildcard' => sub {
  my $obj = TFileInputLine->new( bounds => $bounds, maxLen => 255 );
  isa_ok( $obj, TFileInputLine );

  $obj->{state} = 0;

  # owner->wildCard is called; provide a tiny object inline
  my $owner = bless({ wildCard => '*.pl' }, 'Local::Owner');
  $obj->owner( $owner );

  my $ev = bless {
    what    => evBroadcast,
    message => {
      command => cmFileFocused,
      infoPtr => bless({ name => 'SRC', attr => FA_DIREC }, 'Local::InfoPtr'),
    },
  }, 'Local::Event';

  lives_ok { $obj->handleEvent( $ev ); } "handleEvent lives";
  is( $obj->{data}, 'SRC\\*.pl', 'data becomes "<dir>\\<wildCard>"' );
};

done_testing;
