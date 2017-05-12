#!perl

our $VERSION=0.01;

# This script tests the SysTray module.
# You can run this on Windows, Linux, or Macintosh,
# and see an icon pop up in your systray, which you
# can click on.

use strict;
use warnings;

use SysTray;

SysTray::create("my_callback", "some_icon.ico", "Hi there");

while (1) { 
  SysTray::do_events();
  select(undef, undef, undef, 0.1);
}

sub my_callback {
  my $events = shift;

  warn "Events = $events";

  if ($events & SysTray::MB_LEFT_CLICK) {
    warn "Left click event on the systray icon";
  } elsif ($events & SysTray::MB_RIGHT_CLICK) {
    warn "Right click event on the systray icon";
  }
  
  if (($events & SysTray::MSG_SHUTDOWN) || ($events & SysTray::MSG_LOGOFF)) {
    warn "";
    exit(0);
  }
}
