[![Actions Status](https://github.com/vsepohui/Strong-Random/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/vsepohui/Strong-Random/actions?workflow=test)
# NAME

Strong::Random - Strong random generator

# SYNOPSIS

    use Strong::Random;

    my $rand = new Strong::Random;

    # Print random character
    print chr $rand->rand(256) . "\n";

# METHODS

## new()

Strong::Random constructor.

Parameters:

        $seed - Seed for next series of random generation by algorythm. 
                If not specified, will be use CPU-time + PID.

Return:

        Strong::Random based class object.

## srand()

Setup new seed.

Parameters:

        $seed - Seed for next series of random generation by algorythm. 
                If not specified, will be use CPU-time + PID.

## rand()

Return random number.

Parameters:

        $num - If specified, method will return int between [0..$num-1).
                   If not specfied, method return value form [0..1).

# VERSION

0.8

# AUTHOR

All code writen by Ivan Trunaev.

Contacts <ivan@trunaev.ru>
