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
$Net::OpenNebula::Cluster::VERSION = '0.310.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'cluster';

1;
