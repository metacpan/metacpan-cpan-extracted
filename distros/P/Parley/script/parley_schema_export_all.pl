#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Parley::Schema;
use Parley;

use Getopt::Long;
my %cli=();
GetOptions(\%cli, 'to=s');

if (not defined $cli{to}) {
    $cli{to} = Parley->VERSION();
}

my $schema = Parley::Schema->connect;

$schema->create_ddl_dir(
    ['PostgreSQL', 'MySQL', 'SQLite'],
    $cli{to},
    'db_script',
);

