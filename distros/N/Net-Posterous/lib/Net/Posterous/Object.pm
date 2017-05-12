package Net::Posterous::Object;

use Class::Accessor "antlers";

=head1 NAME

Net::Posterous::Object - base class for Net::Posterous objects

=head1 METHODS

=cut

=head2 new

Basic constructor.

=cut
sub new {
    my $class = shift;
    my %opts  = @_;
    return bless \%opts, $class;
}

sub _handle_datetime {
    my $self = shift;
    # Make sure date is in RFC822 format e.g Sun, 03 May 2009 19:58:58 -0700
    $self->{_strp} ||= DateTime::Format::Strptime->new( pattern => "%a, %d %b %Y %H:%M:%S %z");

    $self->date($self->{_strp}->format_datetime(shift)) if @_;
    return $self->{_strp}->parse_datetime($self->date);
    
}

1;