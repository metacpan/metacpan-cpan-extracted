package MyTest;

use Mojo::Base -strict;
use Browser::Open;

our @browser_open_cb = ();
Mojo::Util::monkey_patch 'Browser::Open', open_browser => sub {
    $_->(@_) for @browser_open_cb;
};

1;
