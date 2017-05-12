# NAME

Net::ZooKeeper::Semaphore

# DESCRIPTION

Distributed semaphores via Apache ZooKeeper

# SYNOPSIS

    my $fqdn = Sys::Hostname::FQDN::fqdn();
    my $zkh = Net::ZooKeeper->new(...);

    my $cpu_semaphore = Net::ZooKeeper::Semaphore->new(
        count => 1,
        path => "/semaphores/${fqdn}_cpu",
        total => Sys::CPU::cpu_count(),
        zkh => $zkh,
    );

    my %mem_info = Linux::MemInfo::get_mem_info();
    my $mem_semaphore = Net::ZooKeeper::Semaphore->new(
        count => 4E6, # 4GB
        data => $$,
        path => "/semaphores/${fqdn}_mem",
        total => $mem_info{MemTotal},
        zkh => $zkh,
    );

    undef $cpu_semaphore; # to delete lease

# METHODS

## new(%options)

Object creation doesn't block.
Undef is returned if it isn't possible to acquire a lease.
An exception is raised on any ZooKeeper errors.
A lease is held as long as the object lives.

Parameters:

- count

Resource amount to be leased.
Must be an integer (negative values are to be added to total).

- data

Optional. Data for lease znode.
Must be a string, default is '0'.

- path

Path in ZooKeeper that identifies the semaphore.
If it doesn't exist, it will be created.
Also path/lock and path/leases will be created.

- total

Total amount of available resource.
If there are any active leases for the given path that were created with a
different total, an exception will be raised.

- zkh

Net::ZooKeeper handle object

# AUTHOR

    Oleg Komarov <komarov@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
