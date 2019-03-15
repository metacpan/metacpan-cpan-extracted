use strict;
use warnings;
use Test::AutoMock qw(mock manager);
use Test::More import => [qw(is note done_testing)];

# a black box function you want to test
sub get_metacpan {
    my $ua = shift;
    my $response = $ua->get('https://metacpan.org/');
    if ($response->is_success) {
        return $response->decoded_content;  # or whatever
    }
    else {
        die $response->status_line;
    }
}

# build and set up the mock
my $mock_ua = mock(
    methods => {
        # implement only the method you are interested in
        'get->decoded_content' => "Hello, metacpan!\n",
    },
);

# action first
my $body = get_metacpan($mock_ua);

# then, assertion
is $body, "Hello, metacpan!\n";
manager($mock_ua)->called_with_ok('get->is_success' => []);
manager($mock_ua)->not_called_ok('get->status_line');

# print all recorded calls
for (manager($mock_ua)->calls) {
    my ($method, $args) = @$_;
    note "$method(" . join(', ', @$args) . ")";
}

done_testing;
