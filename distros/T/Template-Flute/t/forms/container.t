#!perl

use strict;
use warnings;
use Test::More tests => 1;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml = <<EOF;
<specification name="test">
<form name="login" id="login">
<field name="email" id="email" />
<field name="password" id="password" />
</form>
<container name="login" value="!username"/>
</specification>
EOF

my $html = <<EOF;
<div class="login">
<form name="login" id="login">
<input type="email" id="email">
<input type="password" id="password">
</form>
</div>
EOF

# process
my $flute = Template::Flute->new(specification => $xml,
                                 template => $html,
                                 );

my $out = $flute->process;

ok ($out =~ m%<form id="login" name="login"><input id="email" type="email" /><input id="password" type="password" /></form>%, "Test whether form appears within container")
    || diag "Output: $out.";
