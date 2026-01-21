#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Arrayref Input Example: Using array references instead of hash references
# Useful for command-line arguments or list-based data

say "=== Arrayref Input Formats ===\n";

say "--- Format 1: Even-Element Array (Key-Value Pairs) ---\n";

my ($result1, $msg1) = filter(
    [
        'username', 'alice',
        'email',    'alice@example.com',
        'phone',    '555-1234',
        'city',     'San Francisco',
    ],
    ['username', 'email'],
    ['phone', 'city'],
);

say "Even-element arrayref:";
say "  $_: $result1->{$_}" for sort keys $result1->%*;
say "  Status: $msg1\n";

say "--- Format 2: Odd-Element Array (Becomes Flag) ---\n";

my ($result2, $msg2) = filter(
    [
        'command', 'deploy',
        'env',     'production',
        'verbose',  # No value - becomes flag => 1
    ],
    ['command', 'env'],
    ['verbose'],
    [], 1,  # Debug ON to see warning
);

say "Odd-element arrayref (verbose becomes flag):";
say "  $_: $result2->{$_}" for sort keys $result2->%*;
say "  Status: $msg2\n";

say "--- Format 3: Arrayref Containing Hashref ---\n";

my ($result3, $msg3) = filter(
    [
        {
            name  => 'Charlie',
            email => 'charlie@example.com',
            age   => 30,
        }
    ],
    ['name', 'email'],
    ['age'],
);

say "Arrayref containing single hashref:";
say "  $_: $result3->{$_}" for sort keys $result3->%*;
say "  Status: $msg3\n";

say "--- Format 4: Command-Line Style Arguments ---\n";

# Simulating command-line arguments: @ARGV
my @argv = ('user', 'bob', 'action', 'create', 'force');

my ($result4, $msg4) = filter(
    \@argv,
    ['user', 'action'],
    ['force'],
    [], 1,
);

say "Command-line style array:";
say "  $_: $result4->{$_}" for sort keys $result4->%*;
say "  Status: $msg4\n";

say "--- Format 5: Mixed Data Types in Array ---\n";

my ($result5, $msg5) = filter(
    [
        'product_id', 123,        # String key, numeric value
        'price',      29.99,      # Float value
        'in_stock',   1,          # Boolean/integer
        'active',                  # Odd element - becomes flag
    ],
    ['product_id'],
    ['price', 'in_stock', 'active'],
    [], 1,
);

say "Mixed data types:";
say "  $_: $result5->{$_}" for sort keys $result5->%*;
say "  Status: $msg5\n";

say "--- Format 6: Array vs Hash Comparison ---\n";

my $hash_input = {
    name  => 'Diana',
    email => 'diana@example.com',
};

my $array_input = ['name', 'Diana', 'email', 'diana@example.com'];

my ($hash_result, $hash_msg) = filter($hash_input, ['name'], ['email']);
my ($array_result, $array_msg) = filter($array_input, ['name'], ['email']);

say "Hashref input:";
say "  $_: $hash_result->{$_}" for sort keys $hash_result->%*;

say "\nArrayref input (equivalent):";
say "  $_: $array_result->{$_}" for sort keys $array_result->%*;

say "\nBoth produce same result: ",
    (join('', sort keys $hash_result->%*) eq join('', sort keys $array_result->%*))
    ? "Yes" : "No";
say "";

say "--- Format 7: Empty or Minimal Arrays ---\n";

my ($result6, $msg6) = filter(
    [],  # Empty array
    ['required'],
);
say "Empty array:";
say "  Result: " . ($result6 // "undef");
say "  Status: $msg6\n";

my ($result7, $msg7) = filter(
    ['only_one'],  # Single element
    [],
    ['_'],
);
say "Single-element array:";
say "  $_: $result7->{$_}" for sort keys $result7->%*;
say "  Status: $msg7\n";

say "--- Format 8: OO Interface with Arrayrefs ---\n";

my $array_filter = Params::Filter->new_filter({
    required => ['id', 'type'],
    accepted  => ['name', 'value', 'enabled'],
});

my @datasets = (
    ['id', 1, 'type', 'A', 'name', 'First'],
    ['id', 2, 'type', 'B', 'name', 'Second', 'enabled'],  # Odd!
    ['id', 3, 'type', 'C'],  # Minimal
);

for my $dataset (@datasets) {
    my ($result, $status) = $array_filter->apply($dataset);
    say "Dataset: " . join(', ', @$dataset);
    say "  Result: " . join(', ', map { "$_=$result->{$_}" } sort keys $result->%*);
    say "  Status: $status\n";
}
