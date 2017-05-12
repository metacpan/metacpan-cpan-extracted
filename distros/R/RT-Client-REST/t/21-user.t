use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form',
    'rt_type', 'id',
    
    # attributes:
    'name', 'password', 'real_name', 'gecos',
    'privileged', 'email_address',  'comments', 'organization',
    'address_one', 'address_two', 'city', 'state', 'zip', 'country',
    'home_phone', 'work_phone', 'cell_phone', 'pager', 'disabled',
    'nickname', 'lang', 'contactinfo', 'signature'
);

BEGIN {
    use_ok('RT::Client::REST::User');
}

my $user;

lives_ok {
    $user = RT::Client::REST::User->new;
} 'User can get successfully created';

for my $method (METHODS) {
    can_ok($user, $method);
}

ok('user' eq $user->rt_type);

done_testing;

# vim:ft=perl:
