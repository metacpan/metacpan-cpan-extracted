package Net::Connector::Juniper::Firewall;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends('Net::Connector::Juniper::Srx');

__PACKAGE__->meta->make_immutable;
1;
