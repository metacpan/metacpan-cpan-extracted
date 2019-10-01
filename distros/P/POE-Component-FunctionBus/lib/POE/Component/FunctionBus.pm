package POE::Component::FunctionBus;

# Core/Internal modules and options
use 5.0244;
use strict;
use warnings;

# External modules
use POE;

=head1 NAME

POE::Component::FunctionBus - Scalable dynamic function bus

=head1 PECULIARITIES

=head2 UNUSABLE MODULE

This module is a skeleton for a larger module and the author 
is basically getting his enviroment setup, trying to remember 
howto get PODs nicely formatted and other bits and bobs, that 
is the only reason this module has been uploaded. 

This module should not be used by anyone in its current state.

=head2 VERSIONING

The author of this module has taken a rather strange approach 
to the versioning of the module, basically there the time the 
source code/package was packaged 'make dist'. 

=head1 VERSION

Version 1569954247

=cut

our $VERSION = '1569954247';

=head1 DESCRIPTION

The entire point of this module is to make a very fast/easy interface for 
attaching internal and even external functions to a common standardized 
serialization bus. (The serialization used is not enforced)

This module is the forerunner for an upcoming protocol that is in RFC, as the 
author of the same protocol I have decided to race ahead and make something 
from its fundamental core principles to solve some issues I have in the present.

=head2 WHY

Simply put you can publish functions over a common protocol (not neccesarily 
just in perl) and instead of them being controlled by any type of namespace, 
they are infact simply functions on a bus so for scalability of that expensive 
processing function, you can attach as many workers as like.

This does however mean that very large complex tasks should be split down into 
as small of a set of work functions as possible, so that they can be more easily 
distributed amongst multiple processes.

But no one writes large heavy monolthic 'evil' functions anymore, right?

=head2 CONSIDERATIONS

To be considering using this type of distributed work network you should also 
remember that it is rather dependant on code enacting postback type behaviour, 
rather than block-and-return. 

Not that you could not use block-and-return it would just well, be rather 
resource hungry and not very scalable. If you do have a_function() that takes
8 days to run, consider wrapping it in a service that responds that it is busy 
or so. That way you can have multiple nodes providing that service.

=head1 SYNOPSIS

Perhaps a little code snippet.

    use POE::Component::FunctionBus;

    my $options = {
    }

    my $node = POE::Component::FunctionBus->new($options); 

    $node->offer()


=head1 EXPORT

There are no exports for this module

=head1 METHODS

These are for instanciating connecting nodes 

=head2 new

Create a new connection object, by default this will act as both a server and 
client, it also by default binds 0.0.0.0/IPV4_ANY on port 10101(TCP) as well as
af_unix:/tmp/functionbus.PID.sock (PID here meaning the literal PID that perl 
is using)

=cut

sub new {
  my ($class,$options) = @_;

  my $self = bless {
      alias   => __PACKAGE__,
      session => 0,
  }, $class;

  $self->{session} = POE::Session->create(
    package_states => [
      $self => {
        _start          =>      '_start',
        _stop           =>      '_stop',
        _keep_alive     =>      '_keep_alive',
      }
    ],
    heap => {
      parent          => POE::Kernel->get_active_session()->ID
    }
  );

  $self->{id} = $self->{session}->ID;

  return $self;
}



=head1 OBJECT METHODS

=head2 Blocking

These are primarily functions that can be called on the resultant POE::Session 
returned from an initilizer (documented above), in the spirit of non blocking 
processing you should really use these as little as possible

=head3 somefunc

=cut

sub somefunc {
}

=head2 NON Blocking

These are binds to anonymous POE::Kernels that post into the primary session, 
as of such they do not return anything directly but some may allow callbacks.

=head3 network_id

Networks are generally dynamically created within the scope of a set of working 
nodes however this in its self is given a unique id, just incase there happens 
to be more than one network running.

This value can be set in the initilizer.



=head1 AUTHOR

Paul G Webster, C<< <daemon at cpan.org> >>

=head1 BUGS

We don't have these!

Incase we are wrong though report any bugs or feature requests to 
L<https://github.com/PaulGWebster/p5-POE-Component-FunctionBus/issues>.

I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc 
command.

    perldoc POE::Component::FunctionBus

You can also look for information at:

=over 4

=item * Github: Authors repository

L<https://github.com/PaulGWebster/p5-POE-Component-FunctionBus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-FunctionBus>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/POE-Component-FunctionBus>

=item * Search CPAN

L<https://metacpan.org/release/POE-Component-FunctionBus>

=back


=head1 ACKNOWLEDGEMENTS

=over 2

=item Rocco Caputo

Rocco Caputo is <rcaputo@cpan.org>.  POE is his brainchild.  He wishes
to thank you for your interest, and he has more thanks than he can
count for all the people who have contributed.  POE would not be
nearly as cool without you.

Except where otherwise noted, POE is Copyright 1998-2013 Rocco Caputo.
All rights reserved.  POE is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Paul G Webster.

This is free software, licensed under:

  The (three-clause) BSD License


=head1 DEVELOPER SECTION

This section is because this module is under heavy development, really its just 
notes to my self on what I am planning to do - examples and other bits and 
peices. (or total junk)

Anything in this section should never be reffered to as once this module hits 
release this section will vanish.

=head2 TODO

=head3 AF_UNIX local pools

make it so /var/functionbus.pid.sock (pid representing the master perl process)
is contactable

=head3 detailed protocol spec

Write down precisely what is required to talk on one of these networks so other
people have half a prayer of using it in other languages, maybe write a csharp
module? maybe kick python/java friends to do the same hmmm

=head2 functions

=head3 _start

Start a session and setup the initial enviroment

=cut 

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  # This is a hack because we do not trust alias.
  $kernel->yield('_keep_alive');
}

=head3 _stop

Called when the main POE::Session stops ... tidying up

=cut 

sub _stop {
  my ($kernel,$heap) = @_[KERNEL,HEAP];


}

=head3 _start

Start a session and setup the initial enviroment

=cut 

sub _keep_alive {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  warn "keepalive";
  $kernel->delay_add('_keep_alive' => 1);
}

1; # End of POE::Component::FunctionBus
