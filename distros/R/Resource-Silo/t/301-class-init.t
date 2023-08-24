#!/usr/bin/env perl

=head1 DESCRIPTION

Bread::Board-like class-based initializer.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Basename qw(dirname);

use lib dirname(__FILE__)."/tlib";

use Resource::Silo;

resource life  => sub { 42 };
resource square =>
    argument        => qr(\d+),
    init            => sub { $_[2] * $_[2] };

resource class  =>
    class           => 'My::Class',
    dependencies    => { foo => ['life'], bar => ['square', 9] };

resource literal =>
    class           => 'My::Class',
    dependencies    => { life => 1, fine => \137 };

subtest 'happy path' => sub {
    my $container = silo->new;

    is $INC{'My/Class.pm'}, undef, "module not loaded";

    my $item = $container->class;

    is $INC{'My/Class.pm'}, dirname(__FILE__)."/tlib/My/Class.pm", "module loaded now";
    is ref $item, 'My::Class', "value of expected class returned";
    is $item->{foo}, 42, "constant dependency present";
    is $item->{bar}, 81, "parametrized dependency present";
};

subtest 'pass literal value' => sub {
    my $container = silo->new;
    my $item = $container->literal;
    is $item->{life}, 42, "abbreviated dependency works";
    is $item->{fine}, 137, "literal value in dependency works";
};

done_testing;

