#!/usr/bin/perl -w
use strict;
use utf8;
use warnings;
use diagnostics;
use CGI::Carp qw(fatalsToBrowser);
use lib qw(%PATH%lib);
use MySQL::Admin::GUI;
ContentHeader("%PATH%config/settings.pl");
Body();