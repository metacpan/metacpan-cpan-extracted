package RSS::Video::Google::Channel::Item::Media::Thumbnail;

use strict;
use Data::Dumper;

use constant HEIGHT     => 240;
use constant WIDTH      => 320;

use constant ROUTINES => [qw(
	url
	height
	width
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
	return $self->{url} || '';
}

sub height {
	my $self = shift;
	$self->{height} = shift if $_[0];
	return $self->{height} || HEIGHT;
}

sub width {
	my $self = shift;
	$self->{width} = shift if $_[0];
	return $self->{width} || WIDTH;
}

sub hashref {
	my $self = shift;
	return {
		url        => $self->url,
		height     => $self->height,
		width      => $self->width,
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel::Item::Media::Thumbnail

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
