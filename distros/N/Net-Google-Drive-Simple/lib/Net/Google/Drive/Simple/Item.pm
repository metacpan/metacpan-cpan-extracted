###########################################
package Net::Google::Drive::Simple::Item;
###########################################

use strict;
use warnings;

our $VERSION = '3.02';

sub new {
    my ( $pkg, $data ) = @_;

    die q[new is expecting one hashref] unless ref $data eq 'HASH';

    return bless { data => $data }, $pkg;
}

sub is_folder {
    my ($self) = @_;

    my $mimeType = $self->mimeType;
    $mimeType = '' unless defined $mimeType;
    return $mimeType eq 'application/vnd.google-apps.folder' ? 1 : 0;
}

sub is_file {
    return $_[0]->is_folder ? 0 : 1;
}

sub DESTROY { }

sub AUTOLOAD {
    our $AUTOLOAD;

    my $self = shift;
    my $key  = $AUTOLOAD;
    $key =~ s/.*:://;

    my $data = $self->{data};
    die unless $data && ref $data;

    return $data->{$key} if exists $data->{$key};

    # catching typos :-)
    my $lc_key = lc $key;
    if ( $lc_key ne $key ) {
        my $mapping = $self->_mapping();
        return $data->{ $mapping->{$lc_key} } if exists $mapping->{$lc_key};
    }

    die "Cannot find any attribute named '$key' for " . ref($self);
}

sub _mapping {
    my ($self) = @_;

    return $self->{_mapping} if defined $self->{_mapping};
    $self->{_mapping} = { map { lc($_) => $_ } keys %{ $self->{data} } };

    return $self->{_mapping};
}

1;

__END__


=head1 NAME

Net::Google::Drive::Simple::Item - Representation of a Google Drive File

=head1 SYNOPSIS

    use feature 'say';
    use Net::Google::Drive::Simple;

    # requires a ~/.google-drive.yml file with an access token,
    # see description from Net::Google::Drive::Simple

    my $gd = Net::Google::Drive::Simple->new();
    my $children = $gd->children( "/" ); # or any other folder /path/location

    foreach my $item ( @$children ) {
        # $item is one Net::Google::Drive::Simple::Item object

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

Net::Google::Drive::Simple::Item provides a class to manipulate the
File methadata from Google Drive API.

    https://developers.google.com/drive/api/v3/reference/files

=head2 GETTING STARTED

This class should not be used directly, and you should use
L<Net::Google::Drive::Simple> as shown in the synopsis.

=head1 METHODS

=over 4

=item C<new( $data )>

Constructor, creates one object which hold on hash ref C<$data>
to manipulate the metadata for a file.
All the keys from the hash below as documented in L<Google Drive API Doc|https://developers.google.com/drive/api/v3/reference/files>
are mapped using AUTOLOAD so you can use helpers for every first level entry like these:

        $file->kind;
        $file->id;
        $file->name;
        $file->mimeType;
        ....

        {
          "kind": "drive#file",
          "id": string,
          "name": string,
          "mimeType": string,
          "description": string,
          "starred": boolean,
          "trashed": boolean,
          "explicitlyTrashed": boolean,
          "trashingUser": {
            "kind": "drive#user",
            "displayName": string,
            "photoLink": string,
            "me": boolean,
            "permissionId": string,
            "emailAddress": string
          },
          "trashedTime": datetime,
          "parents": [
            string
          ],
          "properties": {
            (key): string
          },
          "appProperties": {
            (key): string
          },
          "spaces": [
            string
          ],
          "version": long,
          "webContentLink": string,
          "webViewLink": string,
          "iconLink": string,
          "hasThumbnail": boolean,
          "thumbnailLink": string,
          "thumbnailVersion": long,
          "viewedByMe": boolean,
          "viewedByMeTime": datetime,
          "createdTime": datetime,
          "modifiedTime": datetime,
          "modifiedByMeTime": datetime,
          "modifiedByMe": boolean,
          "sharedWithMeTime": datetime,
          "sharingUser": {
            "kind": "drive#user",
            "displayName": string,
            "photoLink": string,
            "me": boolean,
            "permissionId": string,
            "emailAddress": string
          },
          "owners": [
            {
              "kind": "drive#user",
              "displayName": string,
              "photoLink": string,
              "me": boolean,
              "permissionId": string,
              "emailAddress": string
            }
          ],
          "teamDriveId": string,
          "driveId": string,
          "lastModifyingUser": {
            "kind": "drive#user",
            "displayName": string,
            "photoLink": string,
            "me": boolean,
            "permissionId": string,
            "emailAddress": string
          },
          "shared": boolean,
          "ownedByMe": boolean,
          "capabilities": {
            "canAddChildren": boolean,
            "canChangeCopyRequiresWriterPermission": boolean,
            "canChangeViewersCanCopyContent": boolean,
            "canComment": boolean,
            "canCopy": boolean,
            "canDelete": boolean,
            "canDeleteChildren": boolean,
            "canDownload": boolean,
            "canEdit": boolean,
            "canListChildren": boolean,
            "canModifyContent": boolean,
            "canMoveChildrenOutOfTeamDrive": boolean,
            "canMoveChildrenOutOfDrive": boolean,
            "canMoveChildrenWithinTeamDrive": boolean,
            "canMoveChildrenWithinDrive": boolean,
            "canMoveItemIntoTeamDrive": boolean,
            "canMoveItemOutOfTeamDrive": boolean,
            "canMoveItemOutOfDrive": boolean,
            "canMoveItemWithinTeamDrive": boolean,
            "canMoveItemWithinDrive": boolean,
            "canMoveTeamDriveItem": boolean,
            "canReadRevisions": boolean,
            "canReadTeamDrive": boolean,
            "canReadDrive": boolean,
            "canRemoveChildren": boolean,
            "canRename": boolean,
            "canShare": boolean,
            "canTrash": boolean,
            "canTrashChildren": boolean,
            "canUntrash": boolean
          },
          "viewersCanCopyContent": boolean,
          "copyRequiresWriterPermission": boolean,
          "writersCanShare": boolean,
          "permissions": [
            permissions Resource
          ],
          "permissionIds": [
            string
          ],
          "hasAugmentedPermissions": boolean,
          "folderColorRgb": string,
          "originalFilename": string,
          "fullFileExtension": string,
          "fileExtension": string,
          "md5Checksum": string,
          "size": long,
          "quotaBytesUsed": long,
          "headRevisionId": string,
          "contentHints": {
            "thumbnail": {
              "image": bytes,
              "mimeType": string
            },
            "indexableText": string
          },
          "imageMediaMetadata": {
            "width": integer,
            "height": integer,
            "rotation": integer,
            "location": {
              "latitude": double,
              "longitude": double,
              "altitude": double
            },
            "time": string,
            "cameraMake": string,
            "cameraModel": string,
            "exposureTime": float,
            "aperture": float,
            "flashUsed": boolean,
            "focalLength": float,
            "isoSpeed": integer,
            "meteringMode": string,
            "sensor": string,
            "exposureMode": string,
            "colorSpace": string,
            "whiteBalance": string,
            "exposureBias": float,
            "maxApertureValue": float,
            "subjectDistance": integer,
            "lens": string
          },
          "videoMediaMetadata": {
            "width": integer,
            "height": integer,
            "durationMillis": long
          },
          "isAppAuthorized": boolean,
          "exportLinks": {
            (key): string
          }
        }

=item C<$file-E<gt>is_folder>

Return a boolean '1' or '0' to indicate if the current file
is one folder or not. (this is using the mimeType value).

    $iterm->is_folder

=item C<$file-E<gt>is_file>

Return a boolean '1' or '0' to indicate if the current file
is a regular file (not a folder).
(this is using the mimeType value).

     $iterm->is_file or ! $iterm->is_folder

=item C<$file-E<gt>kind>

Identifies what kind of resource this is. Value: the fixed string "drive#file".

=item C<$file-E<gt>id>

The ID of the file.

=item C<$file-E<gt>name>

The name of the file. This is not necessarily unique within a folder.
Note that for immutable items such as the top level folders of shared drives, My Drive root folder,
and Application Data folder the name is constant.

=item C<$file-E<gt>mimeType>

The MIME type of the file.
Google Drive will attempt to automatically detect an appropriate value from uploaded content if no value is provided. The value cannot be changed unless a new revision is uploaded.

If a file is created with a Google Doc MIME type, the uploaded content will be imported if possible. The supported import formats are published in the About resource.

=item C<$file-E<gt>description>

A short description of the file.

=item C<$file-E<gt>starred>

boolean - Whether the user has starred the file.

=item C<$file-E<gt>trashed>

boolean - Whether the file has been trashed, either explicitly or from a trashed parent folder. Only the owner may trash a file, and other users cannot see files in the owner's trash.

=item C<$file-E<gt>explicitlyTrashed>

boolean - Whether the file has been explicitly trashed, as opposed to recursively trashed from a parent folder.

=item C<$file-E<gt>version>

A monotonically increasing version number for the file. This reflects every change made to the file on the server, even those not visible to the user.

=item C<$file-E<gt>createdTime>

The time at which the file was created (RFC 3339 date-time).

=item C<$file-E<gt>modifiedTime>

The last time the file was modified by anyone (RFC 3339 date-time).
Note that setting modifiedTime will also update modifiedByMeTime for the user.

=item C<$file-E<gt>size>

The size of the file's content in bytes. This is only applicable to files with binary content in Google Drive.

=item C<$file-E<gt>capabilities>

Capabilities the current user has on this file. Each capability corresponds to a fine-grained action that a user may take.

=item more...

Please refer to the official documentation

       https://developers.google.com/drive/api/v3/reference/files

for more informations about the possible fields.

=back

=head1 Tips

=head2 AUTOLOAD

The implemented AUTOLOAD function is case insensitive.
The following functions C<$iterm->id>, C<$iterm->ID> and C<$iterm->Id>
for example are all equivalent and return the 'id' for the file.


When trying to access to an unknown field, the code will die/throw an exception.

     eval { $item->DoNotExist } and $@ =~ m{"Cannot find any attribute named 'DoNotExist'}

=head1 AUTHOR

2019, Nicolas R. <cpan@atoomic.org>
