#!/usr/bin/perl -w
use strict;

local $/ = undef;
$_ = <>;
s/\{\{\{/{{{\n/g;
s/\}\}\}/\n}}}/g;
print;
