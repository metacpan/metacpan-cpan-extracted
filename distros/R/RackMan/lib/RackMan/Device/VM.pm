package RackMan::Device::VM;

use Moose::Role;
use RackMan;
use namespace::autoclean;

with "RackMan::Device::Server";

__PACKAGE__

__END__

=head1 NAME

RackMan::Device::VM - Base role for VMs

=head1 DESCRIPTION

This module is the base role for VMs.
Mostly a proxy module so VMs are treated like normal servers.

=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

