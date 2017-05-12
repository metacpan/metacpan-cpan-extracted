package OurCal::Provider::Multi;

use strict;
use OurCal::Provider;


=head1 NAME

OurCal::Provider::Multi - aggregate multiple providers

=head1 SYNOPSIS

    [a_multi_provider]
    providers = something another 
    type      = multi

=head1 CONFIG OPTIONS

=over 3 

=item providers

A space separated list of other provider names

=back

=head1 METHODS

=cut

=head2 new <param[s]>

Requires an C<OurCal::Config> object as config param and a name param.

=cut

sub new {
    my $class = shift;
    my %what  = @_;

    # get all the names of of our providers
    my $conf      = $what{config}->config($what{name});
    my $providers = $conf->{providers};
    my $default   = 0;
    foreach my $provider (split ' ', $providers) {
        $what{_providers}->{$provider} = OurCal::Provider->load_provider($provider, $what{config});        
        $default = 1 if $provider eq 'default';
    }
    return bless \%what, $class;
}

sub todos {
    my $self = shift;
    return $self->_gather('todos');
}

sub providers {
    my $self = shift;
    return values %{$self->{_providers}};
}

sub has_events {
    my $self = shift;
    my %opts = @_;
    foreach my $provider ($self->providers) {
        return 1 if $provider->has_events(%opts);
    }
    return 0;
}

sub events {
    my $self   = shift;
    my %opts   = @_;
    my @events = sort { $b->date cmp $a->date } $self->_gather('events', %opts);
    @events    = splice @events, 0, $opts{limit} if defined $opts{limit};
    return @events;
}

sub users {
    my $self = shift;
    return $self->_gather('users', @_);
}

sub _gather {
    my $self = shift;
    my $sub  = shift;
    my %opts = @_;

    my @vals;
    foreach my $provider ($self->providers) {
        push @vals, $provider->$sub(%opts);
    }
    return @vals;

}

sub save_todo {
    my $self = shift;
    return $self->_do_default('save_todo', @_);
}

sub del_todo {
    my $self = shift;
    return $self->_do_default('del_todo', @_);
}


sub save_event {
    my $self = shift;
    return $self->_do_default('save_event', @_);
}

sub del_event {
    my $self = shift;
    return $self->_do_default('del_event', @_);
}

sub _do_default {
    my $self  = shift;
    my $sub   = shift;
    my $thing = shift;
    die "You must specify at least one provider named 'default' if you want to save\n" 
        unless $self->{_providers}->{default};
    $self->{_providers}->{default}->$sub($thing);
}

=head2 todos

Returns all the todos on the system.

=head2 has_events <param[s]>

Returns whether there are events given the params.

=head2 events <param[s]>

Returns all the events for the given params.

=head2 users

Returns the name of all the users on the system.

=head2 save_todo <OurCal::Todo>

Save a todo.

=head2 del_todo <OurCal::Todo>

Delete a todo.


=head2 save_event <OurCal::Event>

Save an event.

=head2 del_event <OurCal::Event>

Delete an event..

=cut



1;

