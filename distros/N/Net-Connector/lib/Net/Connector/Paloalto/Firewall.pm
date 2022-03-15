package Net::Connector::PaloAlto::Firewall;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

extends("Net::Connector::PaloAlto::Panos");

__PACKAGE__->meta->make_immutable;
1;
