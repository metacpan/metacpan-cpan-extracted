requires 'Class::Accessor::Lite';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'parent';
requires 'perl', '5.008005';

feature 'as_anyevent_child', 'support AnyEvent->child feature.' => sub {
    requires 'AnyEvent';
};

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Requires';
    requires 'Test::SharedFork';
    requires 'IO::Pipe';
};
