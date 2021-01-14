# 🗃 Store::Directories 🗃

Manage a key/value store of directories with controls for
concurrent access and locking.

**Version:** 0.2

# SYNOPSIS

```perl
use Store::Directories;

# Create a new store at given directory
# (or adopt one that is already there)
my $store = Store::Directories->init("path/to/store/")

# (In this example, we create a new directory containing a text file
# and then atomically increment the value written in the file)

my $value = 1;

# Get a directory with the key 'foo' in the store,
# creating it if it doesn't exist yet
my $lock;
my $dir = $store->get_or_add('foo' {

    # as an option, we can provide a subroutine to use to
    # initialize the directory contents if we create it
    # (but if the directory already exists, this won't be called)
    init => sub {
        my $dir = shift;
        open(my $fh, '>', "$dir/hello.txt") or die "could not open file: $!";
        print $fh $value;
        close $fh;
    }
});

{
    # Get an exclusive lock on the directory before reading/writing to it.
    # This ensure no other process is reading or modifying the directory
    # contents while we're working.
    my $lock = $store->lock_ex('foo');

    open(my $fh, '<', "$dir/hello.txt") or die "could not open file: $!";
    $value = <$fh>;
    open($fh, '>', "$dir/hello.txt")    or die "could not re-open file: $!";
    print $fh $value + 1;
    close $fh;

    # The lock is released once $lock is out-of-scope
}
```

# DESCRIPTION

[Store::Directories](https://metacpan.org/pod/Store%3A%3ADirectories) manages a key/value store of directories and allows
processes to assert shared (read-only) or exclusive (writable) locks on
those directories.

Directories in a [Store::Directories](https://metacpan.org/pod/Store%3A%3ADirectories) Store are referenced by unique
string "keys". Internally, the directories are named with hexadecimal UUIDS,
so the keys you use to identify them can contain illegal or unusual characters
for filenames. (web URLs are a common example).

Processes can perform operations on these directories in parallel by requesting
"locks" on particualr directories. These locks can be either _shared_ or
_exclusive_ (to borrow [flock(2)](http://man.he.net/man2/flock) terminology). Lock objects are obtained
with the `lock_sh` or `lock_ex` methods of a [Store::Directories](https://metacpan.org/pod/Store%3A%3ADirectories) instance
and are automatically released once they go out of scope.

**Shared** locks are used when a process wants to read, but not modify the
contents of a directory while being sure that no other process can modify the
contents while its reading. There can be multiple shared locks from different
processes on a directory at once, but never at the same time as an _exclusive_
lock.

**Exclusive** locks are used when a process wants to read _and_ modify the
contents of a directory while being sure that no other process can modify
or read the contents while its working. There can only be one exclusive lock
on a directory at once and there can't be any _shared_ locks with it.

If a process requests a lock that is unavailable at the moment (due to another
process already having an incompatible lock), then the process will block until
the lock can be obtained (either by the other process dying or releasing its
locks). Be aware that the order in which locks are granted is _not_ necessarily
the same order that that they were requested in.

**WARNING:** The guarantees around locking make the assumption that every
process is using this package and playing by its rules.
Unrelated processes are free to ignore the rules and mess things up as
much as they like.

# Documentation

For full documentation, please see the man pages installed with the module
or the page on MetaCPAN [HERE](https://metacpan.org/pod/Store%3A%3ADirectories).

# AUTHOR

Cameron Tauxe `camerontauxe@gmail.com`

# LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
