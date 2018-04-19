[![Build Status](https://api.travis-ci.org/hexfusion/perl-net-etcd.svg?branch=master)](https://travis-ci.org/hexfusion/perl-net-etcd)

# NAME

Net::Etcd - etcd v3 REST API.

# SYNOPSIS

    Etcd v3.1.0 or greater is required.   To use the v3 API make sure to set environment
    variable ETCDCTL_API=3.  Precompiled binaries can be downloaded at https://github.com/coreos/etcd/releases.

    $etcd = Net::Etcd->new(); # host: 127.0.0.1 port: 2379
    $etcd = Net::Etcd->new({ host => $host, port => $port, ssl => 1 });

    # put key
    $put_key = $etcd->put({ key =>'foo1', value => 'bar' });

    # check for success of a transaction
    $put_key->is_success;

    # get single key
    $key = $etcd->range({ key =>'test0' });

    # return single key value or the first in a list.
    $key->get_value

    # get range of keys
    $range = $etcd->range({ key =>'test0', range_end => 'test100' });

    # return array { key => value } pairs from range request.
    my @users = $range->all

    # delete single key
    $etcd->deleterange({ key => 'test0' });

    # watch key range, streaming.
    $watch = $etcd->watch( { key => 'foo', range_end => 'fop'}, sub {
        my ($result) =  @_;
        print STDERR Dumper($result);
    })->create;

    # create/grant 20 second lease
    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

    # attach lease to put
    $etcd->put( { key => 'foo2', value => 'bar2', lease => 7587821338341002662 } );

    # add new user
    $etcd->user( { name => 'samba', password => 'foo' } )->add;

    # add new user role
    $role = $etcd->role( { name => 'myrole' } )->add;

    # grant read permission for the foo key to myrole
    $etcd->role_perm( { name => 'myrole', key => 'foo', permType => 'READWRITE' } )->grant;

    # grant role
    $etcd->user_role( { user => 'samba', role => 'myrole' } )->grant;

    # defrag member's backend database
    $defrag = $etcd->maintenance()->defragment;
    print "Defrag request complete!" if $defrag->is_success;

    # member version
    $v = $etcd->version;

    # list members
    $etcd->member()->list;

# DESCRIPTION

[Net::Etcd](https://metacpan.org/pod/Net::Etcd) is object oriented interface to the v3 REST API provided by the etcd [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway).

# ACCESSORS

## host

The etcd host. Defaults to 127.0.0.1

## port

Default 2379.

## name

Username for authentication, defaults to $ENV{ETCD\_CLIENT\_USERNAME}

## password

Authentication credentials, defaults to $ENV{ETCD\_CLIENT\_PASSWORD}

## ca\_file

Path to ca\_file, defaults to $ENV{ETCD\_CLIENT\_CA\_FILE}

## key\_file

Path to key\_file, defaults to $ENV{ETCD\_CLIENT\_KEY\_FILE}

## cert\_file

Path to cert\_file, defaults to $ENV{ETCD\_CLIENT\_CERT\_FILE}

## cacert

Path to cacert, defaults to $ENV{ETCD\_CLIENT\_CACERT\_FILE}.

## ssl

To enable set to 1

## api\_version

defaults to /v3beta

## api\_path

The full api path. Defaults to http://127.0.0.1:2379/v3alpha

## auth\_token

The token that is passed during authentication.  This is generated during the
authentication process and stored until no longer valid or username is changed.

# PUBLIC METHODS

## version

Returns the etcd member version

    $etcd->version()

## watch

See [Net::Etcd::Watch](https://metacpan.org/pod/Net::Etcd::Watch)

    $etcd->watch({ key =>'foo', range_end => 'fop' })

## role

See [Net::Etcd::Auth::Role](https://metacpan.org/pod/Net::Etcd::Auth::Role)

    $etcd->role({ role => 'foo' });

## role\_perm

See [Net::Etcd::Auth::RolePermission](https://metacpan.org/pod/Net::Etcd::Auth::RolePermission)

Grants or revoke permission of a specified key or range to a specified role.

## user\_role

See [Net::Etcd::User::Role](https://metacpan.org/pod/Net::Etcd::User::Role)

    $etcd->user_role({ name => 'samba', role => 'foo' });

## auth

See [Net::Etcd::Auth](https://metacpan.org/pod/Net::Etcd::Auth)

    $etcd->auth({ name => 'samba', password => 'foo' })->authenticate;
    $etcd->auth()->enable;
    $etcd->auth()->disable

## lease

See [Net::Etcd::Lease](https://metacpan.org/pod/Net::Etcd::Lease)

    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

## maintenance

See [Net::Etcd::Maintenance](https://metacpan.org/pod/Net::Etcd::Maintenance)

    $etcd->maintenance()->snapshot

## member

See [Net::Etcd::Member](https://metacpan.org/pod/Net::Etcd::Member)

    $etcd->member()->list

## user

See [Net::Etcd::User](https://metacpan.org/pod/Net::Etcd::User)

    $etcd->user( { name => 'samba', password => 'foo' } )->add;

## put

See [Net::Etcd::KV::Put](https://metacpan.org/pod/Net::Etcd::KV::Put)

    $etcd->put({ key =>'foo1', value => 'bar' });

## deleterange

See [Net::Etcd::KV::DeleteRange](https://metacpan.org/pod/Net::Etcd::KV::DeleteRange)

    $etcd->deleterange({ key=>'test0' });

## range

See [Net::Etcd::KV::Range](https://metacpan.org/pod/Net::Etcd::KV::Range)

    $etcd->range({ key =>'test0', range_end => 'test100' });

## txn

See [Net::Etcd::KV::Txn](https://metacpan.org/pod/Net::Etcd::KV::Txn)

    $etcd->txn({ compare => \@compare, success => \@op });

## op

See [Net::Etcd::KV::Op](https://metacpan.org/pod/Net::Etcd::KV::Op)

    $etcd->op({ request_put => $put });
    $etcd->op({ request_delete_range => $range });

## compare

See [Net::Etcd::KV::Compare](https://metacpan.org/pod/Net::Etcd::KV::Compare)

    $etcd->compare( { key => 'foo', result => 'EQUAL', target => 'VALUE', value => 'baz' });
    $etcd->compare( { key => 'foo', target => 'CREATE', result => 'NOT_EQUAL', create_revision => '2' });

## configuration

Initialize configuration checks to see if etcd is installed locally.

# AUTHOR

Sam Batschelet (hexfusion)

# CONTRIBUTORS

Ananth Kavuri

# ACKNOWLEDGEMENTS

The [etcd](https://github.com/coreos/etcd) developers and community.

# CAVEATS

The [etcd](https://github.com/coreos/etcd) v3 API is in heavy development and can change at anytime please see
 [api\_reference\_v3](https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/api_reference_v3.md)
for latest details.

Authentication provided by this module will only work with etcd v3.3.0+

# LICENSE AND COPYRIGHT

Copyright 2018 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
