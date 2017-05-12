#!/usr/bin/perl

use strict;

opendir T, "templates";
chdir "templates";
chmod 0644, grep { !/^..?$/ } readdir T;
