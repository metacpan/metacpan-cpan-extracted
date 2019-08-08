# NAME

PawsX::Waiter - A Waiter library for Paws

# SYNOPSIS
    use PawsX::Waiter;

      my $client = Paws->new(
         config => {
             region      => 'ap-south-1'
         }
      );

      my $service = $client->service('ELB');

      # Apply waiter role to Paws class
      PawsX::Waiter->meta->apply($service);
      my $response = $service->RegisterInstancesWithLoadBalancer(
         LoadBalancerName => 'test-elb',
         Instances        => [ { InstanceId => 'i-0xxxxx'  } ]
      );

      my $waiter = $service->GetWaiter('InstanceInService');
      $waiter->wait(
         {
            LoadBalancerName => 'test-elb',
            Instances        => [ { InstanceId => 'i-0xxxxx' } ],
        }
      );
      

# DESCRIPTION

Waiters are utility methods that poll for a particular state to occur on a client. Waiters can fail after a number of attempts at a polling interval defined for the service client.

# METHODS

## GetWaiter

    my $waiter = $service->GetWaiter('InstanceInService');
    

This method returns a new PawsX::Waiter object and It has the following attributes. You can configure the waiter behaviour with this.

### delay(Int)

    $waiter->delay(10);
    

Number of seconds to delay between polling attempts. Each waiter has a default delay configuration value, but you may need to modify this setting for specific use cases.

### maxAttempts(Int)

    $waiter->maxAttempts(100);
    

Maximum number of polling attempts to issue before failing the waiter. Each waiter has a default maxAttempts configuration value, 
but you may need to modify this setting for specific use cases.

### beforeWait(CodeRef)

    $waiter->beforeWait(sub { 
         my ($w, $attempts, $response) = @_;
         say STDERR "Waiter attempts left:" . ( $w->maxAttempts - $attempts );
    });


Register a callback that is invoked after an attempt but before sleeping. provides the number of attempts made and the previous response.

### wait(HashRef)

     $waiter->wait(
         {
            LoadBalancerName => 'test-elb',
            Instances        => [ { InstanceId => 'i-0xxxxx' } ],
        }
      );

Block until the waiter completes or fails.Note that this might throw a PawsX::Exception::\* if the waiter fails.

# SEE ALSO

- [Paws](https://metacpan.org/pod/Paws)

# AUTHOR

Prajith Ndz <prajithpalakkuda@gmail.com>

# COPYRIGHT

Copyright (C) Prajith Ndz.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
