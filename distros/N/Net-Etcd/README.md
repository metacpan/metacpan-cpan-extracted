[![Build Status](https://api.travis-ci.org/hexfusion/perl-etcd3.svg?branch=master)](https://travis-ci.org/hexfusion/perl-etcd3)

# NAME

Net::Etcd

# SYNOPSIS

    Etcd v3.1.0 or greater is required.   To use the v3 API make sure to set environment
    variable ETCDCTL_API=3.  Precompiled binaries can be downloaded at https://github.com/coreos/etcd/releases.

    $etcd = Net::Etcd->new(); # host: 127.0.0.1 port: 2379
    $etcd = Net::Etcd->new({ host => $host, port => $port, ssl => 1 });

    # put key
    $result = $etcd->put({ key =>'foo1', value => 'bar' });

    # get single key
    $key = $etcd->range({ key =>'test0' });

    # return single key value or the first in a list.
    $key->get_value

    # get range of keys
    $range = $etcd->range({ key =>'test0', range_end => 'test100' });

    # return array { key => value } pairs from range request.
    my @users = $range->all

    # watch key range, streaming.
    $watch = $etcd->watch( { key => 'foo', range_end => 'fop'}, sub {
        my ($result) =  @_;
        print STDERR Dumper($result);
    })->create;

    # create/grant 20 second lease
    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

    # attach lease to put
    $etcd->put( { key => 'foo2', value => 'bar2', lease => 7587821338341002662 } );

# DESCRIPTION

`Net::Etcd` An object oriented interface to the v3 REST API provided by the etcd grpc gateway.

# ACCESSORS

## host

## port

## username

## password

## ssl

## auth

## api\_root

## api\_prefix

defaults to /v3alpha

## api\_path

## auth\_token

# PUBLIC METHODS

## watch

Returns a [Net::Etcd::Watch](https://metacpan.org/pod/Net::Etcd::Watch) object.

    $etcd->watch({ key =>'foo', range_end => 'fop' })

## role

Returns a [Net::Etcd::Auth::Role](https://metacpan.org/pod/Net::Etcd::Auth::Role) object.

    $etcd->role({ role => 'foo' });

## user\_role

Returns a [Net::Etcd::User::Role](https://metacpan.org/pod/Net::Etcd::User::Role) object.

    $etcd->user_role({ name => 'samba', role => 'foo' });

## auth\_enable

Currently not available.

## lease

Returns a [Net::Etcd::Lease](https://metacpan.org/pod/Net::Etcd::Lease) object.

## user

Returns a [Net::Etcd::User](https://metacpan.org/pod/Net::Etcd::User) object.

## put

Returns a [Net::Etcd::KV::Put](https://metacpan.org/pod/Net::Etcd::KV::Put) object.

## range

Returns a [Net::Etcd::KV::Range](https://metacpan.org/pod/Net::Etcd::KV::Range) object.

## configuration

Initialize configuration checks to see it etcd is installed locally.

# AUTHOR

Sam Batschelet, &lt;sbatschelet at mac.com>

# ACKNOWLEDGEMENTS

The [etcd](https://github.com/coreos/etcd) developers and community.

# CAVEATS

The [etcd](https://github.com/coreos/etcd) v3 API is in heavy development and can change at anytime please see
https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/api\_reference\_v3.md
for latest details.

# LICENSE AND COPYRIGHT

Copyright 2017 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
