package OurCal::Event;


use strict;

=head1 NAME

OurCal::Event - an event class for OurCal

=head1 METHODS

=head2 new <param[s]>

Requires a description and a date (in C<yyyy-mm-dd> form.                

Can also take id, recurring (boolean) and editable (boolean) params.
        
=cut

sub new {
    my ($class, %event) = @_;
    return bless \%event, $class;   
}

=head2 description 

The description of the event

=cut
                
sub description {
    my $self = shift;
    return $self->_trim($self->{description});
}
      

=head2 date 

The date of the event in C<yyy-mm-dd> form.

=cut
   
sub date {
	my $self = shift;
	return $self->{date};
}

=head2 id

The id of the event (may return undef).

=cut
                
sub id {
    my $self = shift;
    return $self->{id};
}

=head2 recurring

Is the event recurring

=cut

sub recurring {
    my $self = shift;
    return $self->{recurring} || 0;
}

=head2 editable

Is this event editable.

=cut

sub editable {
    my $self = shift;
    return $self->{editable} || 0;
}


sub _trim {
    my($self, $text) = @_;
    $text =~ s/^\s*(.+=?)\$/$1/;
    return $text;
}

1;

