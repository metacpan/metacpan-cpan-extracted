#!/usr/bin/env perl
use inc::Module::Package 'Au:dry 1';
all_from 'lib/Plack/Middleware/Static/Range.pm';
requires 'parent';
requires 'Plack::Middleware';
requires 'PerlIO::subfile';
requires 'HTTP::Message';
