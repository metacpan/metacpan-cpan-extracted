package OurCal;

use strict;
use OurCal::Day;
use OurCal::Month;
use OurCal::Provider;
use Data::Dumper;

our $VERSION = '1.2';

=head1 NAME

OurCal - a simple yet featureful personal calendaring system

=head1 SYNOPSIS

This is a example index.cgi

    my $config    = OurCal::Config->new( file => 'ourcal.conf' );
    my $handler   = OurCal::Handler->new( config => $config);
    my $cal       = OurCal->new( date => $handler->date, user => $handler->user, config => $config );
    my $view      = OurCal::View->load_view($handler->view, config => $config->config, calendar => $cal);

    print $handler->header($view->mime_type);
    print $view->handle($handler->mode);

=head2 DESCRIPTION

OurCal was written one hungover Sunday afternoon 5 years ago and hasn't 
changed that much since. It's not a complicated calendaring system, I've 
got other code to do that, but it's simple and extendable and it works.

Feature wise:

=over 4

=item simple events

OurCal has no concept of start or end times - an event is on a day or it 
isn't. Surprisingly this suffices 99% of my time and makes things much 
quicker and easier internally.

Events can be marked up using the Chump syntax which is kind of like 
Markdown but had the virtue of existing at the time. There's no real 
reason why Chump couldn't be ripped out and replaced with Markdown.

Events have a date and a description and that's pretty much it. If you 
want more feed me beer and choclate covered coffee beans until I get 
round to finishing EventQueue.

=item todos

OurCal has simple TODO items as well - these are also marked up in 
Chump.

=item icalendar

OurCal can import iCalendar feeds from both local and remote sources and 
can also export an ICS feed. Since it's all done with plugins (I loves 
me my plugins) you could write plugins to import and export whatever you 
want. 

=item multi user

Nominally OurCal is multi user but there's no user management to speak 
of and I only ever use it for one person so I wouldn't know. 

=item hCalendar

All events use hCalendar semantic markup because I'm nothing if not 
Buzzword Compatible.

=item mod_perl

There's no mod_perl or mod_perl handler at the moment but it'd be but a 
moments work to do. 

=back

=cut

=head1 METHODS


=head2 new <params>

Requires a C<config> param of type C<OurCal::Config> and a C<date> param 
in the form C<yyyy-mm> or C<yyyy-mm-dd>. Can optionally take a user 
param. No user validation is done. 

=cut

sub new {
    my $class     = shift;
    my %opts      = @_;
    $opts{provider} ||= OurCal::Provider->new(config => $opts{config});
    return bless \%opts, $class;
}

=head2 date

Return the current date

=cut

sub date {
    return $_[0]->{date};
}

=head2 user

Return the current user 

=cut

sub user {
    return $_[0]->{user};
}

=head2 span_name 

Return the current date as a span name (month or day)

=cut

sub span_name {
    my $self = shift;
    my $date = $self->date;
    if (10 == length($date)) {
        return 'day';
    } elsif (7 == length($date)) {
        return 'month';
    } elsif (4 == length($date)) {
        return 'year';
    } else {
        die "Unknown date type for $date\n";
    }
}

=head2 span

Return the current date as an object - either an C<OurCal::Month> or 
an C<OurCal::Day>).

=cut

sub span {
    my $self = shift;
    my $name = $self->span_name;
    my $date = $self->date;
    my %what = ( date => $date, calendar => $self );
    $what{user} = $self->{user} if defined $self->user;
    if ('month' eq $name) {
        return OurCal::Month->new(%what);
    } elsif ('day' eq $name) {
        return OurCal::Day->new(%what);
    } 

    die "Don't have a handler for $name\n";
}


=head2 events

Return the events for a current span as C<OurCal::Event> objects

=cut

sub events {
    my $self = shift;
    my %opts = @_;
    $opts{user} = $self->user if defined $self->user; 
    return $self->{provider}->events(%opts);
}

=head2 has_events

Return whether the current span has events

=cut

sub has_events {
    my $self = shift;
    my %opts = @_;
    $opts{user} = $self->user if defined $self->user; 
    return $self->{provider}->has_events(%opts);
}


=head2 todos

Return all the current todos as C<OurCal::Todo> objects.

=cut

sub todos {
    my $self = shift;
    my %opts = @_;
    $opts{user} = $self->user if defined $self->user; 
    return $self->{provider}->todos(%opts);
}

=head2 users

Returns the names of all the current users

=cut

sub users {
    my $self = shift;
    return $self->{provider}->users;
}

=head2 save_todo C<OurCal::Todo>

Save a TODO item

=cut

sub save_todo {
    my $self = shift;
    my $todo = shift;
    $self->{provider}->save_todo($todo)
}


=head2 del_todo C<OurCal::Todo>

Delete a TODO item

=cut

sub del_todo {
    my $self = shift;
    my $todo = shift;
    $self->{provider}->del_todo($todo);
}


=head2 save_event C<OurCal::Event>

Save an Event

=cut

sub save_event {
    my $self  = shift;
    my $event = shift;
    $self->{provider}->save_event($event);
}    

=head2 del_event C<OurCal::Event>

Delete an event

=cut

sub del_event {
    my $self  = shift;
    my $event = shift;
    $self->{provider}->del_event($event);
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Distributed under the same terms as Perl itself

=head1 SEE ALSO

L<OurCal::Provider>, L<OurCal::View>, L<OurCal::Handler>, L<OurCal::Config>

=cut

1;
