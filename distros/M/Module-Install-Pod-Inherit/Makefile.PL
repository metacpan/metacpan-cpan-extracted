#!/usr/bin/perl
use warnings;
use strict;
use inc::Module::Install;

all_from 'lib/Module/Install/Pod/Inherit.pm';

requires 'Pod::Inherit' => '0.03';

WriteAll;

