use Test2::V0 -target => 'Scientist';

use lib 't/lib';
use Named::Scientist;

subtest experiment => sub {
    is $CLASS->new->experiment, 'experiment', 'got default experiment name()';
};

subtest name => sub {
    is Scientist::name(), 'experiment', 'name() is set.';
};

subtest named_subclass => sub {
    my $experiment = Named::Scientist->new;
    is $experiment->experiment, 'joe', 'inherited experiment name()';
};

done_testing;
