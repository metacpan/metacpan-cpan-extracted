#! /usr/bin/env perl

use lib '.';

use strict;
use warnings;

use Test::More;
use Tapper::Model qw(model get_hardware_overview);
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Data::DPath qw(dpath);
use Data::Dumper;

plan tests => 3;

# --------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# --------------------------------------------------

is( model('TestrunDB')->resultset('Precondition')->count, 5, "version count" );

my $content = get_hardware_overview(7);
# print STDERR Dumper($content);
is_deeply($content, {
                     'keyword' => 'server',
                     'mem' => '4096',
                     'cores' => '2',
                     'vendor' => 'AMD'
                    },
          'Hardware overview of host dickstone');

Tapper::Model::get_or_create_owner('does_not_exist');
is( model('TestrunDB')->resultset('Owner')->search({login => 'does_not_exist'})->count, 1, "Created new owner" );
