#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

use Module::ExtractUse;


# The original problem code
{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
BEGIN {
    # Only use Apache::DBI on dev.
    if (-f '/var/run/httpd-dev01') {
        # Must be loaded before DBI.
        require Apache::DBI;
        Apache::DBI->import();
    }
}
CODE
}



{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
# require Apache::DBI
require Apache::DBI
CODE
}


{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '';
# require Apache::DBI
# require Apache::DBI
CODE
}


{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
# foo
require Apache::DBI
CODE
}


{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
# use some Apache::DBI, yo
require Apache::DBI
CODE
}

{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
# require Apache::DBI
use Apache::DBI
CODE
}

{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, 'Apache::DBI';
# yo, require Apache::DBI
require Apache::DBI
CODE
}

# Handle trailing comments which become comment lines after the split on
# ';'.
{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '5.008 strict warnings';
use 5.008; # Because we want to
# Another comment

use strict;
use warnings;
CODE
}
