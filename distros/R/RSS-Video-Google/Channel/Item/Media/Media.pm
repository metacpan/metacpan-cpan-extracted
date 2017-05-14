package RSS::Video::Google::Channel::Item::Media;

use strict;
use RSS::Video::Google::Channel::Item::Media::Content;
use RSS::Video::Google::Channel::Item::Media::Player;
use RSS::Video::Google::Channel::Item::Media::Thumbnail;

use Data::Dumper;

use constant GENERATOR   => q{RSS::Video::Google};
use constant OPEN_SEARCH => q{http://a9.com/-/spec/opensearchrss/1.0/};
use constant VERSION     => q{2.0};
use constant MEDIA       => q{http://search.yahoo.com/mrss};
use constant XMLDECL     => q{<?xml version="1.0"?>};

use constant ROUTINES => [qw(
	new_content
	new_thumbnail
	content
	title
	description
	player
	thumbnail
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

sub new_content {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        $self->content(RSS::Video::Google::Channel::Item::Media::Content->new(@args));
}

sub content {
	my $self = shift;
	$self->{content} = shift if $_[0];
	return $self->{content} || $self->new_content;
}

sub new_player {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        $self->player(RSS::Video::Google::Channel::Item::Media::Player->new(@args));
}

sub player {
	my $self = shift;
	$self->{player} = shift if $_[0];
	return $self->{player} || $self->new_player;
}

sub new_thumbnail {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        $self->thumbnail(RSS::Video::Google::Channel::Item::Media::Thumbnail->new(@args));
}

sub thumbnail {
	my $self = shift;
	$self->{thumbnail} = shift if $_[0];
	return $self->{thumbnail} || $self->new_thumbnail;
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

sub pubdate {
	my $self = shift;
	$self->{pubdate} = shift if $_[0];
	return $self->{pubdate} || '';
}

sub hashref {
	my $self = shift;
	return {
		'media:description' => [ $self->description ],
		'media:title'       => [ $self->title ],
		'media:content'     => [ $self->content->hashref ],
		'media:player'      => [ $self->player->hashref ],
		'media:thumbnail'   => [ $self->thumbnail->hashref ],
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel::Item::Media

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
