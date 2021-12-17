# NAME

RxPerl::IOAsync - IO::Async adapter for RxPerl

# SYNOPSIS

    use RxPerl::IOAsync ':all';
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    RxPerl::IOAsync::set_loop($loop);

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

    $loop->run;

# DESCRIPTION

RxPerl::IOAsync is a module that lets you use the [RxPerl](https://metacpan.org/pod/RxPerl) Reactive Extensions in your app that uses IO::Async.

# DOCUMENTATION

The documentation at [RxPerl](https://metacpan.org/pod/RxPerl) applies to this module too.

# NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this, or other, modules, over at [https://perlmodules.net](https://perlmodules.net).

# COMMUNITY CODE OF CONDUCT

The Community Code of Conduct can be found [here](https://metacpan.org/pod/RxPerl%3A%3AIOAsync%3A%3ACodeOfConduct).

# LICENSE

Copyright (C) 2020 Karelcom OÜ.

This is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

# AUTHOR

Alexander Karelas <karjala@cpan.org>
