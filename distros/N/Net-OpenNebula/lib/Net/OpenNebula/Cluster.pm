#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
# !no_doc!
use strict;
use warnings;

package Net::OpenNebula::Cluster;
$Net::OpenNebula::Cluster::VERSION = '0.316.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'cluster';

sub create {
   my ($self, $name) = @_;
   return $self->_allocate([ string => $name ]);
}

# add something to this cluster
# eg add host with hostid 123
# $cluster->_do('add, 'host', 123)
# or pass Net::OpenNebula::Host instance as "resource" (no id needed)
sub _do
{
    my ($self, $action, $resource, $id) = @_;

    if ($action ne 'add' && $action ne 'del') {
        $self->error("Invalid cluster action $action");
        return;
    }

    my $ref = ref($resource);
    if ($ref =~ m/^Net::OpenNebula::(\w+)/) {
        $id = $resource->id;
        $resource = lc($1);
    }
    my $msg = "Cluster action $action for instance $ref resource $resource id $id";
    if (grep {$resource eq $_} qw(host datastore vnet)) {
        $self->info($msg);
        return $self->_onerpc("$action$resource", [int => $self->id], [int => $id]);
    } else {
        $self->error("$msg: unsupported resource");
        return;
    }
}

sub add
{
    my ($self, @args) = @_;
    return $self->_do('add', @args);
}

sub del
{
    my ($self, @args) = @_;
    return $self->_do('del', @args);
}


1;
