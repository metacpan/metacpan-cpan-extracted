#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
use strict;
use warnings;

=head1 NAME

Net::OpenNebula - Access OpenNebula RPC via Perl.

=head1 DESCRIPTION

With this module you can access the OpenNebula XML-RPC service.

=head1 SYNOPSIS

 use Net::OpenNebula;
 my $one = Net::OpenNebula->new(
    url      => "http://server:2633/RPC2",
    user     => "oneadmin",
    password => "onepass",
 );

 my @vms = $one->get_vms();

=cut

package Net::OpenNebula;
$Net::OpenNebula::VERSION = '0.310.0';
use Net::OpenNebula::RPCClient;
push our @ISA , qw(Net::OpenNebula::RPCClient);

use Data::Dumper;

use Net::OpenNebula::Cluster;
use Net::OpenNebula::Datastore;
use Net::OpenNebula::Group;
use Net::OpenNebula::Host;
use Net::OpenNebula::Image;
use Net::OpenNebula::Template;
use Net::OpenNebula::User;
use Net::OpenNebula::VM;
use Net::OpenNebula::VNet;

sub get_clusters {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Cluster->new(rpc => $self);
   return $new->_get_instances($nameregex);
}

sub get_datastores {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Datastore->new(rpc => $self);
   return $new->_get_instances($nameregex);
}

sub get_users {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::User->new(rpc => $self);
   return $new->_get_instances($nameregex);
}

sub get_groups {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Group->new(rpc => $self);
   return $new->_get_instances($nameregex);
}

sub get_hosts {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Host->new(rpc => $self);
   return $new->_get_instances($nameregex);
}

sub get_host {
   my ($self, $id) = @_;

   if(! defined $id) {
       my $msg = "You have to define the ID => Usage: \$obj->get_host(\$host_id)";

       $self->error($msg);
       if( $self->{fail_on_rpc_fail}) {
           die($msg);
       } else {
           return;
       }
   }

   my $data = $self->_rpc("one.host.info", [ int => $id ]);
   return Net::OpenNebula::Host->new(rpc => $self, data => $data, extended_data => $data);
}

sub get_vms {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::VM->new(rpc => $self);
   return $new->_get_instances($nameregex,
                               [ int => -2 ], # always get all resources
                               [ int => -1 ], # range from (begin)
                               [ int => -1 ], # range to (end)
                               [ int => -1 ], # all states, except DONE
                               );
}

sub get_vm {
   my ($self, $id) = @_;

   if(! defined $id) {
       my $msg = "You have to define the ID => Usage: \$obj->\$obj->get_vm(\$vm_id)";

       $self->error($msg);
       if( $self->{fail_on_rpc_fail}) {
           die($msg);
       } else {
           return;
       }
   }

   if($id =~ m/^\d+$/) {
      my $data = $self->_rpc("one.vm.info", [ int => $id ]);
      return Net::OpenNebula::VM->new(rpc => $self, data => $data, extended_data => $data);
   }
   else {
      # try to find vm by name
      my ($vm) = grep { $_->name eq $id } $self->get_vms;
      return $vm;
   }

}


sub get_templates {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Template->new(rpc => $self);
   return $new->_get_instances($nameregex,
                               [ int => -2 ], # all templates
                               [ int => -1 ], # range start
                               [ int => -1 ], # range end
                               );
}

sub get_vnets {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::VNet->new(rpc => $self);
   return $new->_get_instances($nameregex,
                               [ int => -2 ], # all VNets
                               [ int => -1 ], # range start
                               [ int => -1 ], # range end
                               );
}

sub get_images {
   my ($self, $nameregex) = @_;

   my $new = Net::OpenNebula::Image->new(rpc => $self);
   return $new->_get_instances($nameregex,
                               [ int => -2 ], # all templates
                               [ int => -1 ], # range start
                               [ int => -1 ], # range end
                               );
}

sub create_vm {
    my ($self, %option) = @_;

    my $template;

    if($option{template} =~ m/^\d+$/) {
        ($template) = grep { $_->id == $option{template} } $self->get_templates;
    }
    else {
        ($template) = grep { $_->name eq $option{template} } $self->get_templates;
    }

    my $hash_ref = $template->get_template_ref;
    $hash_ref->{TEMPLATE}->[0]->{NAME}->[0] = $option{name};

    my $s = XMLout($hash_ref, RootName => undef, NoIndent => 1 );

    my $id = $self->_rpc("one.vm.allocate", [ string => $s ]);

    if(! defined($id)) {
        $self->error("Create vm failed");
        return;
    }

    return $self->get_vm($id);
}

sub create_host {
    my ($self, %option) = @_;

    my @args = (
        "one.host.allocate",
        [ string => $option{name} ],
        [ string => $option{im_mad} ],
        [ string => $option{vmm_mad} ],
        );

    if ($self->version() < version->new('5.0.0')) {
        push(@args, [ string => $option{vnm_mad} ]);
    };
    push(@args, [ int => (exists $option{cluster} ? $option{cluster} : -1) ]);

    my $id = $self->_rpc(@args);

    if(! defined($id)) {
        $self->error("Create host failed");
        return;
    }

    return $self->get_host($id);
}


sub create_datastore {
   my ($self, $txt) = @_;

   my $new = Net::OpenNebula::Datastore->new(rpc => $self, data => undef);
   $new->create($txt);

   return $new;
}

sub create_user {
   my ($self, $name, $password, $driver) = @_;

   my $new = Net::OpenNebula::User->new(rpc => $self, data => undef);
   $new->create($name, $password, $driver);

   return $new;
}

sub create_group {
   my ($self, $name) = @_;

   my $new = Net::OpenNebula::Group->new(rpc => $self, data => undef);
   $new->create($name);

   return $new;
}

sub create_template {
   my ($self, $txt) = @_;

   my $new = Net::OpenNebula::Template->new(rpc => $self, data => undef);
   $new->create($txt);

   return $new;
}


sub create_vnet {
   my ($self, $txt) = @_;

   my $new = Net::OpenNebula::VNet->new(rpc => $self, data => undef);
   $new->create($txt);

   return $new;
}


sub create_image {
   my ($self, $txt, $datastore) = @_;

   my $datastoreid;
   if($datastore =~ m/^\d+$/) {
      $datastoreid = $datastore;
   }
   else {
      my @datastores = $self->get_datastores(qr{^$datastore$});
      $datastoreid = $datastores[0]->id if (@datastores); # take the first one
   }

   my $new = Net::OpenNebula::Image->new(rpc => $self, data => undef);
   $new->create($txt, $datastoreid);

   return $new;
}

1;
