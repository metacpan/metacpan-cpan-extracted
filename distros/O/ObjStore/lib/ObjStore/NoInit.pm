use strict;
package ObjStore::NoInit;
use Carp;
use vars qw($INIT_DELAYED);
$INIT_DELAYED = 1;

sub import {
    carp "ObjStore::NoInit used too late" if $ObjStore::INITIALIZED;
    shift;
    require ObjStore;
    ObjStore->export(scalar caller(0), @_);
}

sub VERSION {
    carp "ObjStore::NoInit used too late" if $ObjStore::INITIALIZED;
    shift;
    require ObjStore;
    ObjStore->VERSION(@_);
}

1;

=head1 NAME

ObjStore::NoInit - 'use ObjStore', but Delay Initialization

=head1 SYNOPSIS

    #use ObjStore qw(import list);
    use ObjStore::NoInit qw(import list);

=head1 DESCRIPTION

We go through hoops to make it easy for newbies.  Use this module if
you need to do something fancy.  Here is a list of fancies:

=over 4

=item * $ObjStore::CACHE_SIZE

=item * $ObjStore::CLIENT_NAME

=item * $ObjStore::SCHEMA_DB

=back

Some of these variables can also be set via environment variables.

=cut
