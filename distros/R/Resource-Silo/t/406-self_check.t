#!/usr/bin/env perl

=head1 DESCRIPTION

Try to validate impossible setups.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

subtest 'no problem' => sub {
    lives_ok {
        package All::Good;
        use Resource::Silo -class;

        resource foo    =>
            loose_deps      => 1,
            require         => [ 'Test::More' ],
            dependencies    => [ 'bar' ],
            init            => sub { 42 };

        resource bar    =>
            init            => sub {};
    } "defining a valid setup works";

    lives_ok {
        All::Good->new->ctl->meta->self_check;
    } "setup was actually good";
};

subtest 'bad dependencies' => sub {
    lives_ok {
        package Bad::Deps;
        use Resource::Silo -class;

        resource foo    =>
            loose_deps      => 1,
            dependencies    => ['bar'],
            init            => sub {};
    } "defining invalid setup is ok";

    throws_ok {
        Bad::Deps->new->ctl->meta->self_check;
    } qr(resource 'foo': .*depend.*'bar'), "imcomplete dependencies = no go";

    throws_ok {
        Bad::Deps->new->ctl->preload;
    } qr(resource 'foo': .*depend.*'bar'), "ditto with preload";
};

subtest 'unloadable modules' => sub {
    local @INC; # can't load any modules now
    lives_ok {
        package Bad::Mods;
        use Resource::Silo -class;

        resource foo    =>
            require         => ['My::Module'],
            init            => sub {};
    } "defining invalid setup is ok";

    throws_ok {
        Bad::Mods->new->ctl->meta->self_check;
    } qr(resource 'foo': .*load.* 'My::Module'), "can't load modules = no go";

    throws_ok {
        Bad::Mods->new->foo;
    } qr(resource 'foo': .*load.* 'My::Module')
        , "can't load modules in runtime = also no go";
};

done_testing;
