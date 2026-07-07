#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name'   , "Jason");
$s->assign('is_admin', 1);

print $s->fetch();

__DATA__
Hello {$name}!

{if $is_admin}
You are an admin.
{else}
You are not an admin.
{/if}
