# NAME

MooX::CalcTime - This is a instantial object of MooX::CalcTime::Role

# VERSION

version 0.0.8

# SYNOPSIS

    use MooX::CalcTime;
    my $t = MooX::CalcTime;
    ......
    ......

    # return second passed, such as 30
    $t->get_run_second;

    # return a string such as 'Running time: 3 days 2 minutes 1 hours 10 minutes 5 second';
    $t->get_runtime;

    # print return value of C<get_runtime_format> function
    $t->print_runtime;

# DESCRIPTION

This module is a instantial object of MooX::CalcTime::Role,
so that it can be used in a script.

If you want to see more detailed information,
please see [MooX::CalcTime::Role](https://metacpan.org/pod/MooX::CalcTime::Role).

# AUTHOR

Yan Xueqing <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
