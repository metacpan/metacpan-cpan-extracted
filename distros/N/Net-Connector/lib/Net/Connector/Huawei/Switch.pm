package Net::Connector::Huawei::Switch;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends('Net::Connector::Huawei::Vrp');

__PACKAGE__->meta->make_immutable;
1;
