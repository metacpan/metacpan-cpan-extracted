package Net::Google::PicasaWeb;
{
  $Net::Google::PicasaWeb::VERSION = '0.12';
}
use Moose;

# ABSTRACT: use Google's Picasa Web API

use Carp;
use HTTP::Message;
use HTTP::Request::Common;
use HTTP::Request;
use LWP::UserAgent;
use Net::Google::AuthSub;
use URI;
use XML::Twig;

use Net::Google::PicasaWeb::Album;
use Net::Google::PicasaWeb::Comment;
use Net::Google::PicasaWeb::MediaEntry;


has authenticator => (
    is          => 'rw',
    isa         => 'Net::Google::AuthSub',
    required    => 1,
    lazy_build  => 1,
);

sub _build_authenticator {
    my $version = $Net::Google::PicasaWeb::VERSION || 'TEST';
    Net::Google::AuthSub->new(
        service => 'lh2', # Picasa Web Albums
        source  => 'Net::Google::PicasaWeb-'.$version,
    );
}


has user_agent => (
    is          => 'rw',
    isa         => 'LWP::UserAgent',
    required    => 1,
    lazy_build  => 1,
);

sub _build_user_agent {
    LWP::UserAgent->new(
        cookie_jar => {},
    );
}


has service_base_url => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'http://picasaweb.google.com/data/feed/api/',
);


has xml_namespaces => (
    is          => 'rw',
    isa         => 'HashRef[Str]',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xml_namespaces {
    {
        'http://search.yahoo.com/mrss/'         => 'media',
        'http://schemas.google.com/photos/2007' => 'gphoto',
        'http://www.georss.org/georss'          => 'georss',
        'http://www.opengis.net/gml'            => 'gml',
    }
}


sub login {
    my $self     = shift;
    my $response = $self->authenticator->login(@_);

    croak "error logging in: $@"                 unless defined $response;
    croak "error logging in: ", $response->error unless $response->is_success;

    return 1;
}


sub list_albums {
    my ($self, %params) = @_;
    $params{kind} = 'album';

    my $user_id = delete $params{user_id} || 'default';
    return $self->list_entries(
        'Net::Google::PicasaWeb::Album',
        [ 'user', $user_id ],
        %params
    );
}


sub get_album {
    my ($self, %params) = @_;

    croak "missing album_id parameter" unless defined $params{album_id};

    my $user_id  = delete $params{user_id} || 'default';
    my $album_id = delete $params{album_id};

    return $self->get_entry(
        'Net::Google::PicasaWeb::Album',
        [ 'user', $user_id, 'albumid', $album_id ],
        %params
    );
}


sub add_album {
    my ($self, %params) = @_;

    my $twig = XML::Twig->new(
        pretty_print => 'indented',
        empty_tags   => 'expand',
    );

    my $root = XML::Twig::Elt->new(
        'entry' => {
            'xmlns'        => 'http://www.w3.org/2005/Atom',
            'xmlns:media'  => 'http://search.yahoo.com/mrss/',
            'xmlns:gphoto' => 'http://schemas.google.com/photos/2007',
        }
    );

    $twig->set_root($root);

    $root->insert_new_elt('last_child', title => {type => 'text'}, $params{title});
    $root->insert_new_elt('last_child', summary => {type => 'text'}, $params{summary});

    foreach my $gphoto ('location', 'access', 'commentingEnabled', 'timestamp') {
        $root->insert_new_elt('last_child', 'gphoto:' . $gphoto, $params{$gphoto});
    }

    my $group = $root->insert_new_elt('last_child', 'media:group');

    if (defined $params{keywords}) {
        $group->insert_new_elt('last_child', 'media:keywords', join(', ', $params{keywords}));
    }

    $root->insert_new_elt('last_child',
        'category' => {
            'scheme' => 'http://schemas.google.com/g/2005#kind',
            'term'   => 'http://schemas.google.com/photos/2007#album'
        }
    );

    my $uri = $self->service_base_url . 'user/default';
    my $response = $self->request('POST', $uri, $twig->sprint(), 'application/atom+xml');

    $twig->purge();

    if ($response->is_error) {
        croak $response->status_line;
    }

    my @entries = $self->_parse_feed('Net::Google::PicasaWeb::Album', 'entry', $response->content);
    return scalar $entries[0];
}


# This is a tiny cheat that allows us to reuse the list_entries method
{
    package Net::Google::PicasaWeb::Tag;
{
  $Net::Google::PicasaWeb::Tag::VERSION = '0.12';
}

    sub from_feed {
        my ($class, $service, $entry) = @_;
        return $entry->field('title');
    }
}

sub list_tags {
    my ($self, %params) = @_;
    $params{kind} = 'tag';

    my $user_id = delete $params{user_id} || 'default';
    return $self->list_entries(
        'Net::Google::PicasaWeb::Tag',
        [ 'user', $user_id ],
        %params
    );
}


sub list_comments {
    my ($self, %params) = @_;
    $params{kind} = 'comment';

    my $user_id = delete $params{user_id} || 'default';
    return $self->list_entries(
        'Net::Google::PicasaWeb::Comment',
        [ 'user', $user_id ],
        %params
    );
}

sub _feed_url {
    my ($self, $path, $query) = @_;

    $path = join '/', @$path if ref $path;
    $path = $self->service_base_url . $path
        unless $path =~ m{^https?:};

    my $uri = URI->new($path);
    $uri->query_form($query) if $query;

    return $uri;
}


sub get_comment {
    my ($self, %params) = @_;

    croak "missing album_id parameter"   unless defined $params{album_id};
    croak "missing photo_id parameter"   unless defined $params{photo_id};
    croak "missing comment_id parameter" unless defined $params{comment_id};

    my $user_id    = delete $params{user_id} || 'default';
    my $album_id   = delete $params{album_id};
    my $photo_id   = delete $params{photo_id};
    my $comment_id = delete $params{comment_id};

    return $self->get_entry(
        'Net::Google::PicasaWeb::Comment',
        [
            user      => $user_id,
            albumid   => $album_id,
            photoid   => $photo_id,
            commentid => $comment_id,
        ],
        %params
    );
}


sub list_media_entries {
    my ($self, %params) = @_;
    $params{kind} = 'photo';

    my $user_id  = delete $params{user_id};
    my $featured = delete $params{featured};
    
    croak "user_id may not be combined with featured"
        if $user_id and $featured;

    my $path;
    $path   = [ 'user', $user_id ] if $user_id;
    $path   = 'featured'           if $featured;
    $path ||= 'all';

    return $self->list_entries(
        'Net::Google::PicasaWeb::MediaEntry',
        $path,
        %params
    );
}

sub list_photos { shift->list_media_entries(@_) }
sub list_videos { shift->list_media_entries(@_) }


sub get_media_entry {
    my ($self, %params) = @_;

    croak "missing album_id parameter" unless defined $params{album_id};
    croak "missing photo_id parameter" unless defined $params{photo_id};

    my $user_id  = delete $params{user_id} || 'default';
    my $album_id = delete $params{album_id};
    my $photo_id = delete $params{photo_id};

    return $self->get_entry(
        'Net::Google::PicasaWeb::MediaEntry',
        [
            user    => $user_id,
            albumid => $album_id,
            photoid => $photo_id,
        ],
        %params
    );
}

sub get_photo { shift->get_media_entry(@_) }
sub get_video { shift->get_media_entry(@_) }


sub add_media_entry {
    my ($self, %params) = @_;

    my $user_id   = delete $params{user_id} || 'default';
    my $album_id  = delete $params{album_id} || 'default';
    my $data_type = delete $params{data_type} || 'image/jpeg';

    # Prepare Atom
    my $twig = XML::Twig->new(
        pretty_print => 'indented',
        empty_tags   => 'expand',
    );

    my $root = XML::Twig::Elt->new(
        'entry' => {
            'xmlns'        => 'http://www.w3.org/2005/Atom',
        }
    );

    $twig->set_root($root);

    $root->insert_new_elt('last_child', title => {type => 'text'}, $params{title});
    $root->insert_new_elt('last_child', summary => {type => 'text'}, $params{summary});

    # TODO:
    #   <media:group>
    #       <media:keywords>
    #           keyword, keyword, ...
    #       </media:keywords>
    #   </media:group>

    $root->insert_new_elt('last_child',
        'category' => {
            'scheme' => 'http://schemas.google.com/g/2005#kind',
            'term'   => 'http://schemas.google.com/photos/2007#photo'
        }
    );

    # Prepare REST message
    my $uri = $self->service_base_url . "user/$user_id/albumid/$album_id";
    my $request = HTTP::Request->new(POST => $uri, [$self->authenticator->auth_params,
                                                    'Content-Type' => 'multipart/related',
                                                    'MIME-version' => '1.0']);
    $request->add_part(HTTP::Message->new(['Content-Type' => 'application/atom+xml'], $twig->sprint()));
    $request->add_part(HTTP::Message->new(['Content-Type' => $data_type], $params{data}));

    # Clear unneeded Twig
    $twig->purge();

    my $response = $self->user_agent->request($request);

    $request->clear();

    if ($response->is_error) {
        croak $response->status_line;
    }

    # FIXME: Should be proper parser here
    my @entries = $self->_parse_feed('Net::Google::PicasaWeb::MediaEntry', 'entry', $response->content);
    return scalar $entries[0];
}

*add_photo = *add_media_entry;
*add_video = *add_media_entry;


sub request {
    my $self    = shift;
    my $method  = shift;
    my $path    = shift;
    my $query   = ($method eq 'GET') ? shift : undef;
    my $content = shift;
    my $type    = (($method eq 'POST') or ($method eq 'PUT')) ? shift : undef;

    my @headers = $self->authenticator->auth_params;

    my $url = $self->_feed_url($path, $query);
    
    my $request;
    {
        local $_ = $method;
        if    (/GET/)    { $request = GET   ($url, @headers) }
        elsif (/POST/)   { $request = POST  ($url, @headers, Content => $content, Content_Type => $type) }
        elsif (/PUT/)    { $request = PUT   ($url, @headers, Content => $content, Content_Type => $type) }
        elsif (/DELETE/) { $request = DELETE($url, @headers) }
        else             { confess "unknown method [$_]" }
    }

    return $self->user_agent->request($request);
}


sub get_entry {
    my ($self, $class, $path, %params) = @_;
    my $content = $self->_fetch_feed($path, %params);
    my @entries = $self->_parse_feed($class, 'feed', $content);
    return scalar $entries[0];
}

sub _fetch_feed {
    my ($self, $path, %params) = @_;

    # Allow thumbsize to be passed as an array
    if (defined $params{thumbsize} and ref $params{thumbsize}) {
        $params{thumbsize} = join ',', @{ $params{thumbsize} };
    }

    my $response = $self->request( GET => $path => [ %params ] );

    if ($response->is_error) {
        croak $response->status_line;
    }

    return $response->content;
}

sub _parse_feed {
    my ($self, $class, $element, $content) = @_;

    my @items;
    my $feed = XML::Twig->new( 
        map_xmlns => $self->xml_namespaces,
        twig_handlers => {
            $element => sub {
                push @items, $class->from_feed($self, $_);
            },
        },
    );
    $feed->parse($content);

    return @items;
}


sub list_entries {
    my ($self, $class, $path, %params) = @_;

    my $content = $self->_fetch_feed($path, %params);
    return $self->_parse_feed($class, 'entry', $content);
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::Google::PicasaWeb - use Google's Picasa Web API

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use Net::Google::PicasaWeb;

  my $service = Net::Google::PicasaWeb->new;

  # Login via one of these
  $service->login('jondoe@gmail.com', 'north23AZ');

  # Working with albums (see Net::Google::PicasaWeb::Album)
  my @albums = $service->list_albums( user_id => 'jondoe');
  $album->title('Quick Trip To Italy');

  # Listing photos (see Net::Google::PicasaWeb::MediaEntry)
  my @photos      = $album->list_media_entries; 
  my @recent      = $album->list_media_entries( max_results => 10 );
  my @puppies     = $album->list_media_entries( q => 'puppies' );
  my @all_puppies = $service->list_media_entries( q => 'puppies' );

  # Updating/Deleting photos (or video)
  $photo->title('Plz to love RealCat');

  # Listing tags
  my @user_tags  = $service->list_tags( user_id => 'jondoe' );
  my @album_tags = $album->list_tags;
  my @photo_tags = $photo->list_tags;

  # Listing comments (see Net::Google::PicasaWeb::Comment)
  my @recent         = $service->list_comments( user_id => 'jondoe', max_results => 10 );
  my @photo_comments = $photo->list_comments;

=encoding utf8

=head1 ATTRIBUTES

This module uses L<Moose> to handle attributes and such. These attributes are readable, writable, and may be passed to the constructor unless otherwise noted.

=head2 authenticator

This is an L<Net::Google::AuthSub> object used to handle authentication. The default is an instance set to use a service of "lh2" and a source of "Net::Google::PicasaWeb-VERSION".

=head2 user_agent

This is an L<LWP::UserAgent> object used to handle web communication. 

=head2 service_base_url

This is the base URL of the API to contact. This should probably always be C<http://picasaweb.google.com/data/feed/api/> unless Google starts providing alternate URLs or someone has a service providing the same API elsewhere..

=head2 xml_namespaces

When parsing the Google Data API response, these are the namespaces that will be used. By default, this is defined as:

    {
        'http://search.yahoo.com/mrss/'         => 'media',
        'http://schemas.google.com/photos/2007' => 'gphoto',
        'http://www.georss.org/georss'          => 'georss',
        'http://www.opengis.net/gml'            => 'gml',
    }

You may add more namespaces to this list, if needed.

=head1 METHODS

=head2 new

  my $service = Net::Google::PicasaWeb->new(%params);

See the L</ATTRIBUTES> section for a list of possible parameters.

=head2 login

  my $success = $service->login($username, $password, %options);

This is a shortcut for performing:

  $service->authenticator->login($username, $password, %options);

It has some additional error handling. This method will return a true value on success or die on error.

See L<Net::Google::AuthSub>.

=head2 list_albums

  my @albums = $service->list_albums(%params);

This will list a set of albums available from Picasa Web Albums. If no C<%params> are set, then this will list the albums belonging to the authenticated user. If the user is not authenticated, this will probably not return anything. Further control is gained by specifying one or more of the following parameters:

=over

=item user_id

This is the user ID to request a list of albums from. The defaults to "default", which lists those belonging to the current authenticated user.

=back

This method also takes the L</STANDARD LIST OPTIONS>.

=head2 get_album

  my $album = $service->get_album(
      user_id  => 'hanenkamp',
      album_id => '5143195220258642177',
  );

This will fetch a single album from the Picasa Web Albums using the given C<user_id> and C<album_id>. If C<user_id> is omitted, then "default" will be used instead.

This method returns C<undef> if no such album exists.

=head2 add_album

Create a new album for the current authenticated user.

  my $album = $service->add_album(
      title             => 'Trip to Italy',
      summary           => 'This was the recent trip I took to Italy',
      location          => 'Italy',
      access            => 'public',
      commentingEnabled => 'true',
      timestamp         => '1152255600000',
      keywords          => ('italy', 'vacation'),
  );

=over

=item title

The title of a new album.

=item summary

A small description of the album.

=item location

The location of the place where the photos have been taken.

=item access

The type of access to this album. It could be C<public> or C<private>.

=back

The default values will be applied by PicasaWeb on the server side.

See
C<http://code.google.com/intl/en-US/apis/picasaweb/developers_guide_protocol.html#AddAlbums>
for details.

=head2 list_tags

Returns a list of tags that have been used by the logged user or the user named in the C<user_id> parameter.

This method accepts this parameters:

=over

=item user_id

The ID of the user to find tags for. Defaults to the current user.

=back

This method also takes all the L</STANDARD LIST OPTIONS>.

=head2 list_comments

Returns comments on photos for the current account or the account given by the C<user_id> parameter.

It accepts the following parameters:

=over

=item user_id

This is the ID of the user to search for comments within. The comments returned will be commons on photos owned by this user. The default is to search the comments of the authenticated user.

=back

This method also accepts the L</STANDARD LIST OPTIONS>.

=head2 get_comment

  my $comment = $service->get_comment(
      user_id    => $user_id,
      album_id   => $album_id,
      photo_id   => $photo_id,
      comment_id => $comment_id,
  );

Retrieves a single comment from Picasa Web via the given C<user_id>, C<album_id>, C<photo_id>, and C<comment_id>. If C<user_id> is not given, "default" will be used.

Returns C<undef> if no matching comment is found.

=head2 list_media_entries

=head2 list_photos

=head2 list_videos

Returns photos and videos based on the query options given. If a C<user_id> option is set, the photos returned will be those related to the named user ID. Without a user ID, the photos will be pulled from the general community feed.

It accepts the following parameters:

=over

=item user_id

If given, the photos will be limited to those owned by this user. If it is set to "default", then the authenticated user will be used. If no C<user_id> is set, then the community feed will be used rather than a specific user. This option may not be combined with C<featured>.

=item featured

This can be set to a true value to fetch the current featured photos on PicasaWeb. This option is not compatible with C<user_id>.

=back

This method also accepts the L</STANDARD LIST OPTIONS>.

The L</list_photos> and L</list_videos> methods are synonyms for L</list_media_entries>.

=head2 get_media_entry

=head2 get_photo

=head2 get_video

  my $media_entry = $service->get_media_entry(
      user_id  => $user_id,
      album_id => $album_id,
      photo_id => $photo_id,
  );

Returns a specific photo or video entry when given a C<user_id>, C<album_id>, and C<photo_id>. If C<user_id> is not given, "default" will be used.

If no such photo or video can be found, C<undef> will be returned.

=head2 add_media_entry

=head2 add_photo

=head2 add_video

  my $media_entry = $service->add_media_entry(
      user_id   => $user_id,
      album_id  => $album_id,
      title     => $title,
      summary   => $summary,
      keywords  => ($keyword, $keyword, ),
      data      => $binary,
      data_type => $content_type,
  );

=head1 HELPERS

These helper methods are used to do some of the work.

=head2 request

  my $response = $service->request($method, $path, $query, $content);

This handles the details of making a request to the Google Picasa Web API.

=head2 get_entry

  my $entry = $service->get_entry($class, $path, %params);

This is used by the C<get_*> methods to pull and initialize a single object from Picasa Web.

=head2 list_entries

  my @entries = $service->list_entries($class, $path, %params);

This is used by the C<list_*> methods to pull and initialize lists of objects from feeds.

=head1 STANDARD LIST OPTIONS

Several of the listing methods return entries that can be modified by setting the following options.

=over

=item access

This is the L<visibility value|http://code.google.com/apis/picasaweb/reference.html#Visibility> to limit the returned results to.

=item thumbsize

This option is only used when listing albums and photos or videos.

By passing a single scalar or an array reference of scalars, e.g.,

  thumbsize => '72c',
  thumbsize => [ qw( 104c 640u d ) ],
  thumbsize => '1440u,1280u',

You may select the size or sizes of thumbnails attached to the items returned. Please see the L<parameters|http://code.google.com/apis/picasaweb/reference.html#Parameters> documentation for a description of valid values.

=item imgmax

This option is only used when listing albums and photos or videos.

This is a single scalar selecting the size of the main image to return with the items found. Please see the L<parameters|http://code.google.com/apis/picasaweb/reference.html#Parameters> documentation for a description of valid values.

=item tag

This option is only used when listing albums and photos or videos.

This is a tag name to use to filter the items returned.

=item q

This is a full-text query string to filter the items returned.

=item max_results

This is the maximum number of results to be returned.

=item start_index

This is the 1-based index of the first result to be returned.

=item bbox

This option is only used when listing albums and photos or videos.

This is the bounding box of geo coordinates to search for items within. The coordinates are given as an array reference of exactly 4 values given in the following order: west, south, east, north.

=item l

This option is only used when listing albums and photos or videos.

This may be set to the name of a geo location to search for items within. For example, "London".

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-Net-Google-PicasaWeb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Google-PicasaWeb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Google::PicasaWeb

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Google-PicasaWeb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Google-PicasaWeb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Google-PicasaWeb>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Google-PicasaWeb>

=back

=head1 ACKNOWLEDGEMENTS

Authors:

=over

=item *

Sterling Hanenkamp (zostay)

=item *

Andy Shevchenko (andy-shev)

=item *

Benjamin Thomas (bth0mas)

=item *

Tomáš Znamenáček (zoul)

=back

Thanks to:

=over

=item *

Robert May for responding to email messages quickly and transfering ownership of the C<Net::Google::PicasaWeb> namespace and providing some sample code to examine.

=item *

Simon Wistow for L<Net::Google::AuthSub>, which took care of all the authentication details.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
