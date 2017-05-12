package Net::Google::Calendar::Person;
{
  $Net::Google::Calendar::Person::VERSION = '1.05';
}

use strict;
use XML::Atom::Person;
use base qw(XML::Atom::Person Net::Google::Calendar::Base);

my %allowed = (
    attendeeStatus => [qw(accepted declined invited tentative)],
    attendeeType   => [qw(optional required)],
    rel            => [qw(attendee organizer performer speaker)],

);

=head1 NAME

Net::Google::Calendar::Person - a thin wrapper round XML::Atom::Person

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my %opts  = @_; 
    $opts{Version} = '1.0' unless exists $opts{Version};
    my $self = $class->SUPER::new(%opts);
    $self->_initialize();
    return $self;
}


=head2 name [name]

A simple string value that can be used as a representation of this person.

=cut 

sub name {
    my $self = shift;
    return $self->_do('@valueString', @_);
}

=head2 email [email]

Get or set the email of the person

=cut

sub email {
    my $self = shift;
    $self->_do('@email', @_);
}

=head2 attendee_status [status]

Get or set the status of event attendee.

See:

    http://code.google.com/apis/gdata/elements.html#gdAttendeeStatus

Takes or returns any of the values C<accepted>, C<declined>, C<invited>, C<tentative>.

=cut

sub attendee_status {
    my $self = shift;
    $self->_do('attendeeStatus', @_);
}

=head2 attendee_type [type]

Get or set the type of event attendee.

See:

    http://code.google.com/apis/gdata/elements.html#gdAttendeeType

Takes or returns any of the values C<optional>, C<required>.

=cut

sub attendee_type {
    my $self = shift;
    $self->_do('attendeeType', @_);
}


=head2 rel [relationship]

=cut

sub rel {
    my $self = shift;
    $self->_do('@rel', @_);
}


sub _do {
    my $self = shift;
    my $name = shift;
    my $attr = ($name =~ s!^@!!);
    $name =~ s!^gd:!!;
    my $vals = $allowed{$name};
    my $gd_ns = ''; # $self->{_gd_ns};
        
    my $ns =  (defined $vals)? "http://schemas.google.com/g/2005#event." : "";
    if (@_) {
        my $new = shift;
        $new =~ s!^$ns!!;
        die "$new is not one of the allowed values for $name (".join(",", @$vals).")"
            unless !defined $vals || grep { $new eq $_ } @$vals;
        if ($attr) {
            #print "Setting attr $name to ${ns}${new}\n";
            $self->set_attr($name, "${ns}${new}");
        } else {
            #print "Setting child gd:$name to ${ns}${new}\n";
            $self->set($gd_ns, "gd:${name}", '', { value => "${ns}${new}" });
        }
    }
    my $val;
    if ($attr) {
        $val = $self->get_attr($name);
    } else {
        my $tmp = $self->_my_get($gd_ns, "gd:${name}");
        if (defined $tmp) {
            $val = $tmp->getAttribute('value');
        }
        # else { print "Failed to get gd:${name}\n"; }
    }
    $val =~ s!^$ns!! if defined $val;
    return $val;
}
1;
