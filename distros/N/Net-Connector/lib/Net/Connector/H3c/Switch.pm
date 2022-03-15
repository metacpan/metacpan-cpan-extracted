package Net::Connector::H3c::Switch;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends('Net::Connector::H3c::Comware');

__PACKAGE__->meta->make_immutable;
1;
