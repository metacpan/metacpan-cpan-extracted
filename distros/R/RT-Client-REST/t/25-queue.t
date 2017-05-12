use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form', 'rt_type', 'tickets',
    
    # attrubutes:
    'id', 'name', 'description', 'correspond_address', 'comment_address',
    'initial_priority', 'final_priority', 'default_due_in',
);

BEGIN {
    use_ok('RT::Client::REST::Queue');
}

my $user;

lives_ok {
    $user = RT::Client::REST::Queue->new;
} 'Queue can get successfully created';

for my $method (METHODS) {
    can_ok($user, $method);
}

ok('queue' eq $user->rt_type);

# vim:ft=perl:
