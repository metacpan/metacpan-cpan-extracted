use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use FindBin::libs;

use Pivot::ArrayOfHashes qw{pivot};

# Suppose you have some result from DBI::selectall_arrayref(..., { Slice => {} });
my @rows = (
    { name => 'fred',  'lname' => 'flintstone', 'events' => 'Chase, Hugs',         date => '2025-01-01' },
    { name => 'fred',  'lname' => 'flintstone', 'events' => 'Chase, Tickle, Hugs', date => '2025-01-02' },
    { name => 'fred',  'lname' => 'flintstone', 'events' => 'Tickle',              date => '2025-01-03' },
    { name => 'wilma', 'lname' => 'flintstone', 'events' => 'Chase, Tickle, Hugs', date => '2025-01-01' },
    { name => 'wilma', 'lname' => 'flintstone', 'events' => 'Tickle',              date => '2025-01-02' },
    { name => 'fred',  'lname' => 'rubble',     'events' => 'Chase, Hugs',         date => '2025-01-01' },
);

# I want events by date, and to group by each of the other cols.
# In short, "what is everyone on what date".
my %options = (
    pivot_on   => 'events',
    pivot_into => 'date',
);

# Using our function!
my @pivoted = pivot(\@rows, %options);

# Returns an array like so:
my $r = [
    {
        'name'       => 'fred',
        'lname'      => 'flintstone',
        '2025-01-01' => 'Chase, Hugs',
        '2025-01-02' => 'Chase, Tickle, Hugs',
        '2025-01-03' => 'Tickle',
        },
        {
        'name'       => 'wilma',
        'lname'      => 'flintstone',
        '2025-01-01' => 'Chase, Tickle, Hugs',
        '2025-01-02' => 'Tickle',
        '2025-01-03' => undef,
        },
        {
        'name'       => 'fred',
        'lname'      => 'rubble',
        '2025-01-01' => 'Chase, Hugs',
        '2025-01-02' => undef,
        '2025-01-03' => undef,
    },
];

is_deeply(\@pivoted, $r, "Pivoted data as expected");
