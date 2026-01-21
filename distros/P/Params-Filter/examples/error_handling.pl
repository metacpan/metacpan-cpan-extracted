#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Error Handling Example: Filtering failures and how to handle them

say "=== Error Handling Patterns ===\n";

# Pattern 1: Check return value in scalar context
say "--- Pattern 1: Scalar Context Check ---\n";

sub create_user {
    my ($input) = @_;

    my $user = filter(
        $input,
        ['username', 'email'],    # required
        ['full_name'],
    );

    if ($user) {
        say "  User created successfully!";
        return $user;
    } else {
        say "  ERROR: Failed to create user - missing required fields";
        return undef;
    }
}

my $result1 = create_user({
    username => 'alice',
    email    => 'alice@example.com',
});
say "  Result: ", $result1 ? "Success" : "Failed";

say "\n";
my $result2 = create_user({
    username => 'bob',
    # email is missing!
});
say "  Result: ", $result2 ? "Success" : "Failed";

# Pattern 2: Check return value in list context
say "\n--- Pattern 2: List Context (Get Error Message) ---\n";

my ($data, $status) = filter(
    {
        name  => 'Charlie',
        # email missing!
        phone => '555-1234',
    },
    ['name', 'email'],
    ['phone'],
);

if ($data) {
    say "  Validation succeeded";
} else {
    say "  Validation failed!";
    say "  Error message: $status";
}

# Pattern 3: OO Interface with error handling
say "\n--- Pattern 3: OO Interface Error Handling ---\n";

my $filter = Params::Filter->new_filter({
    required => ['product_id', 'quantity'],
    accepted => ['price', 'description'],
});

my @orders = (
    { product_id => 1, quantity => 5, price => 9.99 },
    { product_id => 2, quantity => 3 },  # Valid (minimal)
    { quantity => 10 },                  # Invalid: missing product_id
    { product_id => 3, price => 19.99 }, # Invalid: missing quantity
);

for my $order (@orders) {
    my ($filtered, $msg) = $filter->apply($order);

    if ($filtered) {
        my $fields = join ', ', sort keys $filtered->%*;
        say "  ✓ Order valid: $fields";
    } else {
        say "  ✗ Order rejected: $msg";
    }
}

# Pattern 4: Early return pattern
say "\n--- Pattern 4: Early Return on Filtering Failure ---\n";

sub process_payment {
    my ($input) = @_;

    my ($payment, $status) = filter(
        $input,
        ['amount', 'currency', 'card_number'],
        ['card_holder', 'expiry'],
    );

    # Early return if validation fails
    return (0, "Payment validation failed: $status") unless $payment;

    # Process payment...
    say "  Processing payment: $payment->{amount} $payment->{currency}";

    return (1, "Payment processed successfully");
}

my ($success, $message) = process_payment({
    amount      => 100,
    currency    => 'USD',
    card_number => '4111-1111-1111-1111',
});
say "  Result: $message\n";

my ($success2, $message2) = process_payment({
    amount   => 50,
    # currency missing!
    card_number => '4222-2222-2222-2222',
});
say "  Result: $message2";

# Pattern 5: Collecting multiple filtering errors
say "\n--- Pattern 5: Batch Filtering ---\n";

my $batch_filter = Params::Filter->new_filter({
    required => ['id', 'type'],
    accepted => ['name', 'value'],
});

my @batch_data = (
    { id => 1, type => 'A', name => 'First' },
    { id => 2 },                       # Missing type
    { type => 'B' },                   # Missing id
    { id => 3, type => 'C', extra => 'data' },  # Valid (extra ignored)
);

my (@valid, @invalid);

for my $item (@batch_data) {
    my ($filtered, $msg) = $batch_filter->apply($item);

    if ($filtered) {
        push @valid, $filtered;
    } else {
        push @invalid, { input => $item, error => $msg };
    }
}

say "  Valid items: " . scalar(@valid);
say "  Invalid items: " . scalar(@invalid);
for my $inv (@invalid) {
    my $input_str = join ', ', %{$inv->{input}};
    say "    - $input_str";
    say "      Error: $inv->{error}";
}
