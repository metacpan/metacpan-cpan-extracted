package OurCal::Provider::ICalendar;

use strict;
use LWP::Simple;
use Data::ICal::DateTime;
use DateTime;
use DateTime::Span;
use File::Spec;
use OurCal::Event;
use OurCal::Provider;
use Carp qw(cluck);
use Digest::MD5 qw(md5_hex);


=head1 NAME

OurCal::Provider::ICalendar - an RFC2445 provider for OurCal

=head1 SYNOPSIS

    [an_ical_provider
    type = icalendar
    file = path/to/file.ics

=head1 CONFIG OPTIONS

=over 4 

=item file

The ics file. Can either be a local file or a url of one.

=item cache

The name of a cache provider. This will cache fetching the file.

=back

=head1 METHODS

=cut

=head2 new <param[s]>

Requires an C<OurCal::Config> object as config param and a name param. 

=cut


sub new {
    my $class = shift;
    my %what  = @_;
    my $conf  = $what{config}->config($what{name});
    my $file  = $conf->{file};
    if ($file !~ m!^http://!) {
        $file = File::Spec->rel2abs($file);
        $file = "file://$file";
    }
    $what{file}   = $file;
    if ($conf->{cache}) {
        $what{_cache} = OurCal::Provider->load_provider($conf->{cache}, $what{config}); 
    }

    return bless \%what, $class;
}

sub users {
    return ();
}

sub todos {
    return ();
}

sub events {
    my $self  = shift;
    my %opts  = @_;
    my $data  = $self->_fetch_data;
    return () unless $data;
    my $cal   = Data::ICal->new( data => $data );
    return () unless $cal;
    my @vals;
    if (defined $opts{date}) {
        my @names = qw(year month day);
        my @bits  = split /-/, $opts{date};
        my %conf;
        foreach my $bit (@bits) {
            my $name = shift @names;
            last unless $name;
            $conf{$name} = $bit;
        }
        my $s    = DateTime->new(%conf)->truncate( to => 'day');
        my $e    = $s->clone->add( days => 1)->subtract( seconds => 1 );
        my $span = DateTime::Span->from_datetimes( start => $s, end => $e );
        push @vals, $span, 'day';
    }
    
    my @events  = $cal->events(@vals);
    @events     = map { $_->explode(@vals) } @events if @vals;
    @events     = sort { $a->start->epoch <=> $b->start->epoch } @events;
    @events     = splice @events, 0, $opts{limit} if defined $opts{limit};
    return map { $self->_to_event($_) } @events;
}


sub _fetch_data {
    my $self = shift;
    return get($self->{file}) unless defined $self->{_cache};
    my $file = $self->{name}."@".md5_hex($self->{file});    
    return ($self->{_cache}->cache( $file, sub { get($self->{file}) }))[0];    
}

sub _to_event {
    my $self  = shift;
    my $event = shift;
    my %what;
    $what{id}          = $event->property('id');
    $what{date}        = $event->start->strftime("%Y-%m-%d");
    $what{description} = $event->summary;    
    $what{recurring}   = $event->property('rrule') or $event->property('rdate'); 
    $what{editable}    = 0;
    return OurCal::Event->new(%what);
}

sub has_events {
    my $self  = shift;
    return scalar($self->events(@_));
}

sub save_event {
    return 0;
}

sub del_event {
    return 0;
}

sub save_todo {
    return 0;
}

sub del_todo {
    return 0;
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

