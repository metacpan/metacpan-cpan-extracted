#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use lib "$Bin/lib";

use Test::More;

eval { require YAML::Syck };

if($@)
{
  eval { require YAML };

  plan(skip_all => 'YAML or YAML::Syck required for setup tests')  if($@); 
}

Test::More->import(tests => 4);

$ENV{'ROSEDBRC'}       = "$Bin/rosedbrc";
$ENV{'ROSEDB_DEVINIT'} = rand > 0.5 ? 'My::FixUp' : "$Bin/lib/My/FixUp.pm";

use_ok('My::DB');

my $entry = My::DB->registry->entry(domain => 'somedomain', type => 'sometype');

is($entry->database, 'somevalue', 'ROSEDBRC 1');

$entry = My::DB->registry->entry(domain => 'otherdomain', type => 'othertype');

is($entry->host, 'othervalue', 'ROSEDBRC 2');

if($ENV{'ROSEDB_DEVINIT'} eq 'My::FixUp')
{
  is($entry->port, '456', 'ROSEDB_DEVINIT 1');
}
else
{
  is($entry->port, '789', 'ROSEDB_DEVINIT 1');
}
