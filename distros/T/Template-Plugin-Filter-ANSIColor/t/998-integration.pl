use Template;

use warnings;
use strict;

my $engine = Template->new(
	PLUGIN_BASE => 'Template::Plugin::Filter'
) || die Template->error();

$engine->process(\*DATA, { nocolor => 1 })
	|| die $engine->error();

__DATA__
[% USE ANSIColor 'color' nocolor = nocolor %]
You will not see the colors since color is turned off with the nocolor option

[% "this is red on bright yellow " | color 'red' 'on_bright_yellow' %]
[% "this is green on blue " | color 'green' 'on_blue' %]
[% "this is bright cyan on yellow " | color 'bright_cyan' 'on_yellow' %]
