build_requires 'Test::More';
build_requires 'Test::Requires';

requires 'parent';
requires 'Net::IP::Minimal';
requires 'Term::ANSIColor';

on 'test' => sub {
    requires 'Capture::Tiny';
    requires 'Test::SharedFork';
    requires 'Test::Fatal';
};
