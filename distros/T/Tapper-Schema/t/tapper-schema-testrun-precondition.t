use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;

use 5.010;

use Tapper::Config;
use Tapper::Schema;

use Data::Dumper;
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

use Test::More;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_preconditions2.yml' );
# --------------------------------------------------------------------------------


sub model
{
        my ($schema_basename) = @_;

        $schema_basename ||= 'TestrunDB';

        my $schema_class = "Tapper::Schema::$schema_basename";

        # lazy load class
        eval "use $schema_class";
        if ($@) {
                print STDERR $@;
                return undef;
        }
        return $schema_class->connect(Tapper::Config->subconfig->{database}{$schema_basename}{dsn},
                                      Tapper::Config->subconfig->{database}{$schema_basename}{username},
                                      Tapper::Config->subconfig->{database}{$schema_basename}{password});
}

ok(1);
my @preconditions;
my $testrun      = model->resultset('Testrun')->find(24);
my $precondition = model->resultset('Precondition')->new({
                                                          shortname => 'none',
                                                          precondition => 'precondition_type: none',
                                                         })->insert;
push @preconditions, $precondition->id;

$precondition = model->resultset('Precondition')->new({
                                                          shortname => 'none',
                                                          precondition => 'precondition_type: none',
                                                         })->insert;
push @preconditions, $precondition->id;
$testrun->insert_preconditions(2, @preconditions);
my @mappings = map { [$_->precondition_id, $_->succession] } model->resultset('TestrunPrecondition')->search({testrun_id => 24},
                                                                                                          {order_by => 'succession'})->all;
is_deeply(\@mappings, [
                       [  8, 1 ],
                       [ 12, 2 ],
                       [ 13, 3 ],
                       [  7, 4 ],
                       [  9, 5 ],
                       [ 10, 6 ],
                      ], 'Insert precondition');

done_testing();

