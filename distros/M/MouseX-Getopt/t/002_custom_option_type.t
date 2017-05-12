#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

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

    MouseX::Getopt::OptionTypeMap->add_option_type_to_map(
        'ArrayOfInts' => '=i@'
    );

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

# Make sure it really used our =i@, instead of falling back
#  to =s@ via the type system, and test that exceptions work
#  while we're at it.
eval {
    local @ARGV = ('--nums', 3, '--nums', 'foo');

    my $app = App->new_with_options;
};
like($@, qr/Value "foo" invalid/, 'Numeric constraint enforced');
