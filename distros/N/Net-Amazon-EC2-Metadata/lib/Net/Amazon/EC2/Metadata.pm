package Net::Amazon::EC2::Metadata;

use vars qw/$VERSION/; $VERSION='0.10';
use warnings;
use strict;
use Carp;

use LWP::Simple;
# http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1085&categoryID=100

#Docs
#http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/AESDG-chapter-instancedata.html


### Metadata
# ami-id	The AMI ID used to launch the instance.	1.0
# ami-manifest-path	The manifest path of the AMI with which the instance was launched.	1.0
# ami-launch-index	The index of this instance in the reservation (per AMI).	1.0
# ancestor-ami-ids	The AMI IDs of any instances that were rebundled to create this AMI.	2007-10-10
# instance-id	The ID of this instance.	1.0
# instance-type	The type of instance to launch. For more information, see Selecting Instance Types.	2007-08-29
# local-hostname	The local hostname of the instance.	2007-01-19
# public-hostname	The public hostname of the instance.	2007-01-19
# local-ipv4	Public IP address if launched with direct addressing; private IP address if launched with public addressing.	1.0
# public-ipv4	NATted public IP Address	2007-01-19
# public-keys/	Public keys. Only available if supplied at instance launch time	1.0
# reservation-id	ID of the reservation.	1.0
# security-groups	Names of the security groups the instance is launched in. Only available if supplied at instance launch time	1.0
# product-codes	 Product codes associated with this instance.	2007-03-01




my $data = {};
my $baseurl='http://169.254.169.254/latest/';
my $metaurl=$baseurl."meta-data/";
my $userurl=$baseurl."user-data/";

my @data = qw(ami_id ami_manifest_path ami_launch_index 
                  ancestor_ami_ids instance_id  instance_type
                  local_hostname public_hostname
                  local_ipv4 public_ipv4
                  reservation_id
                  security_groups
                  product_codes	
               );





for my $item (@data)  {
    no strict 'refs';
    *{"$item"} = sub {
        return $data->{$item}  if $data->{$item};
        my $path = $item;
        $path =~ s/_/-/;
        $data->{$item} = get($metaurl.$path);
        return $data->{$item};
    }
}
  

sub new{
    my $class = shift;
    return bless {}, $class;
}



# returns a hash of all the data
#
sub available_data{
    return [@data, 'user_data', 'public_keys'];
}

sub all_data{
    my $data={};
    for  (@data, 'user_data', 'public_keys' )      {
        no strict 'refs';        
        $data->{$_}= $_->();
    }
    return $data;
}



sub public_keys{
    my $self = shift;
    my $key  = shift;
    my $item = 'public_keys';    
    my $path = $item;
    $path =~ s/_/-/;
    if ($key)     {
        $path .=  "/$key";
        $item .=  "/$key";
    }
    return $data->{$item}  if $data->{$item} ;
    $data->{$item} = get($metaurl.$path);        
    return $data->{$item};
}

sub public_key{
    public_keys(@_);
}


sub user_data{
    my $item = '__userdata';    
    return $data->{$item}  if $data->{$item};
    my $path = $item;
    $data->{$item} = get($userurl);
    return $data->{$item};
}












1;

 # Magic true value required at end of module




__END__


=head1 NAME

Net::Amazon::EC2::Metadata - Retrieves data from EC2 Metadata service.  Both script and API; Works only from an EC2 instance.

=head1 VERSION

This document describes Net::Amazon::EC2::Metadata; version 0.10

=head1 SYNOPSIS
    
    #  running on an EC2 instance.
    use Perl6::Say;
    use Net::Amazon::EC2::Metadata;
    no warnings 'uninitialized';
    my $data = Net::Amazon::EC2::Metadata->all_data;
    for (sort keys %$data)      {
        say "$_: $data->{$_}";
    }

    ###############
    use Net::Amazon::EC2::Metadata;
    my $metadata_service= Net::Amazon::EC2::Metadata->new();  
    warn $metadata_service->ami_id; 


=head1 DESCRIPTION

This module queries Amazon's Elastic Compute Cloud Metadata service described at: http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/AESDG-chapter-instancedata.html . It also fetches 'user_data' which follows the same API but is often no considered part of the metadata service by Amazons documentation. The module also ships with a command line tool ec2meta  that provides the same data.  

THIS MODULE WILL ONLY WORK ON AN EC2 INSTANCE.

=head1 METHODS

=head2 new()

A constructor - for convenience all methods are class methods.

=head2 all_data()

Returns a hash ref of all the keys, and their values. Note: this means that public_keys is a listing of the keys not a listing of the values.

=head2 available_data()

A listing of all the meta_data and user_data available from this module.

=over

=item ami_id 

=item ami_manifest_path 

=item ami_launch_index 

=item ancestor_ami_ids 

=item instance_id  

=item instance_type

=item local_hostname 

=item public_hostname

=item local_ipv4 

=item public_ipv4

=item reservation_id

=item security_groups

=item product_codes

=item user_data

These methods all return the verbatim data from the calls to the service, and take no parameters. 

=back

=over

=item public_keys($key)

=item public_key($key)

Lists public keys if no key given, returns content of key if a key is given.

=back




=head1 AUTHOR

Nathan McFarland  C<< nathan@cpan.org >>


=head1 COPYRIGHT

Copyright (c) 2008 Nathan McFarland. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO


 Amazon EC2 Documentation: L<http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/>
 Amazon EC2 Metadata Documentation: L<http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/AESDG-chapter-instancedata.html>
 Amazon Tutorial on EC2 Metadata: L<http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1085&categoryID=100>
