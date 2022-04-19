###########################################
package Net::Google::Drive::Simple::V2;
###########################################

use strict;
use warnings;

use parent qw< Net::Google::Drive::Simple::Core >;
use LWP::UserAgent ();
use HTTP::Request  ();

use File::Basename qw( basename );

use JSON qw( from_json to_json );
use Log::Log4perl qw(:easy);

our $VERSION = '3.02';

###########################################
sub new {
###########################################
    my ( $class, %options ) = @_;
    return $class->SUPER::new(
        %options,
        api_file_url   => 'https://www.googleapis.com/drive/v2/files',
        api_upload_url => 'https://www.googleapis.com/upload/drive/v2/files',
    );
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

    if ( my $title = $search_opts->{title} ) {
        $title =~ s|\'|\\\'|g;
        if ( defined $opts->{q} && length $opts->{q} ) {
            $opts->{q} .= ' AND ';
        }

        $opts->{q} .= "title = '$title'";
    }

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
    my $file_data   = $self->_content_sub($file);

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

1;

=head2 METHODS

=over 4

=item C<new>

    my $gd_v2 = Net::Google::Drive::Simple::V2->new();

    # same as:
    my $gd_v2 = Net::Google::Drive::Simple->new( 'version' => 2 );

    # same as:
    my $gd_v2 = Net::Google::Drive::Simple->new();

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

=item C<children_by_folder_id>

=item C<file_mvdir>

=item C<http_delete>

=item C<http_put>

=back

=head1 LEGALESE

Copyright 2012-2019 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2019, Nicolas R. <cpan@atoomic.org>
2012-2019, Mike Schilli <cpan@perlmeister.com>
