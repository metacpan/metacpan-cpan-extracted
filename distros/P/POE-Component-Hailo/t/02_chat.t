use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use POE qw(Component::Hailo);

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(_start hailo_learn_replied)],
    ],
);

POE::Kernel->run;

sub _start {
    POE::Component::Hailo->spawn(
        alias      => 'hailo',
        Hailo_args => {
            storage_class  => 'SQLite',
            brain_resource => ':memory:',
        },
    );

    POE::Kernel->post(hailo => learn_reply =>
        ['foo bar baz'],
        { a => 'b' },
    );
}

sub hailo_learn_replied {
    my ($result, $context) = @_[ARG0..ARG2];
    is_deeply($result, ['Foo bar baz.'], 'Result is correct');
    is_deeply($context, { a => 'b' }, 'Context is correct');
    POE::Kernel->post(hailo => 'shutdown');
}
