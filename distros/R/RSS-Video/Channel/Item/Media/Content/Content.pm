package RSS::Video::Google::Channel::Item::Media::Content;

use strict;
use Data::Dumper;

use constant HEIGHT     => 240;
use constant WIDTH      => 320;
use constant TYPE       => q{video/x-flv};
use constant EXPRESSION => q{full};
use constant MEDIUM     => q{video};

use constant ROUTINES => [qw(
	url
	height
	expression
	width
	type
	duration
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

sub expression {
	my $self = shift;
	$self->{expression} = shift if $_[0];
	return $self->{expression} || EXPRESSION;
}

sub width {
	my $self = shift;
	$self->{width} = shift if $_[0];
	return $self->{width} || WIDTH;
}

sub medium {
	my $self = shift;
	$self->{medium} = shift if $_[0];
	return $self->{medium} || MEDIUM;
}

sub type {
	my $self = shift;
	$self->{type} = shift if $_[0];
	return $self->{type} || TYPE;
}

sub duration {
	my $self = shift;
	$self->{duration} = shift if $_[0];
	return $self->{duration} || '';
}

sub hashref {
	my $self = shift;
	return {
		url        => $self->url,
		height     => $self->height,
		expression => $self->expression,
		width      => $self->width,
		medium     => $self->medium,
		type       => $self->type,
		duration   => $self->duration,
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel::Item::Media::Content

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
