use strict;
use Test::More;

use DateTime;
use Software::Release;
use Software::Release::Change;

my $change = Software::Release::Change->new(
    author_name => 'gphat',
    author_email => 'gphat@cpan.org',
    change_id => 'abc1234',
    date => DateTime->now,
    description => 'Frozzle the wozjob'
);

my $rel = Software::Release->new(
    version => '0.1',
    name => 'Angry Anteater',
    date => DateTime->now,
);

$rel->add_to_changes($change);

cmp_ok(scalar(@{ $rel->changes }), '==', 1, '1 change');

done_testing;