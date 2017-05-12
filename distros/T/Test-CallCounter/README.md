# NAME

Test::CallCounter - Count the number of method calling

# SYNOPSIS

    use Test::CallCounter;

    my $counter = Test::CallCounter->new(
        'LWP::UserAgent' => 'get'
    );

    my $ua = LWP::UserAgent->new();
    $ua->get('http://d.hatena.ne.jp/');

    is($counter->count(), 1);

# DESCRIPTION

Test::CallCounter counts the number of method calling.

# METHODS

- my $counter = Test::CallCounter->new($class\_name, $method\_name)

    Make a instance of Test::CallCounter and hook `$method_name` method in `$class_name` to count calling method.

- $counter->count();

    Get a calling count of `$method_name`.

- $counter->reset()

    Reset counter.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

[Test::Mock::Guard](http://search.cpan.org/perldoc?Test::Mock::Guard)

If you want to do more complex operation while monkey patching, see also [Test::Resub](http://search.cpan.org/perldoc?Test::Resub).

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
