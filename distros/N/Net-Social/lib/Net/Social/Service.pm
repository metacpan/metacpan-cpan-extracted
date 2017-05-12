package Net::Social::Service;

use strict;

=head1 NAME

Net::Social::Service - the base package for all the Net::Social plugins

=head1 METHODS

    my $service = Net::Social->service('LiveJournal');

or

    my $service = Net::Social::Service::LiveJournal->new;


Get the params needed

    my %params = Net::Social::Service::LiveJournal->params;

or
    my %params = $service->params;

    for my $what (qw(read write)) {
        print "Can $what\n" if $params{$what};
    }

    # list what keys are needed to login    
    foreach my $key (keys %$params{read}) {
        print "$key: ".$params{read}->{$key}."\n";
    }
    
then

    $service->login(%params); 

    foreach my $friend ($service->friends) {
        print "$friend->{name} $friend->{type}\n";
    }


    $service->add_friend("frank");
    $service->remove_friend("frank");
    

=cut

=head2 new 

Create a new Service

=cut 

sub new {
    my $class  = shift;
    return bless { _logged_in => 0 }, $class;
}

=head2 params

What fields are needed to log in to this service.

This will return a hash ref, the keys of which will
be either C<read> or C<write> or one of each. If you log in
using the C<write> params you will also be able to read.

Each of those will, in turn, be a hash ref the keys of which described 
what is needed. In turn I<their> values will be another hash ref which 
can contain the fields

=over 4

=item description.

Always present. A description of the field.

=item required

Defaults to 0. Dictates whether this field is required or optional.

=item sensitive

Defaults to 0. Whether or not this field is sensitive or not.

By sensitive we mean that it compromises the user's account. 
Examples of this might be, say, a password as opposed to a 
authorisation token.

This is a bit of a judgment call, to be honest.

=cut

sub params {
    my $class = shift;
    return ();
}


=head2 login <params>

Login in to this site. 

=cut

sub login {
    my $self  = shift;
    my %params = @_;

    my %keys = $self->params;
    foreach my $p (keys %keys) {
        return undef if $keys{$p}->{required} && !exists $params{$p};
    }
    $self->{_logged_in} = 1;
    $self->{_details}   = \%params;
    return 1;
}


=head2 friends

All your friends on the site.

The friends will be return as a list of hash refs.

The hash refs will contain various fields depending 
on the service returning the data such as C<name> (the 
person's full name), C<uid> (the uid on the service), 
C<username> (a username on the service, may be the same 
as  uid). However each one will definitely contain C<type>
which will be one of 4 values, defined as constants in 
C<Net::Social>.

=over4

=item NONE

There's no defined relationship between the two of you.

=item FRIENDED

You've friended them but they haven't friended you.

=item FRIENDED_BY

They've friended you but you haven't friended them.

=item MUTUAL

You've both friended each other. C<MUTUAL> is defined as

    MUTUAL = FRIENDED | FRIENDED_BY

=back

In the future I may make all services return a C<key> field or 
similar which will be the field needed for adding or deleting.

=cut

sub friends {
    my $self  =    shift;
    return ();
}

=head2 add_friend <username>

Add a friend. 

=cut

sub add_friend { }


=head2 remove_friend <username>

Remove a friend.

=cut

sub remove_friend { } 

1;
