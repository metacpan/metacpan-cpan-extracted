#! perl
#
# Tests for Template::Flute::Utils::derive_filename function.

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute::Utils;

ok(Template::Flute::Utils::derive_filename('templates/helloworld.html', '.xml')
   eq 'templates/helloworld.xml');
ok(Template::Flute::Utils::derive_filename('templates/helloworld.html', 'foobar.png', 1)
   eq 'templates/foobar.png');

