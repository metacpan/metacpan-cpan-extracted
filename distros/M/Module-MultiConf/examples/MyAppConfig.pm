#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/examples/MyAppConfig.pm $
# $LastChangedRevision: 1380 $
# $LastChangedDate: 2007-09-21 11:50:13 +0100 (Fri, 21 Sep 2007) $
# $LastChangedBy: oliver $
#
package # hide from PAUSE
    MyAppConfig;

use strict;
use warnings FATAL => 'all';

use Module::MultiConf;

__PACKAGE__->Validate({
    log_dispatch_syslog => {
        name      => { type => SCALAR, default => 'rpc-serialized' },
        min_level => { type => SCALAR, default => 'info' },
        facility  => { type => SCALAR, default => 'local0' },
        callbacks => { type => CODEREF | ARRAYREF,
                            default => sub { return "$_[1]\n" } },
    },
    rpc_serialized => {
        server_class => { type => SCALAR, optional => 1 },
        handlers     => { type => HASHREF, optional => 1 },
        handler_namespaces => { type => SCALAR | ARRAYREF,
                                default => 'RPC::Serialized::Handler'},
        acl_path     => { type => SCALAR, optional => 1},
        debug        => { type => SCALAR, default => 0 },
        trace        => { type => SCALAR, default => 0 },
        timeout      => { type => SCALAR, default => 30 },
    },
    net_server => {
        log_level => { type => SCALAR, default => 4 },
        log_file  => { type => SCALAR | UNDEF, default => undef },
        syslog_facility => { type => SCALAR, default => 'local1' },
        background => { type => SCALAR | UNDEF, default => undef },
        setsid     => { type => SCALAR | UNDEF, default => undef },
    },
});

__PACKAGE__->Force({
    data_serializer => {
        portable => 1,
    },
    net_server => {
        no_client_stdout  => undef,
        no_close_by_child => 1,
    },
});

1;

