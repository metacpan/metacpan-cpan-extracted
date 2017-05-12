# NAME

Promise::Tiny - A promise implementation written in Perl

# SYNOPSIS

    use Promise::Tiny;

    my $promise = Promise::Tiny->new(sub {
        my ($resolve, $reject) = @_;
        some_async_process(..., sub { # callback.
            ...
            if ($error) {
                $reject->($error);
            } else {
                $resolve->('success value');
            }
        });
    })->then(sub {
        my ($value) = @_;
        print $value # -> success value
    }, sub {
        my ($error) = @_;
        # handle error
    });

# DESCRIPTION

Promise::Tiny is tiny promise implementation.
Promise::Tiny has same interfaces as ES6 Promise.

# LICENSE

Copyright (C) hatz48.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hatz48 <hatz48@hatena.ne.jp>
