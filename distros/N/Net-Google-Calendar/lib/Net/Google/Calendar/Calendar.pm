package Net::Google::Calendar::Calendar;
{
  $Net::Google::Calendar::Calendar::VERSION = '1.05';
}

use base qw(Net::Google::Calendar::Entry);

=head1 NAME

Net::Google::Calendar::Calendar - entry class for Net::Google::Calendar Calendar objects

=head1 METHODS 

Note this is very rough at the moment - there are plenty of
convenience methods that could be added but for now you'll
have to access them using the underlying C<XML::Atom::Entry>
object.

=head2 new 

=cut

sub new {
    my ($class, %opts) = @_;

    my $self  = $class->SUPER::new( Version => '1.0', %opts );
    $self->_initialize();
    return $self;
}

sub _initialize {
    my $self = shift;

    $self->{_gd_ns}   = XML::Atom::Namespace->new(gd => 'http://schemas.google.com/g/2005');
    $self->{_gcal_ns} = XML::Atom::Namespace->new(gCal => 'http://schemas.google.com/gCal/2005');
}

=head2 summary [value]

A summary of the calendar.

=cut 

sub summary {
    my $self= shift;
    if (@_) {
        $self->set($self->ns, 'summary', shift);
    }
    return $self->get($self->ns, 'summary');
}


=head2 edit_url

Get the edit url

=cut

sub edit_url {
    my $self  = shift;
    my $force = shift || 0;
    my $url   = $self->_generic_url('edit');

    $url      =~ s!/allcalendars/full!/owncalendars/full! if $force;
    return $url;
}

=head2 color

The color assigned to the calendar.

=cut

sub color {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:color')->[0]) {
        return $el->getAttribute('value');
    }
    return;
}

=head2 override_name

Returns the override name of the calendar.  Not always set.

=cut

sub override_name {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:overridename')->[0]) {
        return $el->getAttribute('value');
    }
    return;
}

=head2 access_level

Returns the access level of the calendar.

=cut

sub access_level {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:accesslevel')->[0]) {
        return $el->getAttribute('value');
    }
    return;
}

=head2 hidden

Returns true if the calendar is hidden, false otherwise

=cut

sub hidden {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:hidden')->[0]) {
        if ($el->getAttribute('value') eq 'true') {
            return 1;
        }
    }
    return 0;
}


=head2 selected

Returns true if the calendar is selected, false otherwise.

=cut

sub selected {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:selected')->[0]) {
        if ($el->getAttribute('value') eq 'true') {
            return 1;
        }
    }
    return 0;
}

=head2 time_zone

Returns the time zone of the calendar.

=cut

sub time_zone {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:timezone')->[0]) {
        return $el->getAttribute('value');
    }
    return;
}



=head2 times_cleaned

Returns the value of timesCleaned

=cut

sub times_cleaned {
    my $self = shift;
    if (@_) {}
    if (my $el = $self->elem->getChildrenByTagName('gCal:timesCleaned')->[0]) {
        return $el->getAttribute('value');
    }
    return;
}

1;
