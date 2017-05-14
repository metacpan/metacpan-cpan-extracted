package RSS::Video::Google::Channel::Item::Media::Player;

use strict;

use constant PLAYER_URL => q{http://www.google.com};

use constant ROUTINES => [qw(
	url
)];

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my %args  = @_;
	my $self = bless {}, $class;
        foreach my $routine (keys %args) {
		if (grep(/^$routine$/, @{&ROUTINES})) {
			$self->$routine($args{$routine});
		}
	}
	return $self;
}


sub url {
	my $self = shift;
	$self->{url} = shift if $_[0];
	return $self->{url} || PLAYER_URL;
}

sub hashref {
	my $self = shift;
	return {
		url => $self->url,
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel::Item::Media::Player

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
