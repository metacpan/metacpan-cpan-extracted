#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'Socialtext::Wikrad';
    use_ok 'Socialtext::Wikrad::Window';
    use_ok 'Socialtext::Wikrad::PageViewer';
    use_ok 'Socialtext::Wikrad::Listbox';
}
