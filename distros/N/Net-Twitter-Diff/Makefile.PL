use strict;
use warnings;
use inc::Module::Install;

name  'Net-Twitter-Diff';
author 'Tomohiro Teranishi <tomohiro.terranishi@gmail.com>';
all_from 'lib/Net/Twitter/Diff.pm';
requires 'Test::More'   => 0;
requires 'Net::Twitter' => '3.03000';
requires 'Array::Diff'  => 0;
license 'perl';
repository 'http://svn.coderepos.org/share/lang/perl/Net-Twitter-Diff/trunk';
auto_install;
WriteAll;

