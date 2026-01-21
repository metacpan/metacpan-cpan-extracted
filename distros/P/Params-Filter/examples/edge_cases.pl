#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Edge Cases Example: Unusual input formats and boundary conditions

say "=== Edge Cases: Unusual Input Formats ===\n";

say "--- Case 1: Odd-Numbered Array (Intentional Flag) ---\n";

my ($result1, $msg1) = filter(
    ['config', 'production', 'debug', 'verbose'],  # 4 elements - even, OK
    ['config'],
    ['debug', 'verbose'],
);

say "Even array (4 elements):";
say "  $_: $result1->{$_}" for sort keys $result1->%*;
say "  Status: $msg1\n";

my ($result2, $msg2) = filter(
    ['config', 'production', 'verbose'],  # 3 elements - odd!
    ['config'],
    ['verbose'],
    [], 1,  # DEBUG ON to see warning
);

say "Odd array (3 elements):";
say "  $_: $result2->{$_}" for sort keys $result2->%*;
say "  Status: $msg2\n";

say "--- Case 2: Single-Element Array ---\n";

my ($result3, $msg3) = filter(
    ['just_one_thing'],  # Single element
    [],
    ['_'],  # Accept the special '_' key
);

say "Single element array:";
say "  $_: $result3->{$_}" for sort keys $result3->%*;
say "  Status: $msg3\n";

say "--- Case 3: Plain Scalar Input ---\n";

my ($result4, $msg4) = filter(
    'plain text value',  # Not a reference!
    [],
    ['_'],
    [], 1,  # DEBUG ON
);

say "Scalar input:";
say "  $_: $result4->{$_}" for sort keys $result4->%*;
say "  Status: $msg4\n";

say "--- Case 4: Long Scalar (Truncation) ---\n";

my $long_string = 'x' x 100;  # 100 characters
my ($result5, $msg5) = filter(
    $long_string,
    [],
    ['_'],
    [], 1,  # DEBUG ON
);

say "Long scalar input (truncated in warning):";
say "  Result: _ => " . substr($result5->{_}, 0, 20) . "...";
say "  Status: $msg5\n";

say "--- Case 5: Empty Hashref ---\n";

my ($result6, $msg6) = filter(
    {},  # Empty!
    ['required_field'],  # But we require something
);

say "Empty hashref with required fields:";
say "  Result: " . ($result6 // "undef");
say "  Status: $msg6\n";

say "--- Case 6: Empty Arrayref ---\n";

my ($result7, $msg7) = filter(
    [],  # Empty!
    ['required_field'],
);

say "Empty arrayref with required fields:";
say "  Result: " . ($result7 // "undef");
say "  Status: $msg7\n";

say "--- Case 7: Arrayref with Single Hashref ---\n";

my ($result8, $msg8) = filter(
    [{name => 'Alice', age => 30}],  # Array containing one hashref
    ['name'],
    ['age'],
);

say "Arrayref containing single hashref:";
say "  $_: $result8->{$_}" for sort keys $result8->%*;
say "  Status: $msg8\n";

say "--- Case 8: Arrayref with Even Elements ---\n";

my ($result9, $msg9) = filter(
    ['key1', 'value1', 'key2', 'value2'],  # 4 elements (even)
    ['key1'],
    ['key2'],
);

say "Even-element arrayref:";
say "  $_: $result9->{$_}" for sort keys $result9->%*;
say "  Status: $msg9\n";

say "--- Case 9: Only Required Fields (No Accepted) ---\n";

my ($result10, $msg10) = filter(
    {
        user_id => 123,
        name    => 'Test User',
        extra   => 'ignored',
    },
    ['user_id'],  # Only required, no accepted list
);

say "Only required fields (extras ignored):";
say "  $_: $result10->{$_}" for sort keys $result10->%*;
say "  Status: $msg10\n";

say "--- Case 10: Empty Required/Accepted/Excluded ---\n";

my ($result11, $msg11) = filter(
    {
        anything => 'goes',
        every   => 'field',
        accepted => 'here',
    },
    [],  # No required fields
    ['*'],  # Accept everything (wildcard)
    [],  # Nothing excluded
);

say "Wildcard accepts everything:";
say "  $_: $result11->{$_}" for sort keys $result11->%*;
say "  Status: $msg11\n";

say "--- Case 11: Undefined Values ---\n";

my ($result12, $msg12) = filter(
    {
        name      => 'Bob',
        email     => undef,  # Explicitly undefined
        phone     => '555-1234',
    },
    ['name'],
    ['email', 'phone'],
);

say "Fields with undef values:";
say "  $_: " . ($result12->{$_} // 'undef') for sort keys $result12->%*;
say "  Status: $msg12\n";

say "--- Case 12: OO Interface with Edge Cases ---\n";

my $filter = Params::Filter->new_filter({
    required => ['id'],
    accepted  => ['*'],  # Wildcard
    excluded  => ['secret'],
    debug     => 1,
});

my ($result13, $msg13) = $filter->apply(
    ['id', 999, 'flag']  # Odd array with OO interface
);

say "OO interface with odd array:";
say "  $_: $result13->{$_}" for sort keys $result13->%*;
say "  Status: $msg13";
