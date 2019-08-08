#!/usr/bin/perl

use feature 'say';
use Try::Tiny;
use Paws;
use Paws::Credential::File;
use Paws::Exception;
use PawsX::Waiter;

my $loadbalancer = $ARGV[0];
my $instance_id  = $ARGV[1];

my $client = Paws->new(
    config => {
        credentials => Paws::Credential::File->new( profile => 'preprod' ),
        region      => 'ap-south-1'
    }
);

my $service = $client->service('ELB');

# Apply waiter role to Paws class
PawsX::Waiter->meta->apply($service);

{
    my $response = $service->DeregisterInstancesFromLoadBalancer(
        LoadBalancerName => $loadbalancer,
        Instances        => [ { InstanceId => $instance_id } ]
    );
}

{
    my $response = $service->RegisterInstancesWithLoadBalancer(
        LoadBalancerName => $loadbalancer,
        Instances        => [ { InstanceId => $instance_id } ]
    );

    my $waiter = $service->GetWaiter('InstanceInService');  

     $waiter->beforeWait(sub { 
	 my ($w, $attempts, $response) = @_;
         say STDERR "Waiter attempts left:" . ( $w->maxAttempts - $attempts );
     }); 

    $waiter->wait(
        {
            LoadBalancerName => $loadbalancer,
            Instances        => [ { InstanceId => $instance_id } ],
        }
    );
}
