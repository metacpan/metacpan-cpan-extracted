[![Build Status](https://circleci.com/gh/hiratara/p5-Test-AutoMock.svg)](https://circleci.com/gh/hiratara/p5-Test-AutoMock)
# NAME

Test::AutoMock - A mock that can be used with a minimum setup

# SYNOPSIS

    use Test::AutoMock qw(mock manager);
    use Test::More import => [qw(is note done_testing)];

    # a black box function you want to test
    sub get_metacpan {
        my $ua = shift;
        my $response = $ua->get('https://metacpan.org/');
        if ($response->is_success) {
            return $response->decoded_content;  # or whatever
        }
        else {
            die $response->status_line;
        }
    }

    # build and set up the mock
    my $mock_ua = mock(
        methods => {
            # implement only the method you are interested in
            'get->decoded_content' => "Hello, metacpan!\n",
        },
    );

    # action first
    my $body = get_metacpan($mock_ua);

    # then, assertion
    is $body, "Hello, metacpan!\n";
    manager($mock_ua)->called_with_ok('get->is_success' => []);
    manager($mock_ua)->not_called_ok('get->status_line');

    # print all recorded calls
    for (manager($mock_ua)->calls) {
        my ($method, $args) = @$_;
        note "$method(" . join(', ', @$args) . ")";
    }

# DESCRIPTION

Test::AutoMock is a mock module designed to be used with a minimal setup.
AutoMock can respond to any method call and returns a new AutoMock instance
as a return value. Therefore, you can use it as a mock object without having
to define all the methods. Even if method calls are nested, there is no
problem.

AutoMock records all method calls on all descendants. You can verify the method
calls and its arguments after using the mock. This is not the "record and
replay" model but the "action and assertion" model.

You can also mock many overloaded operators and hashes, arrays with
[Test::AutoMock::Mock::Overloaded](https://metacpan.org/pod/Test::AutoMock::Mock::Overloaded). If you want to apply monkey patch to use
AutoMock, check [Test::AutoMock::Patch](https://metacpan.org/pod/Test::AutoMock::Patch).

Test::AutoMock is inspired by Python3's unittest.mock module.

# ALPHA WARNING

This module is under development. The API, including names of classes and
methods, may be subject to BACKWARD INCOMPATIBLE CHANGES.

# FUNCTIONS

## `mock`

    my $mock = mock(
        methods => {
            agent => 'libwww-perl/AutoMock',
            'get->is_success' => sub { 1 },
        },
        isa => 'LWP::UserAgent',
    );

Create [Test::AutoMock::Mock::Basic](https://metacpan.org/pod/Test::AutoMock::Mock::Basic) instance. It takes the following
parameters.

- `methods`

    A hash-ref of method definitions. See [Test::AutoMock::Manager::add\_method](https://metacpan.org/pod/Test::AutoMock::Manager::add_method).

- `isa`

    A super class of this mock. See [Test::AutoMock::Manager::isa](https://metacpan.org/pod/Test::AutoMock::Manager::isa).
    To specify multiple classes, use array-ref.

## `mock_overloaded`

It is the same as the mock method except that the generated instance is
[Test::AutoMock::Mock::Overloaded](https://metacpan.org/pod/Test::AutoMock::Mock::Overloaded).

## `manager`

Access the [Test::AutoMock::Manager](https://metacpan.org/pod/Test::AutoMock::Manager) of the mock instance. You can set up and
verify the mock with the Manager object. See [Test::AutoMock::Manager](https://metacpan.org/pod/Test::AutoMock::Manager)
for details.

All [Test::AutoMock::Mock::Basic](https://metacpan.org/pod/Test::AutoMock::Mock::Basic) and [Test::AutoMock::Mock::Overloaded](https://metacpan.org/pod/Test::AutoMock::Mock::Overloaded)
instances have the Manager class. The manager and the mock correspond one to
one. In fact, `manager($mock)->mock == $mock` and
`manager($manager->mock) == $manager` hold.

# SEE ALSO

- [Test::AutoMock::Manager](https://metacpan.org/pod/Test::AutoMock::Manager)
- [Test::MockObject](https://metacpan.org/pod/Test::MockObject)
- [Test::Double](https://metacpan.org/pod/Test::Double)
- [Test::Stub](https://metacpan.org/pod/Test::Stub)
- [Test::Mocha](https://metacpan.org/pod/Test::Mocha)

# LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Honma <hiratara@cpan.org>
