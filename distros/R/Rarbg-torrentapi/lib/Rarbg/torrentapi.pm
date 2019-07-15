package Rarbg::torrentapi;

use strict;
use 5.008_005;
our $VERSION = 'v0.1.9';
use LWP::UserAgent;
use JSON;
use Carp;
use Rarbg::torrentapi::Res;
use Rarbg::torrentapi::Error;
use Moose;

our $BASEURL = 'https://torrentapi.org/pubapi_v2.php?';
our $REQUEST_LIMIT = 2; # The api has a 1req/2s limit.

has [qw(search_string search_imdb search_themoviedb search_tvdb category)] => (
    is  => 'rw',
    isa => 'Str'
);

has limit => (
    is      => 'rw',
    isa     => 'Int',
    default => 25
);

has sort => (
    is      => 'rw',
    isa     => 'Str',
    default => 'last'
);

has [qw(min_seeders min_leechers)] => (
    is  => 'rw',
    isa => 'Int'
);

has ranked => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has mode => (
    is      => 'rw',
    isa     => 'Str',
    default => 'list'
);

has app_id => (
    is      => 'rw',
    isa     => 'Str',
    default => 'p5-Rarbg-torrentapi'
);

has _format => (
    is      => 'ro',
    isa     => 'Str',
    default => 'json_extended'
);

has _ua => (
    is      => 'ro',
    default => sub {
        LWP::UserAgent->new( agent => 'curl/7.44.0' );
    }
);

has _token => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        $self->_renew_token();
    },
    required => 1,
    lazy     => 1
);

has _token_time => (
    is      => 'rw',
    isa     => 'Int',
    default => -1,
);

has _last_request => (
    is      => 'rw',
    isa     => 'Int',
    default => -1
);

sub _renew_token {
    my $self = shift;
    $self->_last_request(time);
    my $url  = $BASEURL . "get_token=get_token&app_id=" . $self->app_id;
    my $res_json = $self->_ua->get($url);
    if ( $res_json->is_success ) {
        $self->_token_time(time);
        my $res = decode_json( $res_json->decoded_content );
        return $res->{token};
    }
    else {
        confess "Cannot get token " . $res_json->status_line;
    }
}

sub _token_valid {
    my $self = shift;
    ( time - $self->_token_time ) < 890;
}

sub _make_request {
    my $self = shift;
    sleep $REQUEST_LIMIT if $self->_last_request != -1 && time - $self->_last_request < $REQUEST_LIMIT;
    unless ( $self->_token_valid ) {
        $self->_token( $self->_renew_token );
        sleep $REQUEST_LIMIT;
    }
    $self->_last_request(time);
    my $url = $BASEURL;
    foreach my $attribute ( $self->meta->get_attribute_list ) {
        next if $attribute =~ /^_/;
        if ( $self->$attribute ) {
            $url .= "$attribute=" . $self->$attribute . "&";
        }
    }
    $url .= "format=" . $self->_format . "&";
    $url .= "ranked=" . $self->ranked . "&";
    $url .= "token=" . $self->_token;
    my $res_json = $self->_ua->get($url);
    if ( $res_json->is_success ) {
        my $tresults = decode_json( $res_json->decoded_content );
        my @res;
        if ( $tresults->{torrent_results}
            && scalar( @{ $tresults->{torrent_results} } ) > 1 )
        {
            foreach my $t ( @{ $tresults->{torrent_results} } ) {
                my $t_obj = Rarbg::torrentapi::Res->new($t);
                push @res, $t_obj;
            }
            return \@res;
        }
        else {
            return Rarbg::torrentapi::Error->new($tresults);
        }
    }
    else {
        confess "Cannot execute Call " . $res_json->status_line;
    }
}

foreach my $method (qw/list search/) {
    __PACKAGE__->meta->add_method(
        $method,
        sub {
            my $self = shift;
            my $args = shift;
            foreach my $key ( keys %{$args} ) {
                $self->$key( $args->{$key} );
            }
            $self->mode("$method");
            return $self->_make_request;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf-8

=head1 NAME

Rarbg::torrentapi - Wrapper around Rarbg torrentapi (L<https://torrentapi.org/apidocs_v2.txt>)

=head1 SYNOPSIS

  use Rarbg::torrentapi;
  my $tapi = Rarbg::torrentapi->new();

  # list lastest torrents
  my $last_added = $tapi->list();

  # list torrents sorted by seeders
  my $last_added = $tapi->list({
      sort => 'seeders',
      limit => 50,
      category => 'tv'
  });

  # search by string
  # You can use all attributes also
  my $search = $tapi->search({
      search_string => 'the beatles',
      category => '23;24;25;26',
      min_seeders => 20
  });

  # search by imdb id
  my $search = $tapi->search({
      search_imdb => 'tt123456'
  });

  # search by themoviedb id
  my $search = $tapi->search({
      search_themoviedb => '123456'
  });

  # search by tvdb id
  my $search = $tapi->search({
      search_tvdb => '123456'
  });


=head1 DESCRIPTION

Rarbg::torrentapi is a simple wrapper around Rarbg's torrentapi.

=head1 ATTRIBUTES

Those attributes can be used on all public methods. In fact you can use them also when creating the object. Some of them make more sense at creation time, some others when calling the method. It's your call.

The only difference is that you should pass them as an anonymous hash if you pass them to a method.

You can find more info about their values at L<https://torrentapi.org/apidocs_v2.txt>

=head2 search_string

=head2 search_imdb

This is the Imdb id (http://imdb.com) in the form 'tt123456'

=head2 search_themoviedb

=head2 search_tvdb

=head2 category

Category can be quite confusing.
It accepts 'tv' and 'movies'. But, for the rest of categories only accepts its id numbers (or a semi-colon separated list of them).

=over 4

=item * XXX (18+) => 4

=item * Movies/XVID => 14

=item * Movies/XVID/720 => 48

=item * Movies/x264 => 17

=item * Movies/x264/1080 => 44

=item * Movies/x264/720 => 45

=item * Movies/x264/3D => 47

=item * Movies/x264/4k => 50

=item * Movies/x265/4k => 51

=item * Movies/x264/4k/HDR => 52

=item * Movies/Full BD => 42

=item * Movies/BD Remux => 46

=item * TV Episodes => 18

=item * TV HD Episodes => 41

=item * TV UHD Episodes => 49

=item * Movies/MP3 => 23

=item * Movies/FLAC => 25

=item * Games/PC ISO => 27

=item * Games/PC RIP => 28

=item * Games/PS3 => 40

=item * Games/XBOX-360 => 32

=item * Software/PC ISO => 33

=item * Games/PS4 => 53

=back

=head2 limit

It can be 25, 50 or 100.

=head2 sort

It can be seeders, leechers or last

=head2 min_seeders

=head2 min_leechers

=head2 ranked

This marks if you want to get all indexed torrents or just the ones from rarbg team.
Defaults to all (0).

=head1 METHODS

=head2 new

Just a simple constructor.

=head2 search

Makes a call to the API in 'search' mode. It returns either a Rarbg::torrentapi::Error or an array of L<Rarbg::torrentapi::Res>.

=head2 list

Makes a call to the API in 'list' mode. It returns either a Rarbg::torrentapi::Error or an array of L<Rarbg::torrentapi::Res>.

=head1 AUTHORS

Paco Esteban E<lt>paco@onna.beE<gt>
Baptiste C. L<https://github.com/baptistecdr>

=head1 COPYRIGHT

Copyright 2015- Paco Esteban

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
