#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $precond_id = `$^X -Ilib bin/tapper precondition-new --condition="precondition_type: image\nname: suse.tgz"`;
chomp $precond_id;
my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
like($precond->precondition, qr"precondition_type: image", 'inserted precond / yaml');

# --------------------------------------------------

my $old_precond_id = $precond_id;
$precond_id = `$^X -Ilib bin/tapper precondition-update --id=$old_precond_id --shortname="foobar-perl-5.11" --condition="precondition_type: file\nname: some_file"`;
chomp $precond_id;

$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond->id, $old_precond_id, 'update precond / id');
is($precond->shortname, 'foobar-perl-5.11', 'update precond / shortname');
like($precond->precondition, qr'precondition_type: file', 'update precond / yaml');

my @retval = `$^X -Ilib bin/tapper precondition-list`;
chomp @retval;
is_deeply(\@retval, [103, 102, 101, 11, 10, 9, 8, 7, 6, 5], 'List preconditions / all, short');

my $retval = `$^X -Ilib bin/tapper precondition-list --id=5 -v`;
like($retval, qr/\s+?Id: 5\s+Shortname: temare_producer\s+Precondition: ---\nprecondition_type: produce\nproducer: Temare\nsubject: KVM\nbitness: 64\n | NULL | \n/, 'List preconditions / id, long');

@retval = `$^X -Ilib bin/tapper precondition-list --testrun=3002`;
chomp @retval;
is_deeply(\@retval, [8, 5], 'List preconditions / per testrun, short');

@retval = `$^X -Ilib bin/tapper precondition-update --shortname="foobar-perl-5.11" --condition="precondition_type: file\nname: some_file" 2>&1`;
chomp @retval;
is($retval[0], q#error: Missing required parameter 'id'#, 'Update precondition / id');

`$^X -Ilib bin/tapper precondition-delete --id=$precond_id --force`;
$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond, undef, "delete precond");


done_testing();
