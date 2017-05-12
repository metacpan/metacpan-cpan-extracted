#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => <tmpl_var nummodules>;

BEGIN {
<tmpl_loop modules>
    use_ok('<tmpl_var modules_item>');
</tmpl_loop>
}

diag(
<tmpl_loop modules>
    "Testing <tmpl_var modules_item> $<tmpl_var modules_item>::VERSION, Perl $], $^X\n",
</tmpl_loop>
);
