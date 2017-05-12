package RSS::Video::Google::Channel::Item::Enclosure;

use strict;
use XML::Simple;

use constant TYPE => q{video/mp4};

use constant ROUTINES => [qw(
	url
	type
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

sub type {
	my $self = shift;
	$self->{type} = shift if $_[0];
	return $self->{type} || TYPE;
}

sub hashref {
	my $self = shift;
	return {
		url  => $self->url,
		type => $self->type,
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel::Item::Enclosure

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
