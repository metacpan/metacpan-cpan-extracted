package Net::Connector::Hillstone::Firewall;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends('Net::Connector::Hillstone::Stoneos');

__PACKAGE__->meta->make_immutable;
1;
