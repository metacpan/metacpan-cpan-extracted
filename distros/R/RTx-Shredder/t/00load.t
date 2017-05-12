use Test::More tests => 7;

BEGIN { require "t/utils.pl" }

use_ok("RTx::Shredder");

use_ok("RTx::Shredder::Plugin");
use_ok("RTx::Shredder::Plugin::Base");
use_ok("RTx::Shredder::Plugin::Objects");
use_ok("RTx::Shredder::Plugin::Attachments");
use_ok("RTx::Shredder::Plugin::Tickets");
use_ok("RTx::Shredder::Plugin::Users");


