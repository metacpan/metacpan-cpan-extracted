package RSS::Video::Google::Channel::Item;

use strict;
use Data::Dumper;

use RSS::Video::Google::Channel::Item::Media;
use RSS::Video::Google::Channel::Item::Enclosure;

use constant GENERATOR   => q{RSS::Video::Google};
use constant OPEN_SEARCH => q{http://a9.com/-/spec/opensearchrss/1.0/};
use constant VERSION     => q{2.0};
use constant MEDIA       => q{http://search.yahoo.com/mrss};
use constant XMLDECL     => q{<?xml version="1.0"?>};

use constant ROUTINES => [qw(
	new_media
	new_enclosure
	description
	title
	author
	media
	pubdate
	guid
	enclosures
	link
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

sub new_media {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        $self->media(RSS::Video::Google::Channel::Item::Media->new(@args));
}

sub media {
	my $self = shift;
	$self->{media} = shift if $_[0];
	return $self->{media} || $self->new_media;
}

sub new_enclosure {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        $self->enclosure(RSS::Video::Google::Channel::Item::Enclosure->new(@args));
}

sub enclosure {
	my $self = shift;
	$self->{enclosure} = shift if $_[0];
	return $self->{enclosure} || $self->new_enclosure;
}

sub description {
	my $self = shift;
	$self->{description} = shift if $_[0];
	return $self->{description} || '';
}

sub title {
	my $self = shift;
	$self->{title} = shift if $_[0];
	return $self->{title} || '';
}

sub author {
	my $self = shift;
	$self->{author} = shift if $_[0];
	return $self->{author} || '';
}

sub pubdate {
	my $self = shift;
	$self->{pubdate} = shift if $_[0];
	return $self->{pubdate} || '';
}

sub guid {
	my $self = shift;
	$self->{guid} = shift if $_[0];
	return $self->{guid} || '';
}

sub link {
	my $self = shift;
	$self->{link} = shift if $_[0];
	return $self->{link} || '';
}

sub hashref {
	my $self = shift;
	return {
		description   => [ $self->description ],
		title         => [ $self->title ],
		author        => [ $self->author ],
		'media:group' => [ $self->media->hashref ],
		pubdate       => [ $self->pubdate ],
		guid          => [ $self->guid ],
		enclosure     => [ $self->enclosure->hashref ],
		link          => [ $self->link ],
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google - Perl extension for blah blah blah

=head1 SYNOPSIS

  use RSS::Video::Google::Channel::Item;

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS:Video::Google

=cut
