# NAME

RxPerl::Mojo - Mojo::IOLoop adapter for RxPerl

# SYNOPSIS

    use RxPerl::Mojo ':all';
    use Mojo::IOLoop;

    sub make_observer ($i) {
        return {
            next     => sub {say "next #$i: ", $_[0]},
            error    => sub {say "error #$i: ", $_[0]},
            complete => sub {say "complete #$i"},
        };
    }

    my $o = rx_interval(0.7)->pipe(
        op_map(sub {$_[0] * 2}),
        op_take_until( rx_timer(5) ),
    );

    $o->subscribe(make_observer(1));

    Mojo::IOLoop->start;

# DESCRIPTION

RxPerl::Mojo is a module that lets you use the [RxPerl](https://metacpan.org/pod/RxPerl) Reactive Extensions in your Mojolicious app
or app that uses Mojo::IOLoop.

# DOCUMENTATION

The documentation at [RxPerl](https://metacpan.org/pod/RxPerl) applies to this module too.

# NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this, or other, modules, over at [https://perlmodules.net](https://perlmodules.net).

# COMMUNITY CODE OF CONDUCT

The Community Code of Conduct can be found [here](https://metacpan.org/pod/RxPerl%3A%3AMojo%3A%3ACodeOfConduct).

# LICENSE

Copyright (C) 2020 Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Karelas <karjala@cpan.org>
