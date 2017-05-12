#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('MouseX::Getopt');
}

{
    package App;
    use Mouse;
    use Mouse::Util::TypeConstraints;

    use Scalar::Util 'looks_like_number';

    with 'MouseX::Getopt';

    subtype 'ArrayOfInts'
        => as 'ArrayRef'
        => where { scalar (grep { looks_like_number($_) } @$_)  };

    has 'nums' => (
        is      => 'ro',
        isa     => 'ArrayOfInts',
        default => sub { [0] }
    );

}

{
    local @ARGV = ();

    my $app = App->new_with_options;
    isa_ok($app, 'App');

    is_deeply($app->nums, [0], '... nums is [0] as expected');
}

{
    local @ARGV = ('--nums', 3, '--nums', 5);

    my $app = App->new_with_options;
    isa_ok($app, 'App');

    is_deeply($app->nums, [3, 5], '... nums is [3, 5] as expected');
}

