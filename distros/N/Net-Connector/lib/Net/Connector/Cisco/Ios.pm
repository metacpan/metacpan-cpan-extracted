package Net::Connector::Cisco::Ios;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends("Net::Connector::Cisco::Nxos");

__PACKAGE__->meta->make_immutable;
1;
