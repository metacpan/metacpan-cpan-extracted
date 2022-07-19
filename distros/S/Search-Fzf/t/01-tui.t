#!perl
use 5.006;
use strict;
use warnings;
use Curses;
use Term::Terminfo;
# use Search::Fzf::Tui;
use Test::More tests => 4;

my $ti = Term::Terminfo->new;
isa_ok $ti, 'Term::Terminfo', 'Term::Terminfo';

my $win = initscr;
is(ref($win), 'Curses::Window', 'Curses init ok.');

use_ok( 'Search::Fzf::Tui' ) || print "Bail out!\n";

my %keymap = ();
my $CONFIG = {
  # Search
  prompt => "> You Entered: ",
  pointer => '>',
  marker => '*',
  algo => 'v2', #v1, v2, exact, regex
  incaseSensitive => 0,
  sort => 0,
  # height => 10, #if height =0, fullscreen
  delimiter => '\s+',
  # nth => '1,2,3',
  # nth => '1..3',
  nth => undef,
  # withNth => '1,2,3,4',
  # withNth => '1..4',
  withNth => undef,
  tac => 0,
  disable => 0,

  #Color
  colorFg => 'default',
  colorBg => 'default',
  colorFgPlus => 'default',
  colorBgPlus => 'cyan',
  colorHl => 'red',
  colorHlPlus => 'red',
  # colorHlPlus => 'magenta',
  colorPointer => 'blue',
  colorMarker => 'green',
  colorGutter => 'default',
  colorInfo => 'white',
  colorPrompt => 'grey8',
  colorHeader => 'grey5',
  colorQuery => 'yellow',
  colorDisabled => 'grey5',
  colorSpinner => 'green',
  colorFgReview => 'default',
  colorBgReview => 'default',
  
  #Interface
  multi => 1,
  cycle => 1,
  mouse => 0,
  keepRight => 0,
  hScroll => 1,
  #缺省为5, 若小于0, 则当行长超过显示宽度时不会跟踪显示最后匹配的字符
  hScrollOff => 5,
  # hScrollOff => 0,
  keymap => \%keymap,
  # jumpLabel => ['a'..'z'],
  # jumpLabel => ['d', 'e', 'f'],
  jumpLabel => undef,
  border => 0,
  topMargin => 0,
  bottomMargin => 0,
  leftMargin => 0,
  rightMargin => 0,
  topPadding => 0,
  bottomPadding => 0,
  leftPadding => 0,
  rightPadding => 0,
  layout => 0, #0 default 1 reverse 2 reverse list
  info => 0, #0 default 1 incline 2 hidden
  # header => "Header test...Header test...Header test...Header test...Header test...",
  headerLines => 0,
  headerFirst => 0,
  review => 1,
  # reviewFunc => \&addTestFunc,
  # reviewFunc => \&defaultReviewFunc,
  # reviewWithColor => 0,
  # reviewFunc => \&batReviewFunc,
  reviewFunc => undef,
  reviewWithColor => 1,
  reviewPosition => 1, #0 up 1 down 2 left 3 right
  reviewBorder => 1,
  reviewWrap => 0,
  reviewScrollOff => 0, #scroll off
  reviewCyclic => 0,
  reviewHead => 0,
  reviewStatus => 0,
  reviewFollow => 0,

  # inputFunc => \&defaultInputFunc,
  inputFunc => undef,
  # execFunc => \&defaultExecFunc,
  execFunc => undef,
  #getch timeout
  timeout => 100,
};

my $tui = new Search::Fzf::Tui($CONFIG); 
isa_ok $tui, 'Search::Fzf::Tui', 'Search::Fzf::Tui';



