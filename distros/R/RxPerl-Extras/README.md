# NAME

RxPerl::Extras - original extra operators for RxPerl

# SYNOPSIS

    use RxPerl::Mojo qw/ ... /; # RxPerl::IOAsync and RxPerl::AnyEvent also possible
    use RxPerl::Extras 'op_exhaust_map_with_latest'; # or ':all'

    # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
    rx_timer(0, 2)->pipe(
        op_take(3),
        op_exhaust_map_with_latest(sub ($val, @) {
            return rx_of($val)->pipe( op_delay(5) );
        }),
    )->subscribe($observer);

# DESCRIPTION

RxPerl::Extras is a collection of original [RxPerl](https://metacpan.org/pod/RxPerl) operators not found in RxJS,
which the author thinks might be useful to many.

It currently contains four pipeable operators.

# EXPORTABLE FUNCTIONS

The code samples in this section assume `$observer` has been set to:

    $observer = {
        next     => sub {say "next: ", $_[0]},
        error    => sub {say "error: ", $_[0]},
        complete => sub {say "complete"},
    };

## PIPEABLE OPERATORS

- op\_exhaust\_all\_with\_latest

    See ["op\_exhaust\_map\_with\_latest"](#op_exhaust_map_with_latest).

        # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
        rx_timer(0, 2)->pipe(
            op_take(3),
            op_map(sub { rx_of($_)->pipe( op_delay(5) ) }),
            op_exhaust_all_with_latest(),
        )->subscribe($observer);

- op\_exhaust\_map\_with\_latest

    Works like RxPerl's [op\_exhaust\_map](https://metacpan.org/pod/RxPerl#op_exhaust_map), except if any new next events arrive before exhaustion,
    the latest of those events will be processed after exhaustion as well.

        # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
        rx_timer(0, 2)->pipe(
            op_take(3),
            op_exhaust_map_with_latest(sub ($val, @) {
                return rx_of($val)->pipe( op_delay(5) );
            }),
        )->subscribe($observer);

- op\_throttle\_time\_with\_both\_leading\_and\_trailing

    Immediately emits events received if none have been emitted during the past `$duration`,
    but if during the next `$duration` seconds after emitting, some next events are received,
    the latest one of those will be emitted after `$duration`.

        # 0, (pause 3 seconds) 4, complete
        rx_timer(0, 0.7)->pipe(
            op_throttle_time_with_both_leading_and_trailing(3),
            op_take(2),
        )->subscribe($observer);

- op\_throttle\_with\_both\_leading\_and\_trailing

        # 0, (pause 3 seconds) 4, complete
        rx_timer(0, 0.7)->pipe(
            op_throttle_with_both_leading_and_trailing(sub ($val) { rx_timer(3) }),
            op_take(2),
        )->subscribe($observer);

# NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this module, at [https://perlmodules.net](https://perlmodules.net).

# COMMUNITY CODE OF CONDUCT

[RxPerl's Community Code of Conduct](https://metacpan.org/pod/RxPerl%3A%3ACodeOfConduct) applies to this module too.

# LICENSE

Copyright (C) 2024 Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Karelas <karjala@cpan.org>
