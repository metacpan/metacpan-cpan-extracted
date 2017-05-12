package Net::MythWeb;
use Moose;
use MooseX::StrictConstructor;
use DateTime;
use DateTime::Format::Strptime;
use HTML::TreeBuilder::XPath;
use Net::MythWeb::Channel;
use Net::MythWeb::Programme;
use URI::URL;
use WWW::Mechanize;

our $VERSION = '0.33';

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'localhost',
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => 80,
);

has 'mechanize' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
        my $ua = WWW::Mechanize->new;
        $ua->default_header( 'Accept-Language' => 'en' );
        return $ua;
    },
);

__PACKAGE__->meta->make_immutable;

sub channels {
    my $self = shift;
    my @channels;

    my $response = $self->_request('/mythweb/settings/tv/channels');
    my $tree     = HTML::TreeBuilder::XPath->new;
    $tree->parse_content( $response->decoded_content );

    foreach
        my $tr ( $tree->findnodes('//tr[@class="settings"]')->get_nodelist )
    {
        my @tr_parts     = $tr->content_list;
        my $number_input = ( $tr_parts[3]->content_list )[0];
        my $id           = $number_input->attr('id');
        $id =~ s/^channum_//;
        my $number     = $number_input->attr('value');
        my $name_input = ( $tr_parts[4]->content_list )[0];
        my $name       = $name_input->attr('value');
        push @channels,
            Net::MythWeb::Channel->new(
            id     => $id,
            number => $number,
            name   => $name,
            );
    }
    return @channels;
}

sub recordings {
    my $self = shift;

    my @recordings;

    my $response = $self->_request('/mythweb/tv/recorded');

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content( $response->decoded_content );

    foreach
        my $row ( $tree->findnodes('//tr[@class="recorded"]')->get_nodelist )
    {
        next unless $row->attr('id') =~ /inforow_/;
        next if $row->as_HTML =~ /Still Recording/;

        my %seen;
        foreach my $link ( $tree->findnodes( '//a', $row )->get_nodelist ) {
            my $href = $link->attr('href');
            next unless $href;
            next unless $href =~ m{/detail/};
            next if $seen{$href}++;
            push @recordings, $self->_programme($href);
        }
    }
    return @recordings;
}

sub programme {
    my ( $self, $channel, $start ) = @_;
    my $channel_id  = $channel->id;
    my $start_epoch = $start->epoch;
    return $self->_programme("/mythweb/tv/detail/$channel_id/$start_epoch");
}

sub _programme {
    my ( $self, $path ) = @_;
    my $response = $self->_request($path);

    my ( $channel_id, $programme_id ) = $path =~ m{(\d+)/(\d+)};

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content( $response->decoded_content );

    my @channel_parts
        = $tree->findnodes('//td[@class="x-channel"]/a')->pop->content_list;
    my $channel_number = $channel_parts[3]->content->[0];
    my $channel_name   = $channel_parts[5];
    $channel_name =~ s/^ +//;
    $channel_name =~ s/ +$//;

    my $channel = Net::MythWeb::Channel->new(
        id     => $channel_id,
        number => $channel_number,
        name   => $channel_name
    );

    my @title_parts
        = $tree->findnodes('//td[id("x-title")]/a')->pop->content_list;
    my $title = $title_parts[0];
    my $subtitle = $title_parts[2] || '';

    my $year = DateTime->from_epoch( epoch => $programme_id )->year;

    my $strptime = DateTime::Format::Strptime->new(
        pattern  => '%Y %a, %b %d, %I:%M %p',
        locale   => 'en_GB',
        on_error => 'croak',
    );

    # Sun, Jun 14, 10:00 PM to 11:00 PM (75 mins)
    my @time_parts
        = $tree->findnodes('//div[id("x-time")]')->pop->content_list;
    my $time_text = $time_parts[0];
    my ( $start_text, $stop_text ) = split ' to ', $time_text;
    $start_text = "$year $start_text";
    my $start = $strptime->parse_datetime($start_text);

    $stop_text =~ s/ \(.+$//;
    my $strptime2 = DateTime::Format::Strptime->new(
        pattern  => '%I:%M %p',
        locale   => 'en_GB',
        on_error => 'croak',
    );
    my $time = $strptime2->parse_datetime($stop_text);
    my $stop = DateTime->new(
        year   => $start->year,
        month  => $start->month,
        day    => $start->day,
        hour   => $time->hour,
        minute => $time->minute,
    );

    # programme runs over midnight
    if ( $stop < $start ) {
        $stop->add( days => 1 );
    }

    my @description_parts
        = $tree->findnodes('//td[id("x-description")]')->pop->content_list;
    my $description = $description_parts[0];
    $description =~ s/^ +//;
    $description =~ s/ +$//;

    return Net::MythWeb::Programme->new(
        id          => $programme_id,
        channel     => $channel,
        start       => $start,
        stop        => $stop,
        title       => $title,
        subtitle    => $subtitle,
        description => $description,
        mythweb     => $self,
    );
}

sub _download_programme {
    my ( $self, $programme, $filename ) = @_;
    my $uri
        = $self->_uri( '/mythweb/pl/stream/'
            . $programme->channel->id . '/'
            . $programme->id );
    my $mirror_response
        = $self->mechanize->get( $uri, ':content_file' => $filename );
    confess( $mirror_response->status_line )
        unless $mirror_response->is_success;
}

sub _delete_programme {
    my ( $self, $programme ) = @_;

    $self->_request( '/mythweb/tv/recorded?delete=yes&chanid='
            . $programme->channel->id
            . '&starttime='
            . $programme->id );
}

sub _record_programme {
    my ( $self, $programme, $start_extra, $stop_extra ) = @_;
    $start_extra ||= 0;
    $stop_extra  ||= 0;
    my $channel_id   = $programme->channel->id;
    my $programme_id = $programme->id;

    $self->_request("/mythweb/tv/detail/$channel_id/$programme_id");
    $self->mechanize->submit_form(
        form_name => 'program_detail',
        fields    => {
            record      => 1,
            startoffset => $start_extra,
            endoffset   => $stop_extra,
        },
        button => 'save',
    );
}

sub _request {
    my ( $self, $path ) = @_;
    my $uri = $self->_uri($path);

    my $response = $self->mechanize->get($uri);
    confess( "Error fetching $uri: " . $response->status_line )
        unless $response->is_success;

    return $response;
}

sub _uri {
    my ( $self, $path ) = @_;
    return 'http://' . $self->hostname . ':' . $self->port . $path;
}

__END__

=head1 NAME

Net::MythWeb - Interface to MythTV via MythWeb

=head1 SYNOPSIS

  use Net::MythWeb;

  my $mythweb = Net::MythWeb->new( hostname => 'owl.local', port => 80 );

  foreach my $channel ( $mythweb->channels ) {
      print $channel->name . "\n";
  }

  foreach my $recording ( $mythweb->recordings ) {
    print $recording->channel->id, ', ', $recording->channel->number, ', ',
        $recording->channel->name, "\n";
    print $recording->start, ' -> ', $recording->stop, ': ', $recording->title,
        ', ',
        $recording->subtitle, ', ',
        $recording->description;
        $recording->download("recording.mpg");
        $recording->delete;
   }

   my $programme = $mythweb->programme( $channel, $start_as_datetime );
   $programme->record;

=head1 DESCRIPTION

This module provides a simple interface to MythTV by making HTTP
requests to its MythWeb web server front end. MythTV is a free
open source digital video recorder. Find out more at
L<http://www.mythtv.org/>.

This module allows you to query the recordings, download
them to a local file and schedule new recordings.

=head1 METHODS

=head2 new

The constructor takes a hostname and port:

  my $mythweb = Net::MythWeb->new( hostname => 'owl.local', port => 80 );

=head2 channels

List the channels and return them as L<Net::MythWeb::Channel> objects:

  foreach my $channel ( $mythweb->channels ) {
      print $channel->name . "\n";
  }

=head2 recordings

List the recordings and return them as L<Net::MythWeb::Programme> objects:

  foreach my $recording ( $mythweb->recordings ) {
    print $recording->channel->id, ', ', $recording->channel->number, ', ',
        $recording->channel->name, "\n";
    print $recording->start, ' -> ', $recording->stop, ': ', $recording->title,
        ', ',
        $recording->subtitle, ', ',
        $recording->description;
        $recording->download("recording.mpg");
        $recording->delete;
   }

=head2 programme

Returns a L<Net::MythWeb::Programme> for the programme which starts
at a given time on the channel:

   my $programme = $mythweb->programme( $channel, $start_as_datetime );
   $programme->record;

=head1 SEE ALSO

L<Net::MythWeb::Channel>, L<Net::MythWeb::Programme>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
