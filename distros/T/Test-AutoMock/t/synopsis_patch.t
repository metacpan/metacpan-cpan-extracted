use strict;
use warnings;
use Test::AutoMock qw(manager);
use Test::AutoMock::Patch qw(patch_sub);
use Test::More import => [qw(is done_testing)];

# a black box function you want to test
sub get_metacpan {
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get('https://metacpan.org/');
    if ($response->is_success) {
        return $response->decoded_content;  # or whatever
    }
    else {
        die $response->status_line;
    }
}

# apply a monkey patch to LWP::UserAgent::new
patch_sub {
    my $mock = shift;

    # set up the mock
    manager($mock)->add_method('get->decoded_content' => "Hello, metacpan!\n");

    # call blackbox function
    my $body = get_metacpan();

    # assertions
    is $body, "Hello, metacpan!\n";
    manager($mock)->called_with_ok('get->is_success' => []);
    manager($mock)->not_called_ok('get->status_line');
} 'LWP::UserAgent::new';

done_testing;
