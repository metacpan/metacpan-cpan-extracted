package RSS::Video::Google;

use strict;
use XML::Simple;

use RSS::Video::Google::Channel;

use constant GENERATOR   => q{RSS::Video::Google};
use constant OPEN_SEARCH => q{http://a9.com/-/spec/opensearchrss/1.0/};
use constant VERSION     => q{2.0};
use constant MEDIA       => q{http://search.yahoo.com/mrss};
use constant XMLDECL     => q{<?xml version="1.0"?>};

use constant ROUTINES => [qw(
	new_channel
	version
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

sub new_channel {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
		@args = %{$args[0]};
	}

        $self->channel(RSS::Video::Google::Channel->new(@args));
}

sub channel {
	my $self    = shift;
	my $channel = shift;
	if (defined $channel && ref $channel eq 'RSS::Video::Google::Channel') {
		$self->{channel} = $channel;
	}
	return $self->{channel};
}

sub version {
	my $self = shift;
	$self->{version} = shift if $_[0];
	return $self->{version} || VERSION;
}

sub xmldecl {
	my $self = shift;
	$self->{xmldecl} = shift if $_[0];
	return $self->{xmldecl} || XMLDECL;
}

sub hashref {
	my $self = shift;

	return {
		rss => [{
			channel => $self->channel->hashref,
			version            => $self->version,
			'xmlns:openSearch' => OPEN_SEARCH,
			'xmlns:media'      => MEDIA,
		}],
	};
}

sub xml {
	my $self = shift;

	my $xs = XML::Simple->new(
		forcearray => 1,
	);

	my $xml = $xs->XMLout(
	        $self->hashref,
        	rootname   => q{},
		xmldecl    => $self->xmldecl,
	);

	return $xml;
}

1;
__END__

=head1 NAME

RSS::Video::Google - Perl extension for generating RSS XML feeds similar to those produced by Google Video web site.

=head1 SYNOPSIS

  use RSS::Video::Google;
  my $video = RSS::Video::Google->new
  $video->new_channel(
      items_per_page => ITEMS_PER_PAGE,
      start_index    => $start_index + 1,
      total_results  => $total_results,
  );
  $video->channel->new_item(
      description => $item->description,
      title       => $item->title,
      new_media   => {
          new_content => {
              url      => $item->content_url,
              duration => $item->duration,
          },
              new_thumbnail => {
              url => $item->thumbnail_url,
          },
      },
  );
  print $video->xml;

=head1 DESCRIPTION

Produces XML RSS feeds similar to those return by google. 
http://video.google.com/videofeed?xxx

You might need something like this if you are writting software to interact
with the Google video server and need to test with your own data sets.

=head1 AUTHOR

Jeff B Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

XML::Simple

=cut
