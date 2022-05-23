#!/usr/bin/env perl

use Test::Most;
use Capture::Tiny 'capture_stderr';
use lib 'lib';

{
    use MooseX::Role::WarnOnConflict ();

    package My::Role::Example;
    use MooseX::Meta::Role::WarnOnConflict;
    use Moose::Role -metaclass => 'MooseX::Meta::Role::WarnOnConflict';

    sub munge { 'munge role' }
}

isa_ok +My::Role::Example->meta, 'MooseX::Meta::Role::WarnOnConflict';

my $stderr = capture_stderr {
    eval <<'END_EVAL';
    package Foo;
    use Moose;
    with 'My::Role::Example';
    sub munge { 'munge foo' }
END_EVAL
};
like $stderr, qr/\QThe class Foo has implicitly overridden the method (munge)/,
  'Implicitly overridding methods should be fatal';

$stderr = capture_stderr {
    eval <<'END_EVAL';
    package Bar;
    use Moose;
    with 'My::Role::Example' => { -alias => { munge => 'another_name' }, -excludes => ['munge'] };
    sub munge { 'munge bar' }
    sub another_name {}
END_EVAL
};

like $stderr, qr/Bar should not alias My::Role::Example 'munge' to 'another_name' if a local method of the same name exists/,
  '... aliasing to an existing name should warn';

$stderr = capture_stderr {
    eval <<'END_EVAL';
    package Baz;
    use Moose;
    with 'My::Role::Example' => { -excludes => ['munge'] };
    sub munge { 'munge bar' }
END_EVAL
};

ok !$stderr,
  '... but explicitly exluding the conflicting errors should be fine';
is Baz->munge, 'munge bar', '... and the correct method should be available';

done_testing;
