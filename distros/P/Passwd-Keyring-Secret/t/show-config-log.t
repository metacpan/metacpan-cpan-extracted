#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Slurp qw(slurp);

use vars qw($logfile);

BEGIN
{
    $logfile = 'config.log';

    if (-e $logfile)
    {
        plan tests => 1;
    }
    else
    {
        plan skip_all => "Cannot find the file '$logfile'";
    }
}

my $logbuf;
slurp($logfile, { buf_ref => \$logbuf });
ok($logbuf, "show '$logfile'") and diag($logbuf);
