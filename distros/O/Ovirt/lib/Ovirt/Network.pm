package Ovirt::Network;

use v5.10;
use Carp;
use Moo;

with 'Ovirt';
our $VERSION = '0.01';

=head1 NAME

Ovirt::Network - Bindings for oVirt Network API 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 use Ovirt::Network;

 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            network_output_attrs    => 'id,data_center_id,name,description', # optional 
 );

 my $network = Ovirt::Network->new(%con);

 # return xml output
 print $network->list_xml; 
 
 # list network attributes
 print $network->list;

 # the output also available in hash
 # for example to print all network name
 my $hash = $network->hash_output;
 for my $array (keys $hash->{network}) {
    print $hash->{network}[$array]->{name};
 }
 
 # we can also specify specific network 'id' when initiating an object
 # so we can direct access the element for specific network
 print $network->hash_output->{id};                   
 print $network->hash_output->{name};

=head1 Attributes

 Other attributes is also inherited from Ovirt.pm
 Check 'perldoc Ovirt' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class 
 
 network_url            = (ro) store default network url path
 network_output_attrs   = (rw) store network attributes to be returned, default is (id, data_center_id, name, description)
                          supported attributes :
                            id          name    
                            usage       description
                            stp         data_center_id
                            mtu 
                            
 network_output_delimiter    = (rw) specify output delimiter between attribute, default is '||'
=cut

has 'network_url'              => ( is => 'ro', default => '/api/networks' );
has 'network_output_attrs'     => ( is => 'rw', default => 'id,data_center_id,name,description',
                                 isa => sub {
                                     # store all output attribute into array split by ','
                                     # $_[0] is the arguments spefied during initialization
                                     my @attrs = split ',' => $_[0];
                                     
                                     croak "network_output_attrs can't be empty"
                                        unless @attrs;
                                     
                                     # check if provided attribute is valid / supported
                                     my @supported_attr = qw |
                                                                id          name    
                                                                usage       description
                                                                stp         data_center_id
                                                                mtu 
                                                            |;
                                     for my $attr (@attrs) {
                                         $attr = lc ($attr);
                                         $attr = Ovirt->trim($attr);
                                         croak "Attribute $attr is not valid / supported"
                                            unless grep { /\b$attr\b/ } @supported_attr;
                                     }
                                 });
                                 
has 'network_output_delimiter'   => ( is => 'rw', default => '||' ); 

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
 Built root_url with network_url
 set output with get_api_response method from Ovirt.pm
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj;
    
    if ($self->id) {
        $self->_set_root_url($self->network_url. '/' . $self->id);
    }
    else {
        $self->_set_root_url($self->network_url);
    }
    
    $self->get_api_response();
}

=head2 list

 return network's attributes text output from hash_output attribute
 if no argument spesified, it will return all network attributes (based on network_output_attrs)
 argument supported is 'network id'
 example :
 $network->list('c4738b0f-b73d-4a66-baa8-2ba465d63132');
=cut

sub list {
    my $self = shift;
    
    my $networkid = shift || undef;
    
    # store the output and return it at the end
    my $output;
    
    # store each attribute to array to be looped
    my @attrs   = split ',' => $self->network_output_attrs;
    
    # store the last element to escape the network_output_delimeter
    my $last_element = pop (@attrs);
    $self->log->debug("last element = $last_element");
    
    # if the id is defined during initialization
    # the rest api output will only contain attributes for this id
    # so it's not necessary to loop on network element
    if ($self->id) {
        for my $attr (@attrs) {
            $self->log->debug("requesting attribute $attr");
    
            my $attr_output = $self->get_network_by_self_id($attr) || $self->not_available;
            $output         .= $attr_output . $self->network_output_delimiter;
            $self->log->debug("output for attribute $attr  = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element");
        
        if (my $last_output = $self->get_network_by_self_id($last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element  = " . $last_output);
        }
        
        $output .= "\n";
    }
    elsif ($networkid) {
        #store networkid element
        my $networkid_element;
        
        $networkid = $self->trim($networkid);
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{network} } ) {
            next unless $self->hash_output->{network}[$element_id]->{id} eq $networkid;
            
            $networkid_element = $element_id;
        }
        
        croak "network id not found" unless $networkid_element >= 0;
        
        for my $attr (@attrs) { 
           $self->log->debug("requesting attribute $attr for element $networkid_element");
    
            my $attr_output = $self->get_network_by_element_id($networkid_element, $attr) || $self->not_available;
            $output         .= $attr_output . $self->network_output_delimiter;
            $self->log->debug("output for attribute $attr element $networkid_element = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element for element $networkid_element");
        
        if (my $last_output = $self->get_network_by_element_id($networkid_element, $last_element) || $self->not_available) {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element element $networkid_element = " . $last_output);
        }
        
        $output .= "\n";
    }
    else {
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{network} } ) {
            
            # in case there's no any element left, the last element become the only attribute requested
            if (@attrs) {
                for my $attr (@attrs) {
                    
                    $self->log->debug("requesting attribute $attr for element $element_id");
    
                    my $attr_output = $self->get_network_by_element_id($element_id, $attr) || $self->not_available;
                    $output         .= $attr_output . $self->network_output_delimiter;
                    $self->log->debug("output for attribute $attr element $element_id = " . $attr_output);
                }
            }
            
            #handle last element or the only element
            $self->log->debug("requesting attribute $last_element for element $element_id");
            
            if (my $last_output = $self->get_network_by_element_id($element_id, $last_element) || $self->not_available) {
                $output .= $last_output;
                $self->log->debug("output for attribute $last_element element $element_id = " . $last_output);
            }
            
            $output .= "\n";
        }
    }
    
    return $output;
}

=head2 get_network_by_element_id
 
 This method is used by list method to list all network attributes requested
 An array element id and attribute name is required
=cut

sub get_network_by_element_id {
    my $self = shift;
    
    my ($element_id, $attr) = @_;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("element id = $element_id, attribute = $attr");
    
    if      ($attr eq 'id') {
            return $self->hash_output->{network}[$element_id]->{id};
    }
    elsif   ($attr eq 'name') {
            return $self->hash_output->{network}[$element_id]->{name};
    }
    elsif   ($attr eq 'usage') {
            return $self->hash_output->{network}[$element_id]->{usages}->{usage};
    }
    elsif   ($attr eq 'description') {
            return $self->hash_output->{network}[$element_id]->{description};
    }
    elsif   ($attr eq 'stp') {
            return $self->hash_output->{network}[$element_id]->{stp};
    }
    elsif   ($attr eq 'mtu') {
            return $self->hash_output->{network}[$element_id]->{mtu};
    }
    elsif   ($attr eq 'data_center_id') {
            return $self->hash_output->{network}[$element_id]->{data_center}->{id};
    }
}

=head2 get_network_by_self_id
 
 This method is used by list method if $self->id is defined
 The id is set during initialization (id => 'networkid')
 attribute name is required
=cut

sub get_network_by_self_id {
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
    elsif   ($attr eq 'usage') {
            return $self->hash_output->{usages}->{usage};
    }
    elsif   ($attr eq 'description') {
            return $self->hash_output->{description};
    }
    elsif   ($attr eq 'stp') {
            return $self->hash_output->{stp};
    }
    elsif   ($attr eq 'mtu') {
            return $self->hash_output->{mtu};
    }
    elsif   ($attr eq 'data_center_id') {
            return $self->hash_output->{data_center}->{id};
    }
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt::Network>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt::Network

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