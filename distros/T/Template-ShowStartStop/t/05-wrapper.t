#!/usr/bin/perl
use strict;
use warnings;
use Template::ShowStartStop;
use Template::Test;

$Template::Test::DEBUG = 1;

my $tt = Template->new({
	CONTEXT => Template::ShowStartStop->new,
});

my $vars = {
	var => 'world',
};

test_expect(\*DATA, $tt, $vars);

__DATA__
-- test --
[% WRAPPER t/templates/wrapper.tt -%]
hello [% var %]
[%- END -%]
[% PROCESS t/templates/how.tt -%]
-- expect --
<!-- START: process input text -->
<!-- START: process t/templates/wrapper.tt -->
Well,
hello world
It's a beatiful day.
<!-- STOP:  process t/templates/wrapper.tt -->
<!-- START: process t/templates/how.tt -->
How are you today?
<!-- STOP:  process t/templates/how.tt -->
<!-- STOP:  process input text -->
-- test --
[% BLOCK bold   %]<b>[% content %]</b>[% END -%]
[% BLOCK italic %]<i>[% content %]</i>[% END -%]
[% WRAPPER bold+italic %]Hello World[% END -%]
-- expect --
<!-- START: process input text -->
<!-- START: process bold -->
<b><!-- START: process italic -->
<i>Hello World</i><!-- STOP:  process italic -->
</b><!-- STOP:  process bold -->
<!-- STOP:  process input text -->
