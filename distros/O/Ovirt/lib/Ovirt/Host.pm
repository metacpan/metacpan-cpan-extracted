package Ovirt::Host;

use v5.10;
use Carp;
use Moo;

with 'Ovirt';
our $VERSION = '0.01';

=head1 NAME

Ovirt::Host - Bindings for oVirt Host API 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 use Ovirt::Host;

 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            host_output_attrs       => 'id,name,state',         # optional 
 );

 my $host = Ovirt::Host->new(%con);

 # return xml output
 print $host->list_xml; 
 
 # list host attributes
 print $host->list;

 # the output also available in hash
 # for example to print all host name
 my $hash = $host->hash_output;
 for my $array (keys $hash->{host}) {
    print $hash->{host}[$array]->{name};
 }
 
 # we can also specify specific host 'id' when initiating an object
 # so we can direct access the element for specific host
 print $host->hash_output->{id};                   
 print $host->hash_output->{name};

=head1 Attributes

 Other attributes is also inherited from Ovirt.pm
 Check 'perldoc Ovirt' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class 
 
 host_url               = (ro) store default host url path
 host_output_attrs      = (rw) store host attributes to be returned, default is (id, name, state)
                          supported attributes :
                            id          name
                            address     cluster_id
                            port        vdsm_version    
                            type        cpu_cores
                            state       memory
                            cpu_sockets cpu_name
                            cpu_speed   os_type
                            cpu_threads
                            
 host_output_delimiter    = (rw) specify output delimiter between attribute, default is '||'
=cut

has 'host_url'              => ( is => 'ro', default => '/api/hosts' );
has 'host_output_attrs'     => ( is => 'rw', default => 'id,name,state',
                                 isa => sub {
                                     # store all output attribute into array split by ','
                                     # $_[0] is the arguments spefied during initialization
                                     my @attrs = split ',' => $_[0];
                                     
                                     croak "host_output_attrs can't be empty"
                                        unless @attrs;
                                     
                                     # check if provided attribute is valid / supported
                                     my @supported_attr = qw |
                                                                id          name
                                                                address     cluster_id
                                                                port        vdsm_version    
                                                                type        cpu_cores
                                                                state       memory
                                                                cpu_sockets cpu_name
                                                                cpu_speed   os_type
                                                                cpu_threads
                                                            |;
                                     for my $attr (@attrs) {
                                         $attr = lc ($attr);
                                         $attr = Ovirt->trim($attr);
                                         croak "Attribute $attr is not valid / supported"
                                            unless grep { /\b$attr\b/ } @supported_attr;
                                     }
                                 });
                                 
has 'host_output_delimiter'   => ( is => 'rw', default => '||' ); 

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
 Built root_url with host_url
 set output with get_api_response method from Ovirt.pm
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj;
    
    if ($self->id) {
        $self->_set_root_url($self->host_url. '/' . $self->id);
    }
    else {
        $self->_set_root_url($self->host_url);
    }
    
    $self->get_api_response();
}

=head2 list

 return host's attributes text output from hash_output attribute
 if no argument spesified, it will return all host attributes (based on host_output_attrs)
 argument supported is 'host id'
 example :
 $host->list('c4738b0f-b73d-4a66-baa8-2ba465d63132');
=cut

sub list {
    my $self = shift;
    
    my $hostid = shift || undef;
    
    # store the output and return it at the end
    my $output;
    
    # store each attribute to array to be looped
    my @attrs   = split ',' => $self->host_output_attrs;
    
    # store the last element to escape the host_output_delimeter
    my $last_element = pop (@attrs);
    $self->log->debug("last element = $last_element");
    
    # if the id is defined during initialization
    # the rest api output will only contain attributes for this id
    # so it's not necessary to loop on host element
    if ($self->id) {
        for my $attr (@attrs) {
            $self->log->debug("requesting attribute $attr");
    
            my $attr_output = $self->get_host_by_self_id($attr) || $self->not_available;
            $output         .= $attr_output . $self->host_output_delimiter;
            $self->log->debug("output for attribute $attr  = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element");
        
        if (my $last_output = $self->get_host_by_self_id($last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element  = " . $last_output);
        }
        
        $output .= "\n";
    }
    elsif ($hostid) {
        #store hostid element
        my $hostid_element;
        
        $hostid = $self->trim($hostid);
        $self->log->debug("host id = $hostid");
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{host} } ) {
            next unless $self->hash_output->{host}[$element_id]->{id} eq $hostid;
            
            $hostid_element = $element_id;
            $self->log->debug("host id element : $hostid_element");
        }
        
        croak "host id not found" unless $hostid_element >= 0;
        
        for my $attr (@attrs) { 
           $self->log->debug("requesting attribute $attr for element $hostid_element");
    
            my $attr_output = $self->get_host_by_element_id($hostid_element, $attr) || $self->not_available;
            $output         .= $attr_output . $self->host_output_delimiter;
            $self->log->debug("output for attribute $attr element $hostid_element = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element for element $hostid_element");
        
        if (my $last_output = $self->get_host_by_element_id($hostid_element, $last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element element $hostid_element = " . $last_output);
        }
        
        $output .= "\n";
    }
    else {
        for my $element_id ( 0 .. $#{ $self->hash_output->{host} } ) {
            
            # in case there's no any element left, the last element become the only attribute requested
            if (@attrs) {
                for my $attr (@attrs) {
                    
                    $self->log->debug("requesting attribute $attr for element $element_id");
    
                    my $attr_output = $self->get_host_by_element_id($element_id, $attr) || $self->not_available;
                    $output         .= $attr_output . $self->host_output_delimiter;
                    $self->log->debug("output for attribute $attr element $element_id = " . $attr_output);
                }
            }
            
            #handle last element or the only element
            $self->log->debug("requesting attribute $last_element for element $element_id");
            
            if (my $last_output = $self->get_host_by_element_id($element_id, $last_element) || $self->not_available) {
                $output .= $last_output;
                $self->log->debug("output for attribute $last_element element $element_id = " . $last_output);
            }
            
            $output .= "\n";
        }
    }
    
    return $output;
}

=head2 get_host_by_element_id
 
 This method is used by list method to list all host attributes requested
 An array element id and attribute name is required
=cut

sub get_host_by_element_id {
    my $self = shift;
    
    my ($element_id, $attr) = @_;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("element id = $element_id, attribute = $attr");
    
    if      ($attr eq 'id') {
            return $self->hash_output->{host}[$element_id]->{id};
    }
    elsif   ($attr eq 'name') {
            return $self->hash_output->{host}[$element_id]->{name};
    }
    elsif   ($attr eq 'memory') {
            return $self->hash_output->{host}[$element_id]->{memory};
    }
    elsif   ($attr eq 'type') {
            return $self->hash_output->{host}[$element_id]->{type};
    }
    elsif   ($attr eq 'state') {
            return $self->hash_output->{host}[$element_id]->{status}->{state};
    }
    elsif   ($attr eq 'cpu_cores') {
            return $self->hash_output->{host}[$element_id]->{cpu}->{topology}->{cores};
    }
    elsif   ($attr eq 'cpu_sockets') {
            return $self->hash_output->{host}[$element_id]->{cpu}->{topology}->{sockets};
    }
    elsif   ($attr eq 'cpu_speed') {
            return $self->hash_output->{host}[$element_id]->{cpu}->{speed};
    }
    elsif   ($attr eq 'cpu_threads') {
            return $self->hash_output->{host}[$element_id]->{cpu}->{topology}->{threads};
    }
    elsif   ($attr eq 'os_type') {
            return $self->hash_output->{host}[$element_id]->{os}->{type};
    }
    elsif   ($attr eq 'cluster_id') {
            return $self->hash_output->{host}[$element_id]->{cluster}->{id};
    }
}

=head2 get_host_by_self_id
 
 This method is used by list method if $self->id is defined
 The id is set during initialization (id => 'hostid')
 attribute name is required
=cut

sub get_host_by_self_id {
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
    elsif   ($attr eq 'state') {
            return $self->hash_output->{status}->{state};
    }
    elsif   ($attr eq 'memory') {
            return $self->hash_output->{memory};
    }
    elsif   ($attr eq 'cpu_cores') {
            return $self->hash_output->{cpu}->{topology}->{cores};
    }
    elsif   ($attr eq 'cpu_sockets') {
            return $self->hash_output->{cpu}->{topology}->{sockets};
    }
    elsif   ($attr eq 'cpu_threads') {
            return $self->hash_output->{cpu}->{topology}->{threads};
    }
    elsif   ($attr eq 'cpu_speed') {
            return $self->hash_output->{cpu}->{speed};
    }
    elsif   ($attr eq 'os_type') {
            return $self->hash_output->{os}->{type};
    }
    elsif   ($attr eq 'cluster_id') {
            return $self->hash_output->{cluster}->{id};
    }
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt::Host>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt::Host

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