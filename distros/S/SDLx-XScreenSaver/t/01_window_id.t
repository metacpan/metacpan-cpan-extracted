# This set of tests adapted from OpenGL::XScreenSaver
# SDLx::XScreenSaver attempts to replicate the interface
# embodied in the module, so it should behave identically
# for various combinations of startup arguments

use strict;
use warnings;

use Test::More tests => 10;

use SDLx::XScreenSaver;

*_init      = \&SDLx::XScreenSaver::init;
*_window_id = \&SDLx::XScreenSaver::_window_id;

sub reset_env {
	delete($ENV{XSCREENSAVER_WINDOW});
	@ARGV = ();
	SDLx::XScreenSaver::_reset_wid();
}

my $ret;

# test 1: default should require creation of new window
reset_env();
$ret = _init();
ok(! $ret                       , "no window id leads to creation of new window (init() return value)");
is(_window_id()        , 0      , "no window id leads to creation of new window (saved window id)");

# test 2: -root option draws on the root window and won't create a new window
reset_env();
@ARGV = qw(-root);
$ret = _init();
ok($ret                         , "-root option will not create a new window");
is(_window_id()        , "ROOT" , "-root option will draw on the root window");

# test 3: resetting the environment actually works (should now create no window again)
reset_env(); $ret = _init();
ok(! $ret                       , "resetting test environment actually works (return value)");
is(_window_id()        , 0      , "resetting test environment actually works (saved window id)");

# test 4: defining window ids will make it draw to them
reset_env(); @ARGV = qw(-window-id 23);   _init();
is(_window_id()        , 23     , "-window-id works with base-10 numbers");
reset_env(); @ARGV = qw(-window-id 0x42); _init();
is(_window_id()        , 0x42   , "-window-id works with base-16 numbers");
reset_env(); @ARGV = qw(-window-id 010);  _init();
is(_window_id()        , 8      , "-window-id works with base-8 numbers");

# test 5: defining only the envvar will make it draw to that window
reset_env(); $ENV{XSCREENSAVER_WINDOW} = "0x2342"; _init();
is(_window_id()        , 0x2342 , "can read window ID from environment");
