#!/usr/bin/perl

use Test;
BEGIN { plan tests => 3 };
use Sys::Protect;
use strict;
use warnings;

use XSLoader;
eval "use threads;";
ok($@);


$Sys::Protect::allowed{"Time::HiRes"} = 0;
eval "use Time::HiRes";
ok($@ ne '');

$Sys::Protect::allowed{"Time::HiRes"} = 1;
eval "use Time::HiRes";
ok($@ eq '');



1;
