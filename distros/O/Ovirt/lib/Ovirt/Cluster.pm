package Ovirt::Cluster;

use v5.10;
use Carp;
use Moo;

with 'Ovirt';
our $VERSION = '0.01';

=head1 NAME

Ovirt::Cluster - Bindings for oVirt Cluster API 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 use Ovirt::Cluster;

 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            cluster_output_attrs    => 'id,name,cpu_id,cpu_arch,description', # optional 
 );

 my $cluster = Ovirt::Cluster->new(%con);

 # return xml output
 print $cluster->list_xml; 
 
 # list cluster attributes
 print $cluster->list;

 # the output also available in hash
 # for example to print all cluster name
 my $hash = $cluster->hash_output;
 for my $array (keys $hash->{cluster}) {
    print $hash->{cluster}[$array]->{name};
 }
 
 # we can also specify specific cluster 'id' when initiating an object
 # so we can direct access the element for specific cluster
 print $cluster->hash_output->{name};                   
 print $cluster->hash_output->{cluster}->{id};

=head1 Attributes

 Other attributes is also inherited from Ovirt.pm
 Check 'perldoc Ovirt' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class 
 
 cluster_url            = (ro) store default cluster url path
 cluster_output_attrs   = (rw) store cluster attributes to be returned, default is (id, name, description)
                          supported attributes :
                            id          name    
                            cpu_id      description
                            cpu_arch    datacenter_id
                            ver_major   ver_minor
                            sched_name  sched_policy
                            
 cluster_output_delimiter    = (rw) specify output delimiter between attribute, default is '||'
=cut

has 'cluster_url' => ( is => 'ro', default => '/api/clusters' );
has 'cluster_output_attrs'       => ( is => 'rw', default => 'id,name,description',
                                 isa => sub {
                                     # store all output attribute into array split by ','
                                     # $_[0] is the arguments spefied during initialization
                                     my @attrs = split ',' => $_[0];
                                     
                                     croak "cluster_output_attrs can't be empty"
                                        unless @attrs;
                                     
                                     # check if provided attribute is valid / supported
                                     my @supported_attr = qw |
                                                                id          name    
                                                                cpu_id      description
                                                                cpu_arch    datacenter_id
                                                                ver_major   ver_minor
                                                                sched_name  sched_policy
                                                            |;
                                     for my $attr (@attrs) {
                                         $attr = lc ($attr);
                                         $attr = Ovirt->trim($attr);
                                         croak "Attribute $attr is not valid / supported"
                                            unless grep { /\b$attr\b/ } @supported_attr;
                                     }
                                 });
                                 
has 'cluster_output_delimiter'   => ( is => 'rw', default => '||' ); 

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
 Built root_url with cluster_url
 set output with get_api_response method from Ovirt.pm
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj;
    
    if ($self->id) {
        $self->_set_root_url($self->cluster_url. '/' . $self->id);
    }
    else {
        $self->_set_root_url($self->cluster_url);
    }
    
    $self->get_api_response();
}

=head2 list

 return cluster's attributes text output from hash_output attribute
 if no argument specified, it will return all cluster attributes (based on cluster_output_attrs)
 argument supported is 'cluster id'
 example :
 $cluster->list('c4738b0f-b73d-4a66-baa8-2ba465d63132');
=cut

sub list {
    my $self = shift;
    
    my $clusterid = shift || undef;
    
    # store the output and return it at the end
    my $output;
    
    # store each attribute to array to be looped
    my @attrs   = split ',' => $self->cluster_output_attrs;
    
    # store the last element to escape the cluster_output_delimeter
    my $last_element = pop (@attrs);
    $self->log->debug("last element = $last_element");
    
    # if the id is defined during initialization
    # the rest api output will only contain attributes for this id
    # so it's not necessary to loop on cluster element
    if ($self->id) {
        for my $attr (@attrs) {
            $self->log->debug("requesting attribute $attr");
    
            my $attr_output = $self->get_cluster_by_self_id($attr) || $self->not_available;
            $output         .= $attr_output . $self->cluster_output_delimiter;
            $self->log->debug("output for attribute $attr  = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element");
        
        if (my $last_output = $self->get_cluster_by_self_id($last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element  = " . $last_output);
        }
        
        $output .= "\n";
    }
    elsif ($clusterid) {
        #store clusterid element
        my $clusterid_element;
        
        $clusterid = $self->trim($clusterid);
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{cluster} } ) {
            next unless $self->hash_output->{cluster}[$element_id]->{id} eq $clusterid;
            
            $clusterid_element = $element_id;
        }
        
        croak "cluster id not found" unless $clusterid_element >= 0;
        
        for my $attr (@attrs) { 
           $self->log->debug("requesting attribute $attr for element $clusterid_element");
    
            my $attr_output = $self->get_cluster_by_element_id($clusterid_element, $attr) || $self->not_available;
            $output         .= $attr_output . $self->cluster_output_delimiter;
            $self->log->debug("output for attribute $attr element $clusterid_element = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element for element $clusterid_element");
        
        if (my $last_output = $self->get_cluster_by_element_id($clusterid_element, $last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element element $clusterid_element = " . $last_output);
        }
        
        $output .= "\n";
    }
    else {
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{vm} } ) {
            
            # in case there's no any element left, the last element become the only attribute requested
            if (@attrs) {
                for my $attr (@attrs) {
                    
                    $self->log->debug("requesting attribute $attr for element $element_id");
    
                    my $attr_output = $self->get_cluster_by_element_id($element_id, $attr) || $self->not_available;
                    $output         .= $attr_output . $self->cluster_output_delimiter;
                    $self->log->debug("output for attribute $attr element $element_id = " . $attr_output);
                }
            }
            
            #handle last element or the only element
            $self->log->debug("requesting attribute $last_element for element $element_id");
            
            if (my $last_output = $self->get_cluster_by_element_id($element_id, $last_element) || $self->not_available) {
                $output .= $last_output;
                $self->log->debug("output for attribute $last_element element $element_id = " . $last_output);
            }
            
            $output .= "\n";
        }
    }
    
    return $output;
}

=head2 get_cluster_by_element_id
 
 This method is used by list method to list all cluster attributes requested
 An array element id and attribute name is required
=cut

sub get_cluster_by_element_id {
    my $self = shift;
    
    my ($element_id, $attr) = @_;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("element id = $element_id, attribute = $attr");
    
    if      ($attr eq 'id') {
            return $self->hash_output->{cluster}[$element_id]->{id};
    }
    elsif   ($attr eq 'name') {
            return $self->hash_output->{cluster}[$element_id]->{name};
    }
    elsif   ($attr eq 'description') {
            return $self->hash_output->{cluster}[$element_id]->{description};
    }
    elsif   ($attr eq 'cpu_arch') {
            return $self->hash_output->{cluster}[$element_id]->{cpu}->{architecture};
    }
    elsif   ($attr eq 'cpu_id') {
            return $self->hash_output->{cluster}[$element_id]->{cpu}->{id};
    }
    elsif   ($attr eq 'datacenter_id') {
            return $self->hash_output->{cluster}[$element_id]->{data_center}->{id};
    }
    elsif   ($attr eq 'sched_name') {
            return $self->hash_output->{cluster}[$element_id]->{scheduling_policy}->{name};
    }
    elsif   ($attr eq 'sched_policy') {
            return $self->hash_output->{cluster}[$element_id]->{scheduling_policy}->{policy};
    }
    elsif   ($attr eq 'ver_major') {
            return $self->hash_output->{cluster}[$element_id]->{version}->{major};
    }
    elsif   ($attr eq 'ver_minor') {
            return $self->hash_output->{cluster}[$element_id]->{version}->{minor};
    }
}

=head2 get_cluster_by_self_id
 
 This method is used by list method if $self->id is defined
 The id is set during initialization (id => 'clusterid')
 attribute name is required
=cut

sub get_cluster_by_self_id {
    my $self = shift;
    
    my $attr = shift;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("attribute = $attr");
    
    if      ($attr eq 'id') {
            return $self->hash_output->{id};
    }
    elsif   ($attr eq 'name') {
            return $self->hash_output->{name};
    }
    elsif   ($attr eq 'description') {
            return $self->hash_output->{description};
    }
    elsif   ($attr eq 'cpu_arch') {
            return $self->hash_output->{cpu}->{architecture};
    }
    elsif   ($attr eq 'cpu_id') {
            return $self->hash_output->{cpu}->{id};
    }
    elsif   ($attr eq 'datacenter_id') {
            return $self->hash_output->{data_center}->{id};
    }
    elsif   ($attr eq 'sched_name') {
            return $self->hash_output->{scheduling_policy}->{name};
    }
    elsif   ($attr eq 'sched_policy') {
            return $self->hash_output->{scheduling_policy}->{policy};
    }
    elsif   ($attr eq 'ver_major') {
            return $self->hash_output->{version}->{major};
    }
    elsif   ($attr eq 'ver_minor') {
            return $self->hash_output->{version}->{minor};
    }
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt::Cluster>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt::Cluster

 You can also look for information at:

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 "Heince Kurniawan".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;