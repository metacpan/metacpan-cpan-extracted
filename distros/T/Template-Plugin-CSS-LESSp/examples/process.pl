#!/usr/bin/env perl

use Template;

my $template = Template->new()->process('style.tt', {});
