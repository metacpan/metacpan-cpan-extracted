#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp;
use Data::Dumper;
use JSON;

my $json_file = $ARGV[0];
my $json = read_file( $json_file ) ;

my $tree = decode_json($json);


sub generate_pod {
    my $path = shift || return;
    my $method = shift || return;
    my $conf = shift || return;

    return unless ref $conf;

    my $pod;
    if ($method eq 'POST') {
        $pod .= "\n=head2 $conf->{name}\n\n";
        $pod .= $conf->{'description'} . "\n\n";
        $pod .= "Usage: \$obj->$conf->{name}(\%args)\n";
        $pod .= "<%args> may items contain from the following list:\n";
        $pod .= "\n=over 4\n\n";
        for my $parameter (keys %{$conf->{parameters}->{'properties'}}) {
            $pod .= "\n=item $parameter\n\n";
            $pod .= $conf->{parameters}->{'properties'}->{$parameter}->{description} . "\n";
            $pod .= "type: $conf->{parameters}->{'properties'}->{$parameter}->{type}\n";
            $pod .= "optional: $conf->{parameters}->{'properties'}->{$parameter}->{optional}\n";
        }
        $pod .= "\n=back\n\n";
        print "$pod";
        
    }
    elsif ($method eq 'GET') {
        $pod .= "\n=head2 $conf->{name}\n\n";
        $pod .= $conf->{'description'} . "\n\n";
        $pod .= "Usage: \$obj->$conf->{name}(\%args)\n";
        $pod .= "<%args> may items contain from the following list:\n";
        $pod .= "\n=over 4\n\n";
        for my $parameter (keys %{$conf->{parameters}->{'properties'}}) {
            $pod .= "\n=item $parameter\n\n";
            $pod .= $conf->{parameters}->{'properties'}->{$parameter}->{description} . "\n";
            $pod .= "type: $conf->{parameters}->{'properties'}->{$parameter}->{type}\n";
            $pod .= "optional: $conf->{parameters}->{'properties'}->{$parameter}->{optional}\n";
        }
        $pod .= "\n=back\n\n";
        print "$pod";
    }
    else {
        warn "generate_method does not support type: $method\n";
    }
}
sub generate_code {
    my $path = shift || return;
    my $method = shift || return;
    my $conf = shift || return;

    print "Generating code: $path method: $method function: $conf->{'name'}\n";
    if ($method eq 'POST') {
        my $prefix = ''
    }
    elsif ($method eq 'GET') {
        print sprintf 'sub %s {
    my $self = shift or return;

    my $a = shift or die "No node for %s()";
    die "node must be a scalar for %s()" if ref $a;

    return $self->get( $base, $a )

}', $conf->name, $conf->name, $conf->name;

        print Dumper $conf;
    }


}
sub process_info {
    my $path = shift || return;
    my $conf = shift || return;
    #print Dumper $conf;
    for my $method (sort keys %{$conf}) {
        #print "path: $path name: $conf->{$method}->{'name'}, method: $conf->{$method}->{'method'}, description: $conf->{$method}->{'description'}\n";
        if ($path =~ m#^/node# && $conf->{$method}->{name} eq 'vmlist' ) {
            #print "Generating pod for $conf->{$method}->{name}\n";
            generate_pod($path,$method,$conf->{$method});
            generate_code($path,$method,$conf->{$method});
        }
    }

}
sub process_children {
    my $conf = shift || return;
    #print Dumper $conf;
    #print "DEBUG: process_children\n";
    for my $child (@{$conf}) {
        process_info($child->{path},$child->{info}) if $child->{info};
        process_children($child->{children});
    }
}

for my $item (@{$tree}) {
    #next unless $item->{text} eq 'nodes';
    process_info($item->{path}, $item->{info});
    process_children($item->{children});
}

#for my $item (@{$tree}) {
#    next unless $item->{text} eq 'nodes';
#    print Dumper $item;
#    if ($item->{children}) {
#        for my $child (@{$item->{children}}) {
#            for my $gchild (@{$child->{children}}) {
#                for my $hash (keys %{$gchild}) {
#                    #print Dumper $gchild;
#                    for my $type (keys %{$gchild->{'info'}}){ 
#                        print "DEBUG: $type\n";
#                        generate_method($type, $gchild->{'info'}->{$type});
#                    }
#                }
#            }
#        }
#    }
#}

=over 4

=item storage

String. The storage to be used in pve-storage-id format. Required.

          {
                      'permissions' => {
                                         'user' => 'all',
                                         'description' => 'You need \'VM.Allocate\' permissions on /vms/{vmid} or on the VM pool /pool/{pool}. For restore (option \'archive\'), it is enough if the user has \'VM.
Backup\' permission and the VM already exists. If you create disks you need \'Datastore.AllocateSpace\' on any used storage.'
                                       },
                      'returns' => {
                                     'type' => 'string'
                                   },
                      'protected' => 1,
                      'name' => 'create_vm',
                      'description' => 'Create or restore a virtual machine.',
                      'parameters' => {
                                        'additionalProperties' => 0,
                                        'properties' => {
                                                          'hostpci[n]' => {
                                                                            'format' => 'pve-qm-hostpci',
                                                                            'typetext' => 'HOSTPCIDEVICE',
                                                                            'type' => 'string',
                                                                            'optional' => 1,
                                                                            'description' => 'Map host pci devices. HOSTPCIDEVICE syntax is:
    }


}

#print Dumper $tree;

=cut 
