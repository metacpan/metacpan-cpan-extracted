#!/usr/bin/perl -w

# Sample script demonstrating Number::Convert::Roman.

# Copyright (c) 2015 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;
use Number::Convert::Roman;

$\ = "\n";

my $c = Number::Convert::Roman->new;

print $c->arabic('IV');
print $c->roman(4);
