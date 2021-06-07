package PawsX::Waiter;

use strict;
use warnings;

use Moose::Role;
use JSON;
use Path::Tiny;
use PawsX::Waiter::Client;

our $VERSION = "0.03";

sub GetWaiter {
    my ( $self, $waiter ) = @_;

    my $version     = $self->version;
    my $waiter_file = path(__FILE__)->parent->child('Waiter/waiters.json');

    my $service = lc $self->service;
    my $definition    = $waiter_file->slurp();
    my $waiter_struct = JSON->new->utf8(1)->decode($definition);

    if ( my $config = $waiter_struct->{$service}->{$version}->{$waiter} ) {
        return PawsX::Waiter::Client->new(
            client      => $self,
            delay       => $config->{'delay'},
            maxAttempts => $config->{'maxAttempts'},
            operation   => $config->{'operation'},
            acceptors   => $config->{'acceptors'},
        );
    }

    die "Invalid waiter: " . $waiter;
}

1;
__END__

=encoding utf-8

=head1 NAME
    
PawsX::Waiter - A Waiter library for Paws

=head1 SYNOPSIS

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
      $waiter->wait({
          LoadBalancerName => 'test-elb',
          Instances        => [ { InstanceId => 'i-0xxxxx' } ],
      });
      
=head1 DESCRIPTION

Waiters are utility methods that poll for a particular state to occur on a client. Waiters can fail after a number of attempts at a polling interval defined for the service client.

=head1 METHODS

=head2 GetWaiter

    my $waiter = $service->GetWaiter('InstanceInService');
    
This method returns a new PawsX::Waiter object and It has the following attributes. You can configure the waiter behaviour with this.

=head3 delay(Int)
    
    $waiter->delay(10);
    
Number of seconds to delay between polling attempts. Each waiter has a default delay configuration value, but you may need to modify this setting for specific use cases.

=head3 maxAttempts(Int)
    
    $waiter->maxAttempts(100);
    
Maximum number of polling attempts to issue before failing the waiter. Each waiter has a default maxAttempts configuration value, 
but you may need to modify this setting for specific use cases.

=head4 beforeWait(CodeRef)

    $waiter->beforeWait(sub { 
        my ($w, $attempts, $response) = @_;
        say STDERR "Waiter attempts left:" . ( $w->maxAttempts - $attempts );
    });

Register a callback that is invoked after an attempt but before sleeping. provides the number of attempts made and the previous response.
  
=head3 wait(HashRef)
    
     $waiter->wait({
         LoadBalancerName => 'test-elb',
         Instances        => [ { InstanceId => 'i-0xxxxx' } ],
     });

Block until the waiter completes or fails.Note that this might throw a PawsX::Exception::* if the waiter fails.

=head1 SEE ALSO

=over 4

=item L<Paws>

=back

=head1 AUTHOR

Prajith Ndz E<lt>prajithpalakkuda@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) Prajith Ndz.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
