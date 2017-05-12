#!/usr/bin/env perl

use warnings;
use strict;

use URI::Escape;

use NetSDS::Util::Text qw(text_encode text_decode text_recode);
use NetSDS::Util::Misc qw(str2uri);

my $var = "жопа жопа жопа проверка связи 3-й раз блин не то бегает, что нескол";

$var = text_encode($var);

$var = text_decode($var, "UTF16-BE");

print length($var) . uri_escape($var,"\0-\xff");

