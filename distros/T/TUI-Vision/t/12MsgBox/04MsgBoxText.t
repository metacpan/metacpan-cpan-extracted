use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::App::Program';
  use_ok 'TUI::Views::Const', qw( cmOK cmCancel );
  use_ok 'TUI::MsgBox::Const', qw( :mfXXXX );
  use_ok 'TUI::MsgBox::MsgBoxText', qw(
    messageBox
    messageBoxRect
    inputBox
    inputBoxRect
  );
} #/ BEGIN

# Mock global $application and $deskTop used inside MsgBoxText
BEGIN {
  package MyApplication;
  our $return_code = ::cmOK;
  sub new { bless {}, shift }
  sub execView { return $return_code }
  $INC{'MyApplication.pm'} = 1;
} #/ BEGIN

BEGIN {
  package MyDeskTop;
  # minimal "size" entry to satisfy centering logic
  sub new {
    return bless { size => { x => 100, y => 40 } }, shift;
  }
  $INC{'MyDeskTop.pm'} = 1;
} #/ BEGIN

# inject mocks into used globals
$TUI::App::Program::application = MyApplication->new;
$TUI::App::Program::deskTop     = MyDeskTop->new;

# Smoke test: messageBoxRect()
subtest 'messageBoxRect' => sub {
  my $r = TRect->new( ax => 1, ay => 1, bx => 50, by => 10 );

  lives_ok {
    $MyApplication::return_code = cmOK;
    my $res = messageBoxRect( $r, "Text", mfConfirmation );
    ok( $res == cmOK, 'messageBoxRect returns execView result' );
  } 'messageBoxRect() lives';
}; #/ 'messageBoxRect' => sub

# Smoke test: messageBox()
subtest 'messageBox' => sub {
  lives_ok {
    $MyApplication::return_code = cmOK;
    my $res = messageBox( "Hello", mfWarning );
    ok( $res == cmOK, 'messageBox returns mocked execView result' );
  } 'messageBox() lives';

  lives_ok {
    # use the sprintf-path (fmt + list)
    $MyApplication::return_code = cmCancel;
    my $res = messageBox( mfError, "Value: %d", 123 );
    ok( $res == cmCancel, 'messageBox sprintf-path returns execView result' );
  } 'messageBox() sprintf path lives';
}; #/ 'messageBox' => sub

# Smoke test: inputBoxRect()
subtest 'inputBoxRect' => sub {
  my $bounds = TRect->new( ax => 1, ay => 1, bx => 30, by => 6 );
  my $data   = [ 'Test' ];

  # stub TUI::Dialogs::Dialog to avoid side effects
  no warnings 'redefine';
  local *TUI::Dialogs::Dialog::insert = sub { };
  local *TUI::Dialogs::Dialog::getData = sub { $_[1]->[0] = 'Update' };

  lives_ok {
    $MyApplication::return_code = cmOK;
    my $res = inputBoxRect( $bounds, "T", "L", $data, 20 );
    ok( $res == cmOK, 'inputBoxRect returns execView result' );
  } 'inputBoxRect() lives';
}; #/ 'inputBoxRect' => sub

# Smoke test: inputBox()
subtest 'inputBox' => sub {
  my $data  = [ 'Original' ];

  # stub TUI::Dialogs::Dialog to avoid side effects
  no warnings 'redefine';
  local *TUI::Dialogs::Dialog::insert = sub { };
  local *TUI::Dialogs::Dialog::getData = sub { $_[1]->[0] = 'Update' };

  lives_ok {
    $MyApplication::return_code = cmOK;    # simulate pressing OK
    my $res = inputBox( "Title", "Label", $data, 50 );
    ok( $res == cmOK,  'inputBox result is cmOK' );
    is_deeply( $data, [ 'Update' ], 'inputBox updated array ref when OK' );
  } 'inputBox() lives';

  lives_ok {
    $MyApplication::return_code = cmCancel;    # simulate cancel
    $data = [ 'Reset' ];
    my $res = inputBox( "T", "L", $data, 50 );
    ok( $res == cmCancel, 'inputBox result is cmCancel' );
    is_deeply( $data, [ 'Reset' ], 'array ref untouched on cancel' );
  } 'inputBox() with cancel lives';
}; #/ 'inputBox' => sub

done_testing();
