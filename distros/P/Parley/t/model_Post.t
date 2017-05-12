use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok 'Parley::Schema' }

my ($schema, $resultset, $rs);

# get a schema to query
$schema = Parley::Schema->connect(
    'dbi:Pg:dbname=parley'
);
isa_ok($schema, 'Parley::Schema');

# grab the Post resultset
$resultset = $schema->resultset('Post');
isa_ok($resultset, 'Parley::ResultSet::Post');

# test the "who posted from XXX ip" resultset method
$rs = $resultset->people_posting_from_ip('127.0.0.1');
isa_ok($rs, 'Parley::ResultSet::Post');

# insert some posts, in a txn, so we can roll them back and not pollute the
# database
eval {
    $schema->txn_do(
        sub {
            _ip_posting_test(
                $schema
            );
        }
    );
};
if ($@) {
    die $@;
}

sub _ip_posting_test {
    my $schema = shift;
    my $resultset = $schema->resultset('Post');

    my $fake_ip = q{10.231.123.111};

    # create a thread for fake posts
    my $thread = $schema->resultset('Thread')->create(
        {
            forum_id    => 0,
            subject     => $fake_ip,
            creator_id  => 0,
        }
    );

    # create a fake post for a couple of users
    for my $person_id (qw/0 0 0 1 1/) {
        $resultset->create(
            {
                thread_id   => $thread->id,
                subject     => $fake_ip,
                message     => $fake_ip,
                creator_id  => $person_id,
                ip_addr     => $fake_ip,
            }
        );
    }

    # there should be 5 posts from $fake_ip
    my $count = $resultset->count(
        {
            ip_addr     => $fake_ip,
        }
    );
    is($count, 5, qq{correct number of posts from $fake_ip});

    # test the resultset method ..
    my $rs = $resultset->people_posting_from_ip($fake_ip);
    isa_ok($rs, 'Parley::ResultSet::Post');
    is($rs->count, 2, qq{correct number of people posting from $fake_ip});

    # make sure our changes don't land in the database
    $schema->txn_rollback;
}
