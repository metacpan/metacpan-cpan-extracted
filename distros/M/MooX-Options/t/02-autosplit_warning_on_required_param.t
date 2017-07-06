#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("Data::Record"); use_module("Regexp::Common"); }
        or plan skip_all => "This test needs Data::Record and Regexp::Common";
}

{

    package t;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option 'treq' => (
        is            => 'ro',
        documentation => 'this is mandatory',
        format        => 's@',
        required      => 1,
        autosplit     => ",",
    );

    1;
}

{
    local @ARGV = ('--treq');
    trap { my $opt = t->new_with_options(); };
    like $trap->stderr,   qr/Option treq requires an argument/, 'stdout ok';
    unlike $trap->stderr, qr/Use of uninitialized/,             'stderr ok';
}

done_testing;

