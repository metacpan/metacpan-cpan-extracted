###########################################
package Net::Google::Drive::Simple;
###########################################

use strict;
use warnings;

use LWP::UserAgent ();
use HTTP::Request  ();

use File::MMagic ();
use IO::File     ();

use OAuth::Cmdline::CustomFile  ();
use OAuth::Cmdline::GoogleDrive ();

use Net::Google::Drive::Simple::Item ();

use File::Basename;

use YAML qw( LoadFile DumpFile );
use JSON qw( from_json to_json );
use Log::Log4perl qw(:easy);

our $VERSION = '0.21';

###########################################
sub new {
###########################################
    my ( $class, %options ) = @_;

    my $oauth;

    if ( exists $options{custom_file} ) {
        $oauth = OAuth::Cmdline::CustomFile->new( custom_file => $options{custom_file} );
    }
    else {
        $oauth = OAuth::Cmdline::GoogleDrive->new();
    }

    my $self = {
        init_done      => undef,
        api_file_url   => "https://www.googleapis.com/drive/v2/files",
        api_upload_url => "https://www.googleapis.com/upload/drive/v2/files",
        oauth          => $oauth,
        error          => undef,
        %options,
    };

    bless $self, $class;
}

###########################################
sub error {
###########################################
    my ( $self, $set ) = @_;

    if ( defined $set ) {
        $self->{error} = $set;
    }

    return $self->{error};
}

###########################################
sub init {
###########################################
    my ( $self, $path ) = @_;

    if ( $self->{init_done} ) {
        return 1;
    }

    DEBUG "Testing API";
    if ( !$self->api_test() ) {
        LOGDIE "api_test failed";
    }

    $self->{init_done} = 1;

    return 1;
}

###########################################
sub api_test {
###########################################
    my ($self) = @_;

    my $url = $self->file_url( { maxResults => 1 } );

    my $ua = LWP::UserAgent->new();

    my $req = HTTP::Request->new(
        GET => $url->as_string,
    );
    $req->header( $self->{oauth}->authorization_headers() );
    DEBUG "Fetching $url";

    my $resp = $ua->request($req);

    if ( $resp->is_success() ) {
        DEBUG "API tested OK";
        return 1;
    }

    $self->error( $resp->message() );

    ERROR "API error: ", $resp->message();
    return 0;
}

###########################################
sub file_url {
###########################################
    my ( $self, $opts ) = @_;

    $opts = {} if !defined $opts;

    my $default_opts = {
        maxResults => 3000,
    };

    $opts = {
        %$default_opts,
        %$opts,
    };

    my $url = URI->new( $self->{api_file_url} );
    $url->query_form($opts);

    return $url;
}

###########################################
sub files {
###########################################
    my ( $self, $opts, $search_opts ) = @_;

    if ( !defined $search_opts ) {
        $search_opts = {};
    }
    $search_opts = {
        page => 1,
        %$search_opts,
    };

    if ( !defined $opts ) {
        $opts = {};
    }

    $self->init();

    my @docs = ();

    while (1) {
        my $url  = $self->file_url($opts);
        my $data = $self->http_json($url);
        return unless defined $data;
        my $next_item = $self->item_iterator($data);

        while ( my $item = $next_item->() ) {
            if ( $item->{kind} eq "drive#file" ) {
                my $file = $item->{originalFilename};
                if ( !defined $file ) {
                    DEBUG "Skipping $item->{ title } (no originalFilename)";
                    next;
                }

                push @docs, $self->data_factory($item);
            }
            else {
                DEBUG "Skipping $item->{ title } ($item->{ kind })";
            }
        }

        if ( $search_opts->{page} and $data->{nextPageToken} ) {
            $opts->{pageToken} = $data->{nextPageToken};
        }
        else {
            last;
        }
    }

    return \@docs;
}

###########################################
sub folder_create {
###########################################
    my ( $self, $title, $parent ) = @_;

    return $self->file_create( $title, "application/vnd.google-apps.folder", $parent );
}

###########################################
sub file_create {
###########################################
    my ( $self, $title, $mime_type, $parent ) = @_;

    my $url = URI->new( $self->{api_file_url} );

    my $data = $self->http_json(
        $url,
        {
            title    => $title,
            parents  => [ { id => $parent } ],
            mimeType => $mime_type,
        }
    );

    return unless defined $data;

    return $data->{id};
}

###########################################
sub file_upload {
###########################################
    my ( $self, $file, $parent_id, $file_id, $opts ) = @_;

    $opts = {} if !defined $opts;

    # Since a file upload can take a long time, refresh the token
    # just in case.
    $self->{oauth}->token_expire();

    my $title = basename $file;

    # First, insert the file placeholder, according to
    # http://stackoverflow.com/questions/10317638
    my $mime_type = $self->file_mime_type($file);

    my $url;

    if ( !defined $file_id ) {
        $url = URI->new( $self->{api_file_url} );

        my $data = $self->http_json(
            $url,
            {
                mimeType    => $mime_type,
                parents     => [ { id => $parent_id } ],
                title       => $opts->{title} ? $opts->{title} : $title,
                description => $opts->{description},
            }
        );

        return unless defined $data;

        $file_id = $data->{id};
    }

    $url = URI->new( $self->{api_upload_url} . "/$file_id" );
    $url->query_form( uploadType => "media" );

    my $file_length = -s $file;
    my $file_data   = _content_sub($file);

    if (
        $self->http_put(
            $url,
            {
                'Content-Type'   => $mime_type,
                'Content'        => $file_data,
                'Content-Length' => $file_length
            }
        )
    ) {
        return $file_id;
    }
}

###########################################
sub rename {
###########################################
    my ( $self, $file_id, $new_name ) = @_;

    my $url = URI->new( $self->{api_file_url} . "/$file_id" );

    if (
        $self->http_put(
            $url,
            {
                "Accept"       => "application/json",
                "Content-Type" => "application/json",
                Content        => to_json( { title => $new_name } ),
            }
        )
    ) {
        return 1;
    }
    return;

}

###########################################
sub http_put {
###########################################
    my ( $self, $url, $params ) = @_;

    my $content = delete $params->{Content};
    my $req     = HTTP::Request->new(
        'PUT',
        $url->as_string,
        [ $self->{oauth}->authorization_headers(), %$params ],
    );

    # $content can be a string or a CODE ref. For example rename() calls us with a string, but
    #  file_upload() calls us with a CODE ref. The HTTP::Request::new() only accepts a string,
    #  so we set the content of the request after calling the constructor.
    $req->content($content);
    my $resp = $self->http_loop($req);

    if ( $resp->is_error ) {
        $self->error( $resp->message() );
        return;
    }
    DEBUG $resp->as_string;
    return $resp;
}

###########################################
sub file_mvdir {
###########################################
    my ( $self, $path, $target_folder ) = @_;

    my $url;

    if ( !defined $path or !defined $target_folder ) {
        LOGDIE "Missing parameter";
    }

    # Determine the file's parent in the path
    my ( $file_id, $folder_id ) = $self->path_resolve($path);

    if ( !defined $file_id ) {
        LOGDIE "Cannot find source file: $path";
    }

    my ($target_folder_id) = $self->path_resolve($target_folder);

    if ( !defined $target_folder_id ) {
        LOGDIE "Cannot find destination path: $target_folder";
    }

    print "file_id=$file_id\n";
    print "folder_id=$folder_id\n";
    print "target_folder_id=$target_folder_id\n";

    # Delete it from the current parent
    $url = URI->new( $self->{api_file_url} . "/$folder_id/children/$file_id" );
    if ( !$self->http_delete($url) ) {
        LOGDIE "Failed to remove $path from parent folder.";
    }

    # Add a new parent
    $url = URI->new( $self->{api_file_url} . "/$target_folder_id/children" );
    if ( !$self->http_json( $url, { id => $file_id } ) ) {
        LOGDIE "Failed to insert $path into $target_folder.";
    }

    return 1;
}

###########################################
sub path_resolve {
###########################################
    my ( $self, $path, $search_opts ) = @_;

    $search_opts = {} if !defined $search_opts;

    my @parts = grep { $_ ne '' } split '/', $path;

    my @ids       = qw(root);
    my $folder_id = my $parent = "root";
    DEBUG "Parent: $parent";

  PART: for my $part (@parts) {

        DEBUG "Looking up part $part (folder_id=$folder_id)";

        my $children = $self->children_by_folder_id(
            $folder_id,
            {
                maxResults => 100,    # path resolution maxResults is different
            },
            { %$search_opts, title => $part },
        );

        return unless defined $children;

        for my $child (@$children) {
            DEBUG "Found child ", $child->title();
            if ( $child->title() eq $part ) {
                $folder_id = $child->id();
                unshift @ids, $folder_id;
                $parent = $folder_id;
                DEBUG "Parent: $parent";
                next PART;
            }
        }

        my $msg = "Child $part not found";
        $self->error($msg);
        ERROR $msg;
        return;
    }

    if ( @ids == 1 ) {

        # parent of root is root
        return ( @ids, @ids );
    }

    return (@ids);
}

###########################################
sub file_delete {
###########################################
    my ( $self, $file_id ) = @_;

    my $url;

    LOGDIE 'Deletion requires file_id' if ( !defined $file_id );

    $url = URI->new( $self->{api_file_url} . "/$file_id" );

    if ( $self->http_delete($url) ) {
        return $file_id;
    }

    return;
}

###########################################
sub http_delete {
###########################################
    my ( $self, $url ) = @_;

    my $req = HTTP::Request->new(
        'DELETE',
        $url,
        [ $self->{oauth}->authorization_headers() ],
    );

    my $resp = $self->http_loop($req);

    DEBUG $resp->as_string;

    if ( $resp->is_error ) {
        $self->error( $resp->message() );
        return;
    }

    return 1;
}

###########################################
sub children_by_folder_id {
###########################################
    my ( $self, $folder_id, $opts, $search_opts ) = @_;

    $self->init();

    $search_opts         = {} unless defined $search_opts;
    $search_opts->{page} = 1  unless exists $search_opts->{page};

    if ( !defined $opts ) {
        $opts = {
            maxResults => 100,
        };
    }

    my $url = URI->new( $self->{api_file_url} );
    $opts->{'q'} = "'$folder_id' in parents";

    if ( my $title = $search_opts->{title} ) {
        $title =~ s|\'|\\\'|g;
        $opts->{q} .= " AND title = '$title'";
    }

    my @children = ();

    while (1) {
        $url->query_form($opts);

        my $data = $self->http_json($url);
        return unless defined $data;

        my $next_item = $self->item_iterator($data);

        while ( my $item = $next_item->() ) {
            push @children, $self->data_factory($item);
        }

        if ( $search_opts->{page} and $data->{nextPageToken} ) {
            $opts->{pageToken} = $data->{nextPageToken};
        }
        else {
            last;
        }
    }

    return \@children;
}

###########################################
sub children {
###########################################
    my ( $self, $path, $opts, $search_opts ) = @_;

    DEBUG "Determine children of $path";
    LOGDIE "No $path given" unless defined $path;

    $search_opts = {} unless defined $search_opts;

    my ( $folder_id, $parent ) = $self->path_resolve( $path, $search_opts );

    return unless defined $folder_id;

    DEBUG "Getting content of folder $folder_id";
    my $children = $self->children_by_folder_id(
        $folder_id, $opts,
        $search_opts
    );

    return unless defined $children;

    return wantarray ? ( $children, $folder_id ) : $children;
}

###########################################
sub search {
###########################################
    my ( $self, $opts, $search_opts, $query ) = @_;
    $search_opts ||= { page => 1 };

    $self->init();

    if ( !defined $opts ) {
        $opts = {
            maxResults => 100,
        };
    }

    my $url = URI->new( $self->{api_file_url} );

    $opts->{'q'} = $query;

    my @children = ();

    while (1) {
        $url->query_form($opts);

        my $data = $self->http_json($url);
        return unless defined $data;

        my $next_item = $self->item_iterator($data);

        while ( my $item = $next_item->() ) {
            push @children, $self->data_factory($item);
        }

        if ( $search_opts->{page} and $data->{nextPageToken} ) {
            $opts->{pageToken} = $data->{nextPageToken};
        }
        else {
            last;
        }
    }

    return \@children;
}

###########################################
sub data_factory {
###########################################
    my ( $self, $data ) = @_;

    return Net::Google::Drive::Simple::Item->new($data);
}

###########################################
sub download {
###########################################
    my ( $self, $url, $local_file ) = @_;

    $self->init();

    if ( ref $url ) {
        $url = $url->downloadUrl();
    }

    my $req = HTTP::Request->new(
        GET => $url,
    );
    $req->header( $self->{oauth}->authorization_headers() );

    my $ua   = LWP::UserAgent->new();
    my $resp = $ua->request( $req, $local_file );

    if ( $resp->is_error() ) {
        my $msg = "Can't download $url (" . $resp->message() . ")";
        ERROR $msg;
        $self->error($msg);
        return;
    }

    if ($local_file) {
        return 1;
    }

    return $resp->content();
}

###########################################
sub http_loop {
###########################################
    my ( $self, $req, $noinit ) = @_;

    my $ua = LWP::UserAgent->new();
    my $resp;

    my $RETRIES        = 3;
    my $SLEEP_INTERVAL = 10;

    {
        # refresh token if necessary
        if ( !$noinit ) {
            $self->init();
        }

        DEBUG "Fetching ", $req->url->as_string();

        $resp = $ua->request($req);

        if ( !$resp->is_success() ) {
            $self->error( $resp->message() );
            warn "Failed with ", $resp->code(), ": ", $resp->message(), "\n";
            if ( --$RETRIES >= 0 ) {
                ERROR "Retrying in $SLEEP_INTERVAL seconds";
                sleep $SLEEP_INTERVAL;
                redo;
            }
            else {
                ERROR "Out of retries.";
                return $resp;
            }
        }

        DEBUG "Successfully fetched ", length( $resp->content() ), " bytes.";
    }

    return $resp;
}

###########################################
sub http_json {
###########################################
    my ( $self, $url, $post_data ) = @_;

    my @headers = ( $self->{'oauth'}->authorization_headers() );
    my $verb    = 'GET';
    my $content;
    if ($post_data) {
        $verb = 'POST';
        push @headers, "Content-Type", "application/json";
        $content = to_json($post_data);
    }
    my $req = HTTP::Request->new(
        $verb,
        $url->as_string(),
        \@headers,
        $content,
    );

    my $resp = $self->http_loop($req);

    if ( $resp->is_error() ) {
        $self->error( $resp->message() );
        return;
    }

    my $data = from_json( $resp->content() );

    return $data;
}

###########################################
sub file_mime_type {
###########################################
    my ( $self, $file ) = @_;

    # There don't seem to be great implementations of mimetype
    # detection on CPAN, so just use this one for now.

    if ( !$self->{magic} ) {
        $self->{magic} = File::MMagic->new();
    }

    return $self->{magic}->checktype_filename($file);
}

###########################################
sub item_iterator {
###########################################
    my ( $self, $data ) = @_;

    my $idx = 0;

    if ( !defined $data ) {
        die "no data in item_iterator";
    }

    return sub {
        {
            my $next_item = $data->{items}->[ $idx++ ];

            return if !defined $next_item;

            if ( $next_item->{labels}->{trashed} ) {
                DEBUG "Skipping $next_item->{ title } (trashed)";
                redo;
            }

            return $next_item;
        }
    };
}

###########################################
sub file_metadata {
###########################################
    my ( $self, $file_id ) = @_;

    LOGDIE 'Deletion requires file_id' if ( !defined $file_id );

    my $url = URI->new( $self->{api_file_url} . "/$file_id" );

    return $self->http_json($url);
}

###########################################
sub _content_sub {
###########################################
    my $filename  = shift;
    my @stat      = stat $filename;
    my $remaining = $stat[7];
    my $blksize   = $stat[11] || 4096;

    die "$filename not a readable file with fixed size"
      unless -r $filename
      and $remaining;

    my $fh = IO::File->new( $filename, 'r' )
      or die "Could not open $filename: $!";
    $fh->binmode;

    return sub {
        my $buffer;

        # upon retries the file is closed and we must reopen it
        unless ( $fh->opened ) {
            $fh = IO::File->new( $filename, 'r' )
              or die "Could not open $filename: $!";
            $fh->binmode;
            $remaining = $stat[7];
        }

        unless ( my $read = $fh->read( $buffer, $blksize ) ) {
            die "Error while reading upload content $filename ($remaining remaining) $!"
              if $! and $remaining;
            $fh->close    # otherwise, we found EOF
              or die "close of upload content $filename failed: $!";
            $buffer ||= '';    # LWP expects an empty string on finish, read returns 0
        }
        $remaining -= length($buffer);
        return $buffer;
    };
}

1;

__END__

=head1 NAME

Net::Google::Drive::Simple - Simple modification of Google Drive data

=head1 SYNOPSIS

    use feature 'say';
    use Net::Google::Drive::Simple;

    # requires a ~/.google-drive.yml file with an access token,
    # see description below.
    my $gd = Net::Google::Drive::Simple->new();

    my $children = $gd->children( "/" ); # or any other folder /path/location

    foreach my $item ( @$children ) {

        # item is a Net::Google::Drive::Simple::Item object

        if ( $item->is_folder ) {
            say "** ", $item->title, " is a folder";
        } else {
            say $item->title, " is a file ", $item->mimeType;
            eval { # originalFilename not necessary available for all files
              say $item->originalFilename(), " can be downloaded at ", $item->downloadUrl();
            };
        }
    }

=head1 DESCRIPTION

Net::Google::Drive::Simple authenticates with a user's Google Drive and
offers several convenience methods to list, retrieve, and modify the data
stored in the 'cloud'. See C<eg/google-drive-upsync> as an example on how
to keep a local directory in sync with a remote directory on Google Drive.

=head2 GETTING STARTED

To get the access token required to access your Google Drive data via
this module, you need to run the script C<eg/google-drive-init> in this
distribution.

Before you run it, you need to register your 'app' with Google Drive
and obtain a client_id and a client_secret from Google:

    https://developers.google.com/drive/web/enable-sdk

Click on "Enable the Drive API and SDK", and find "Create an API project in
the Google APIs Console". On the API console, create a new project, click
"Services", and enable "Drive API" (leave "drive SDK" off). Then, under
"API Access" in the navigation bar, create a client ID, and make sure to
register a an "installed application" (not a "web application"). "Redirect
URIs" should contain "http://localhost". This will get you a "Client ID"
and a "Client Secret".

Then, replace the following lines in C<eg/google-drive-init> with the
values received:

      # You need to obtain a client_id and a client_secret from
      # https://developers.google.com/drive to use this.
    my $client_id     = "XXX";
    my $client_secret = "YYY";

Then run the script. It'll start a web server on port 8082 on your local
machine.  When you point your browser at http://localhost:8082, you'll see a
link that will lead you to Google Drive's login page, where you authenticate
and then allow the app (specified by client_id and client_secret above) access
to your Google Drive data. The script will then receive an access token from
Google Drive and store it in ~/.google-drive.yml from where other scripts can
pick it up and work on the data stored on the user's Google Drive account. Make
sure to limit access to ~/.google-drive.yml, because it contains the access
token that allows everyone to manipulate your Google Drive data. It also
contains a refresh token that this library uses to get a new access token
transparently when the old one is about to expire.

=head1 METHODS

=over 4

=item C<new()>

Constructor, creates a helper object to retrieve Google Drive data
later.

=item C<my $children = $gd-E<gt>children( "/path/to" )>

Return the entries under a given path on the Google Drive as a reference
to an array. Each entry
is an object composed of the JSON data returned by the Google Drive API.
Each object offers methods named like the fields in the JSON data, e.g.
C<originalFilename()>, C<downloadUrl>, etc.

Will return all entries found unless C<maxResults> is set:

    my $children = $gd->children( "/path/to", { maxResults => 3 } )

Due to the somewhat capricious ways Google Drive handles its directory
structures, the method needs to traverse the path component by component
and determine the ID of each directory to get to the next level. To speed
up subsequent lookups, it also returns the ID of the last component to the
caller:

    my( $children, $parent ) = $gd->children( "/path/to" );

If the caller now wants to e.g. insert a file into the directory, its
ID is available in $parent.

Each child comes back as a files#resource type and gets mapped into
an object that offers access to the various fields via methods:

    for my $child ( @$children ) {
        print $child->kind(), " ", $child->title(), "\n";
    }

Please refer to

    https://developers.google.com/drive/v2/reference/files#resource

for details on which fields are available.

=item C<my $files = $gd-E<gt>files( )>

Return all files on the drive as a reference to an array.
Will return all entries found unless C<maxResults> is set:

    my $files = $gd->files( { maxResults => 3 } )

Note that Google limits the number of entries returned by default to
100, and seems to restrict the maximum number of files returned
by a single query to 3,500, even if you specify higher values for
C<maxResults>.

Each file comes back as an object that offers access to the Google
Drive item's fields, according to the API (see C<children()>).

=item C<my $id = $gd-E<gt>folder_create( "folder-name", $parent_id )>

Create a new folder as a child of the folder with the id C<$parent_id>.
Returns the ID of the new folder or undef in case of an error.

=item C<my $id = $gd-E<gt>file_create( "folder-name", "mime-type", $parent_id )>

Create a new file with the given mime type as a child of the folder with the id C<$parent_id>.
Returns the ID of the new file or undef in case of an error.

Example to create an empty google spreadsheet:

    my $id = $gd->file_create( "Quarter Results", "application/vnd.google-apps.spreadsheet", "root" );

=item C<$gd-E<gt>file_upload( $file, $dir_id )>

Uploads the content of the file C<$file> into the directory with the ID
$dir_id on Google Drive. Uses C<$file> as the file name.

To overwrite an existing file on Google Drive, specify the file's ID as
an optional parameter:

    $gd->file_upload( $file, $dir_id, $file_id );

=item C<$gd-E<gt>rename( $file_id, $name )>

Renames the file or folder with C<$file_id> to the specified C<$name>.

=item C<$gd-E<gt>download( $item, [$local_filename] )>

Downloads an item found via C<files()> or C<children()>. Also accepts
the downloadUrl of an item. If C<$local_filename> is not specified,
C<download()> will return the data downloaded (this might be undesirable
for large files). If C<$local_filename> is specified, C<download()> will
store the downloaded data under the given file name.

    my $gd = Net::Google::Drive::Simple->new();
    my $files = $gd->files( { maxResults => 20 }, { page => 0 } );
    for my $file ( @$files ) {
        my $name = $file->originalFilename();
        print "Downloading $name\n";
        $gd->download( $file, $name ) or die "failed: $!";
    }

Be aware that only documents like PDF or png can be downloaded directly. Google Drive Documents like spreadsheets or (text) documents need to be exported into one of the available formats.
Check for "exportLinks" on a file given. In case of a document that can be exported you will receive a hash in the form:

    {
        'format_1' => 'download_link_1',
        'format_2' => 'download_link_2',
        ...
    }

Choose your download link and use it as an argument to the download() function which can also take urls directly.

    my $gd = Net::Google::Drive::Simple->new();
    my $children = $gd->children( '/path/to/folder/on/google/drive' );
    for my $child ( @$children ) {
        if ($child->can( 'exportLinks' )){
            my $type_chosen;
            foreach my $type (keys %{$child->exportLinks()}){
                # Take any type you can get..
                $type_chosen = $type;
                # ..but choose your preferred format, opendocument here:
                last if $type =~/oasis\.opendocument/;
            }
            my $url = $child->exportLinks()->{$type_chosen};

            $gd->download($url, 'my/local/file');

        }
    }

=item C<my $files = $gd-E<gt>search( )>

    my $children= $gd->search({ maxResults => 20 },{ page => 0 },
                              "title contains 'Futurama'");

Search files for attributes. See
L<https://developers.google.com/drive/web/search-parameters>
for a definition of the attributes.

To list all available files, those on the drive, those directly shared
with the user, and those generally available to the user, use an
empty search:

  my $children= $gd->search({},{ page => 0 },"");

=item C<$gd-E<gt>file_delete( file_id )>

Delete the file with the specified ID from Google Drive.

=item C<$gd-E<gt>drive_mvdir( "/gdrive/path/to/file", "/path/to/new/folder" )>

Move an existing file to a new folder. Removes the file's "parent"
setting (pointing to the old folder) and then adds the new folder as a
new parent.

=item C<my $metadata_hash_ref = $gd-E<gt>file_metadata( file_id )>

Return metadata about the file with the specified ID from Google Drive.

=item C<api_test>

Used at init time to check that the connection is correct.

=item C<children_by_folder_id>

=item C<data_factory>

=item C<error>

=item C<file_mime_type>

=item C<file_mvdir>

=item C<file_url>

=item C<http_delete>

=item C<http_json>

=item C<http_loop>

=item C<http_put>

=item C<init>

Internal initialization to setup the connection.

=item C<item_iterator>

=item C<path_resolve>

=back

=head1 Error handling

In case of an error while retrieving information from the Google Drive
API, the methods above will return C<undef> and a more detailed error
message can be obtained by calling the C<error()> method:

    print "An error occurred: ", $gd->error();

=head1 LOGGING/DEBUGGING

Net::Google::Drive::Simple is Log4perl-enabled.
To find out what's going on under the hood, turn on Log4perl:

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

=head1 LEGALESE

Copyright 2012-2019 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2019, Nicolas R. <cpan@atoomic.org>
2012-2019, Mike Schilli <cpan@perlmeister.com>
