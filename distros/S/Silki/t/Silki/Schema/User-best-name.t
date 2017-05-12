use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Silki::Test::FakeSchema;
use Silki::Schema::User;

{
    my $user = Silki::Schema::User->new(
        user_id      => 42,
        display_name => 'Foo Bar',
        _from_query  => 1,
    );

    is(
        $user->best_name(), 'Foo Bar',
        'best_name defaults to display_name'
    );
}

{
    my $user = Silki::Schema::User->new(
        user_id      => 42,
        display_name => q{},
        username     => 'bubba',
        _from_query  => 1,
    );

    is(
        $user->best_name(), 'bubba',
        'best_name falls back to username'
    );
}

{
    my $user = Silki::Schema::User->new(
        user_id      => 42,
        display_name => q{},
        username     => 'bubba@example.com',
        _from_query  => 1,
    );

    is(
        $user->best_name(), 'bubba',
        'best_name falls back to username, but strips email address domain'
    );
}

done_testing();
