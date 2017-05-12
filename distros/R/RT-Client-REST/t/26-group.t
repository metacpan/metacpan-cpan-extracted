use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form',
    'rt_type', 'id',
    
    # attributes:
    'name', 'description', 'members'
);

BEGIN {
    use_ok('RT::Client::REST::Group');
}

my $user;

lives_ok {
    $user = RT::Client::REST::Group->new;
} 'User can get successfully created';

for my $method (METHODS) {
    can_ok($user, $method);
}

ok('group' eq $user->rt_type, 'rt_type is ok');

# vim:ft=perl:
