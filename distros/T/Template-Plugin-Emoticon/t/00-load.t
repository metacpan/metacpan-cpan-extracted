use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'Template::Plugin::Emoticon' }

diag "Testing Template::Plugin::Emoticon "
   . "$Template::Plugin::Emoticon::VERSION, Perl $], $^X";
