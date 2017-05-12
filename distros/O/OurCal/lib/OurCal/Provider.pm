package OurCal::Provider;

use strict;
use UNIVERSAL::require;
use Module::Pluggable sub_name    => '_providers',
                      search_path => 'OurCal::Provider';

=head1 NAME

OurCal::Provider - class for getting events and TODOs from the system

=head1 CONFIGURATION

Teh default provider is a Multi provider named C<providers>. This means 
that you can do

    [providers]
    providers=default birthday 

    [default]
    dsn=dbi:SQLite:ourcal
    type=dbi

    [birthday]
    file=birthday.ics
    type=icalendar

Alternatively you can specify another default provider using the 
provider config option

    provider=cache_everything

    [cache_everything]
    child=providers
    type=cache

    [providers]
    providers=default birthday 
    type=multi

    [default]
    dsn=dbi:SQLite:ourcal
    type=dbi

    [birthday]
    file=birthday.ics
    type=icalendar


Read individual providers for config options.

=head1 METHODS

=cut

=head2 new <param[s]>

Requires an C<OurCal::Config> object as config param.

Authomatically instantiates the default provider.

=cut


# TODO if the child of a cache is an icalendar provider 
# and the icalendar provider has the same cache a sa cache then there'll be
# a deep recursion. We should fix this somehow.
sub new {
    my $class = shift;
    my %what  = @_;

    # first work out what provider we're using
    my $conf     = $what{config};
    my @args ;
    my $name     = $conf->{_}->{provider};
    if (defined $name) {
        push @args, $name;
    } else {
        push @args, ("providers", $conf, type => "multi");
    }
    # then load it
    $what{_provider} = $class->load_provider(@args); 
    return bless \%what, $class;
}

=head2 providers

Returns a hash of all providers installed on the system as key-value 
pairs of the name of the provider and class it represents.

=cut

sub providers {
    my $self  = shift;
    my $class = (ref $self)? ref($self) : $self;

    my %providers;
    foreach my $provider ($self->_providers) {
        my $name = $provider;
        $name =~ s!^${class}::!!;
        $providers{lc($name)} = $provider;
    }
    return %providers;
}

=head2 load_provider <name>

Load a provider with a given name as defined in the config and returns 
it as an object.

=cut

sub load_provider {
    my $self  = shift;
    my $name  = shift;
    my $conf  = shift;  
    my %opts  = @_;
    my $pconf = $conf->config($name) || die "Don't know about provider $name\n";
    my $type  = $pconf->{type}       || $opts{type}  || die "Couldn't work out type for provider $name - you must provide a 'type' config\n"; 
    my %provs = $self->providers;
    my $class = $provs{lc($type)}    || die "Couldn't get a class for provider $name of type $type\n";
    $class->require || die "Couldn't require class $class: $@\n";
    return $class->new(config => $conf, name => $name);
}


=head2 todos

Returns all the todos on the system.

=cut 

sub todos {
    my $self = shift;
    return $self->_do_default('todos', @_);
}

=head2 has_events <param[s]>

Returns whether there are events given the params.

=cut

sub has_events {
    my $self = shift;
    return $self->_do_default('has_events', @_);
}

=head2 events <param[s]>

Returns all the events for the given params.

=cut

sub events {
    my $self   = shift;
    my %opts   = @_;
    my @events = sort { $b->date cmp $a->date } $self->_do_default('events', %opts);
    @events    = splice @events, 0, $opts{limit} if defined $opts{limit};
    return @events;
}

=head2 users

Returns the name of all the users on the system.

=cut

sub users {
    my $self = shift;
    return $self->_do_default('users', @_);
}

=head2 save_todo <OurCal::Todo>

Save a todo.

=cut

sub save_todo {
    my $self = shift;
    return $self->_do_default('save_todo', @_);
}

=head2 del_todo <OurCal::Todo>

Delete a todo.

=cut

sub del_todo {
    my $self = shift;
    return $self->_do_default('del_todo', @_);
}

=head2 save_event <OurCal::Event>

Save an event.

=cut

sub save_event {
    my $self = shift;
    return $self->_do_default('save_event', @_);
}

=head2 del_event <OurCal::Event>

Delete an event..

=cut

sub del_event {
    my $self = shift;
    return $self->_do_default('del_event', @_);
}

sub _do_default {
    my $self  = shift;
    my $sub   = shift;
    my $thing = shift;
    $self->{_provider}->$sub($thing, @_);
}
1;

