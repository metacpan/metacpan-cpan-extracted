#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# DESCRIPTION
#
# After a fresh installation, there are three default forums in the database,
# but not yet any posts.
# Due to the current join types there are no forums listed/returned on the
# forum/list page.
#
# SOLUTION
#
# The solution appears to be to use LEFT JOINs all the way from
# forum --> post (last_post) --> person (creator) --> authentication
#
# EXTRA WORK
#
# sub list() in Controller::Forum does its own ->search() instead of calling
# out to the model.
# Before this bug can be fixed/tested we need to move the search call out to
# the model, and then call a model method in the controller

use Test::More tests => 5;

BEGIN { use_ok 'Parley::Schema' }

my ($schema, $resultset, $rs);

# get a schema to query
$schema = Parley::Schema->connect(
    'dbi:Pg:dbname=parley'
);
isa_ok($schema, 'Parley::Schema');

# grab the Post resultset
$resultset = $schema->resultset('Forum');
isa_ok($resultset, 'Parley::ResultSet::Forum');

# make sure we can call the forum_list method on the resultset
can_ok(
    $resultset,
    qw( forum_list )
);


# because we need to test the behaviour when there are no "last_post"s
# we run the bulk of the tests in a txn so we can clear data, run tests, and
# rollback to where we were at the start
eval {
    $schema->txn_do(
        sub {
            _forum_list_test(
                $schema
            );
        }
    );
};
if ($@) {
    die $@;
}

sub _forum_list_test {
    my $schema = shift;
    my $resultset = $schema->resultset('Forum');
    my ($no_join_count, $list_count);

    # clear last_post references
    $resultset->update(
        {
            last_post_id => undef,
        }
    );

    # count the number of forums, no joins followed
    $no_join_count = $resultset->count();

    # count the number of forums, calling the method with the joins
    $list_count = $resultset->forum_list->count();

    # the two should match
    is($list_count, $no_join_count, q{correct numer of forums returned});


    
    # make sure our changes don't land in the database
    $schema->txn_rollback;
}


1;
