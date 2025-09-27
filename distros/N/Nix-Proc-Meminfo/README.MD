# NAME

Nix::Proc::Meminfo - access /proc/meminfo with core classes

# SYNOPSIS

    #!/usr/bin/env perl

    use v5.42;
    use Nix::Proc::Meminfo;

    my $proc = Nix::Proc::Meminfo->new();

    # optionally you can provide a parameter for a custom location
    $proc = Nix::Proc::Meminfo->new( file_uri => '/proc/meminfo' );

    # return a hash ref with all meminfo parameters as keys, each with a "value" and "unit"
    my $mi = $proc->get_all();
    say "MemTotal: ".$mi->{'MemTotal'}{'value'};

    # alternatively you can just retrieve a single value from /proc/meminfo wrather than load all of them
    # which will save a tiny little bit of memory and possibly time
    say "Active(file): " . $proc->get('Active(file)')->{'value'};

    # the units are also provided and will typically be KB or an empty string
    say "DirectMap4k: " . $proc->get('DirectMap4k')->{'unit'};

# DESCRIPTION

Nix::Proc::Meminfo provides access to the linux /proc/meminfo file which contains real time
data about current memory usage provided directly by the kernel. This module requires a minimum 5.42 version of perl
because it uses modern perl features throughout it's code. This module is written using the core class feature.

The module is parameter agnostic. Meaning it simply parses the meminfo file on your system the way it is presented by the Linux kernel. Some Linux kernels that have been modified or are ancient, may not provide certain parameters. It is the duty of the
user to understand what is provided by a modified kernel.

# METHODS

## new

`new()`

Object constructor that accepts a single optional argument `file_uri` allowing the user to change the location
the object looks for the meminfo file. This obviously defaults to `/proc/meminfo` where it typically should be.

## get

`get('SomeParam')`

Accepts a string that is the case sensitive name of the parameter found in the meminfo file.
Returns either `false` if the parameter was not found or a hash ref with two keys:

`value` and `unit`. Where `value` is probably the number you are looking for
and `unit` is typically either "KB" or an empty string.

## get\_all

`get_all()`

Accepts no arguments. Returns a hash reference where the parameters of your meminfo file are keys and values are hashes containing `value` and `unit` keys respectively.

# SEE ALSO

Study what you might expect to find in your `/proc/meminfo` file:

[proc\_meminfo(5)](https://man7.org/linux/man-pages/man5/proc_meminfo.5.html)

# LICENSE

Copyright (C) 2025 Joshua S. Day

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
