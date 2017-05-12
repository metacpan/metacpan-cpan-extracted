#! /usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_scheduling_run1.yml' );
# -----------------------------------------------------------------------------------------------------------------


my @modules = ('Tapper::Fake',
               'Tapper::Fake::Child',
               'Tapper::Fake::Master',
              );



plan tests => $#modules+1;

=pod

Using eval makes a bareword out of the $module string which is expected for
module handling. Some modules don't expect any parameter for new. They simply
ignore the 'testrun => 4'. Thus we don't need to separate both kinds of
modules.

=cut

foreach my $module(@modules) {
        my $obj;
        eval "require $module";
        $obj = eval "$module->new()";
        isa_ok($obj, $module);
        print $@ if $@;
}
