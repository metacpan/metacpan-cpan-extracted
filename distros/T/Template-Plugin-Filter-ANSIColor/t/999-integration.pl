use Template;

use warnings;
use strict;

my $engine = Template->new(
	PLUGIN_BASE => 'Template::Plugin::Filter'
) || die Template->error();

$engine->process(\*DATA)
	|| die $engine->error();

__DATA__
[% USE ANSIColor 'color' %]
[% "this is red on bright yellow " | color 'red' 'on_bright_yellow' %]
[% "this is green on blue " | color 'green' 'on_blue' %]
[% "this is bright cyan on yellow " | color 'bright_cyan' 'on_yellow' %]
[% "this is simply green " | color 'green' %]
[% "this is default on bright magenta" | color 'on_bright_magenta' %]

nocolor is turned on:
[% "this is default on bright magenta and nocolor=1" | color 'on_bright_magenta' nocolor = 1 %]

