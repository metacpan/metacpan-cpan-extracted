package Net::Google::Drive;

use 5.008001;
use strict;
use warnings;
use utf8;

use lib '/home/vrag/perl/googleoauth/lib';

use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;
use URI;
use File::Basename;

use Carp qw/carp croak/;

use Net::Google::OAuth;

use Data::Printer;

our $VERSION = '0.01';

our $DOWNLOAD_BUFF_SIZE     = 1024;
our $UPLOAD_BUFF_SIZE       = 256 * 1024;
our $FILE_API_URL           = 'https://www.googleapis.com/drive/v3/files';
our $FILE_API2_URL          = 'https://www.googleapis.com/drive/v2/files';
our $UPLOAD_FILE_API_URL    = 'https://www.googleapis.com/upload/drive/v3/files';

sub new {
    my ($class, %opt) = @_;

    my $self                    = {};
    my $client_id               = $opt{-client_id}          // croak "You must specify '-client_id' param";
    my $client_secret           = $opt{-client_secret}      // croak "You must specify '-client_secret' param";
    $self->{access_token}       = $opt{-access_token}       // croak "You must specify '-access_token' param";
    $self->{refresh_token}      = $opt{-refresh_token}      // croak "You must specify '-refresh_token' param";
    $self->{ua}                 = LWP::UserAgent->new();

    $self->{oauth}              = Net::Google::OAuth->new(
                                                -client_id      => $client_id,
                                                -client_secret  => $client_secret,
                                            );
    bless $self, $class;
    return $self;
}

sub searchFileByName {
    my ($self, %opt)        = @_;
    my $filename            = $opt{-filename}      || croak "You must specify '-filename' param";

    my $search_res = $self->__searchFile('name=\'' . $filename . "'");
 
    return $search_res;
}

sub searchFileByNameContains {
    my ($self, %opt)        = @_;
    my $filename            = $opt{-filename}      || croak "You must specify '-filename' param";

    my $search_res = $self->__searchFile('name contains \'' . $filename . "'");
 
    return $search_res;
}


sub downloadFile {
    my ($self, %opt)        = @_;
    my $file_id             = $opt{-file_id}        || croak "You must specify '-file_id' param";
    my $dest_file           = $opt{-dest_file}      || croak "You must specify '-dest_file' param";
    my $ua                  = $self->{ua};
    my $access_token        = $self->__getAccessToken();

    my $uri = URI->new(join('/', $FILE_API_URL, $file_id));
    $uri->query_form(
                        'alt'               => 'media',
                    );
    my $headers = [
        'Authorization' => 'Bearer ' . $access_token,
    ];

    my $request = HTTP::Request->new(   'GET',
                                        $uri,
                                        $headers,
                            );

    my $FL;
    my $response = $ua->request($request, sub {
                                                    if (not $FL) {
                                                        open $FL, ">$dest_file" or croak "Cant open $dest_file to write $!";
                                                        binmode $FL;
                                                    }
                                                    print $FL $_[0];
                                                }, 
                                                $DOWNLOAD_BUFF_SIZE
                                            );
    if ($FL) {
        close $FL;
    }
    my $response_code = $response->code();
    if ($response_code != 200) {
        my $error_message = __readErrorMessageFromResponse($response);
        croak "Can't download file id: $file_id to destination file: $dest_file. Code: $response_code. Message: '$error_message'";
    }
    return 1;
}

sub deleteFile {
    my ($self, %opt)        = @_;
    my $file_id             = $opt{-file_id}        || croak "You must specify '-file_id' param";
    my $access_token        = $self->__getAccessToken();

    my $uri = URI->new(join('/', $FILE_API_URL, $file_id));

    my $headers = [
        'Authorization' => 'Bearer ' . $access_token,
    ];

    my $request = HTTP::Request->new(   'DELETE',
                                        $uri,
                                        $headers,
                            );
    my $response = $self->{ua}->request($request);
    my $response_code = $response->code();
    if ($response_code =~ /^[^2]/) {
        my $error_message = __readErrorMessageFromResponse($response);
        croak "Can't delete file id: $file_id. Code: $response_code. Message: $error_message";
    }
    return 1;
}

sub uploadFile {
    my ($self, %opt)                    = @_;
    my $source_file                     = $opt{-source_file}        || croak "You must specify '-source_file' param";

    if (not -f $source_file) {
        croak "File: $source_file not exists";
    }

    my $file_size = (stat $source_file)[7];
    my $part_upload_uri = $self->__createEmptyFile($source_file, $file_size);
    open my $FH, "<$source_file" or croak "Can't open file: $source_file $!";
    binmode $FH;

    my $filebuf;
    my $uri = URI->new($part_upload_uri);
    my $start_byte = 0;
    while (my $bytes = read($FH, $filebuf, $UPLOAD_BUFF_SIZE)) {
        my $end_byte = $start_byte + $bytes - 1;
        my $headers = [
            'Content-Length'    => $bytes,
            'Content-Range'     => sprintf("bytes %d-%d/%d", $start_byte, $end_byte, $file_size),
        ];
        my $request = HTTP::Request->new('PUT', $uri, $headers, $filebuf);

        # Send request to upload part of file
        my $response = $self->{ua}->request($request);
        my $response_code = $response->code();
        # On end part, response code is 200, on middle part is 308
        if ($response_code == 200 || $response_code == 201) {
            if ($end_byte + 1 != $file_size) {
                croak "Server return code: $response_code on upload file, but file is not fully uploaded. End byte: $end_byte. File size: $file_size. File: $source_file";
            }
            return decode_json($response->content());
        }
        elsif ($response_code != 308) {
            croak "Wrong response code on upload part file. Code: $response_code. File: $source_file";
        }
        $start_byte += $bytes;
    }
    close $FH;

    return;
}

sub setFilePermission {
    my ($self, %opt)            = @_;
    my $file_id                 = $opt{-file_id}        || croak "You must specify '-file_id' param";
    my $permission_type         = $opt{-type}           || croak "You must specify '-type' param";
    my $role                    = $opt{-role}           || croak "You must specify '-role' param";
    my %valid_permissions       = (
        'user'              => 1,
        'group'             => 1,
        'domain'            => 1,
        'anyone'            => 1,
    );

    my %valid_roles = (
        'owner'             => 1,
        'organizer'         => 1,
        'fileOrganizer'     => 1,
        'writer'            => 1,
        'commenter'         => 1,
        'reader'            => 1,
    );
    #Check permission in param
    if (not $valid_permissions{$permission_type}) {
        croak "Wrong permission type: '$permission_type'. Valid permissions types: " . join(' ', keys %valid_permissions);
    }

    #Check role in param
    if (not $valid_roles{$role}) {
        croak "Wrong role: '$role'. Valid roles: " . join(' ', keys %valid_roles);
    }
    my $access_token            = $self->__getAccessToken();

    my $uri = URI->new(join('/', $FILE_API_URL, $file_id, 'permissions'));
    my $headers = [
        'Authorization' => 'Bearer ' . $access_token,
        'Content-Type'  => 'application/json',
    ];
    my $request_content = {
        'type'  => $permission_type,
        'role'  => $role,
    };

    my $request = HTTP::Request->new('POST', $uri, $headers, encode_json($request_content));

    my $response = $self->{ua}->request($request);
    my $response_code = $response->code();
    if ($response_code != 200) {
        my $error_message = __readErrorMessageFromResponse($response);
        croak "Can't share file id: $file_id. Code: $response_code. Error message: $error_message";
    }
    return decode_json($response->content());
}

sub getFileMetadata {
    my ($self, %opt)            = @_;
    my $file_id                 = $opt{-file_id}        || croak "You must specify '-file_id' param";
    my $access_token            = $self->__getAccessToken();

    my $uri = URI->new(join('/', $FILE_API2_URL, $file_id));
    $uri->query_form('supportsTeamDrives' => 'true');

    my $headers = [
        'Authorization' => 'Bearer ' . $access_token,
    ];
    my $request = HTTP::Request->new("GET", $uri, $headers);
    my $response = $self->{ua}->request($request);
    my $response_code = $response->code();
    if ($response_code != 200) {
        my $error_message = __readErrorMessageFromResponse($response);
        croak "Can't get metadata from file id: $file_id. Code: $response_code. Error message: $error_message";
    }
    return decode_json($response->content());
}

sub shareFile {
    my ($self, %opt)            = @_;
    my $file_id                 = $opt{-file_id}        || croak "You must specify '-file_id' param";

    ## Adding permissions to file
    my $permission = $self->setFilePermission(
                                -file_id        => $file_id,
                                -type           => 'anyone',
                                -role           => 'reader',
                            );
    if ((not exists $permission->{type}) || ($permission->{type} ne 'anyone')) {
        croak "Can't set permission to anyone for file id: $file_id";
    }

    my $metadata = $self->getFileMetadata( -file_id => $file_id );
    return $metadata->{webContentLink};
}

sub __createEmptyFile {
    my ($self, $source_file, $file_size)        = @_;
    my $access_token                            = $self->__getAccessToken();

    my $body = {
        'name'  => basename($source_file),
    };
    my $body_json = encode_json($body);

    my $uri = URI->new($UPLOAD_FILE_API_URL);
    $uri->query_form('upload_type'  => 'resumable');
    my $headers = [
        'Authorization'             => 'Bearer ' . $access_token,
        'Content-Length'            => length($body_json),
        'Content-Type'              => 'application/json; charset=UTF-8',
        'X-Upload-Content-Length'   => $file_size,
    ];

    my $request = HTTP::Request->new('POST', $uri, $headers, $body_json);
    my $response = $self->{ua}->request($request);

    my $response_code = $response->code();
    if ($response_code != 200) {
        my $error_message = __readErrorMessageFromResponse($response);
        croak "Can't upload part of file. Code: $response_code. Error message: $error_message";
    }

    my $location = $response->header('Location') or croak "Location header not defined";

    return $location;
}

sub __readErrorMessageFromResponse {
    my ($response) = @_;
    my $error_message = eval {decode_json($response->content)};
    if ($error_message) {
        return $error_message->{error}->{message};
    }
    return '';
}



sub __searchFile {
    my ($self, $q) = @_;

    my $access_token = $self->__getAccessToken();
    
    my $headers = [
        'Authorization' => 'Bearer ' . $access_token,
    ];

    my $uri = URI->new($FILE_API_URL);
    $uri->query_form('q'    => $q);
    my $request = HTTP::Request->new('GET',
                                $uri,
                                $headers,
                            );
    my $files = [];
    $self->__apiRequest($request, $files);


    return $files;
}

sub __apiRequest {
    my ($self, $request, $files) = @_;

    my $response = $self->{ua}->request($request);
    my $response_code = $response->code;
    if ($response_code != 200) {
        croak "Wrong response code on search_file. Code: $response_code";
    }

    my $json_res = decode_json($response->content);

    if (my $next_token = $json_res->{next_token}) {
        my $uri = $request->uri;
        $uri->query_form('next_token' => $next_token);
        $self->__apiRequest($request, $files);
    }
    push @$files, @{$json_res->{files}};

    return 1;
}

sub __getAccessToken {
    my ($self) = @_;

    my $oauth = $self->{oauth};
    my $token_info = 
        eval {
            $oauth->getTokenInfo( -access_token => $self->{access_token} );
        };
    # If error on get token info or token is expired
    if (not $@) {
        if ((exists $token_info->{expires_in}) && ($token_info->{expires_in} > 5)) {
            return $self->{access_token};
        }
    }

    #Refresh token
    $oauth->refreshToken( -refresh_token => $self->{refresh_token} );
    $self->{refresh_token} = $oauth->getRefreshToken();
    $self->{access_token} = $oauth->getAccessToken();

    return $self->{access_token};
}

1;

=head1 NAME

B<Net::Google::Drive> - simple Google drive API module

=head1 SYNOPSIS

This module use to upload, download, share file on Google drive
    use Net::Google::Drive;

    #Create disk object. You need send in param 'access_token', 'refresh_token', 'client_id' and 'client_secret'. 
    #Values of 'client_id' and 'client_secret' uses to create Net::Google::OAuth object so that update value of 'access_token'.
    my $disk = Net::Google::Drive->new(
                                        -client_id          => $client_id,
                                        -client_secret      => $client_secret,
                                        -access_token       => $access_token,
                                        -refresh_token      => $refresh_token,
                                        );

    # Search file by name
    my $file_name = 'upload.doc';
    my $files = $drive->searchFileByName( -filename => $file_name ) or croak "File '$file_name' not found";
    my $file_id = $files->[0]->{id};
    print "File id: $file_id\n";

    #Download file
    my $dest_file = '/home/upload.doc';
    $disk->downloadFile(
                            -file_id        => $file_id,
                            -dest_file      => $dest_file,
                            );

    #Upload file
    my $source_file = '/home/upload.doc';
    my $res = $disk->uploadFile( -source_file   => $source_file );
    print "File: $source_file uploaded. File id: $res->{id}\n";

=head1 METHODS

=head2 new(%opt)

Create L<Net::Google::Disk> object

    %opt:
        -client_id          => Your app client id (Get from google when register your app)
        -client_secret      => Your app client secret (Get from google when register your app)
        -access_token       => Access token value (Get from L<Net::Google::OAuth>)
        -refresh_token      => Refresh token value (Get from L<Net::Google::OAuth>)

=head2 searchFileByName(%opt)

Search file on google disk by name. Return arrayref to info with found files. If files not found - return empty arrayref

    %opt:
        -filename           => Name of file to find
    Return:
   [
        [0] {
            id         "1f13sLfo6UEyUuFpn-NWPnY",
            kind       "drive#file",
            mimeType   "application/x-perl",
            name       "drive.t"
        }
    ]
    
=head2 searchFileByNameContains(%opt)

Search files on google drive by name contains value in param '-filename'
Param and return value same as in method L<searchFileByName>

=head2 downloadFile(%opt) 

Download file from google dist to -dest_file on local system. Return 1 if success, die in otherwise

    %opt: 
        -dest_file          => Name of file on disk in which you will download file from google disk
        -file_id            => Id of file on google disk

=head2 deleteFile(%opt)

Delete file from google disk. Return 1 if success, die in otherwise

    %opt: 
        -file_id            => Id of file on google disk

=head2 uploadFile(%opt)

Upload file from local system to google drive. Return file_info hashref if success, die in otherwise
    
    %opt:
        -source_file        => File on local system
    Return:
       {
            id         "1LVAr2PpqX9m314JyZ6YJ4v_KIzG0Gey2",
            kind       "drive#file",
            mimeType   "application/octet-stream",
            name       "gogle_upload_file"
       }

=head2 setFilePermission(%opt)

Set permissions for file on google drive. Return permission hashref, die in otherwise

    %opt:
        -file_id            => Id of file on google disk
        -type               => The type of the grantee. Valid values are: (user, group, domain, anyone)
        -role               => The role granted by this permission. Valid values are: (owner, organizer, fileOrganizer, writer, commenter, reader)
    Return:
        {
            allowFileDiscovery   JSON::PP::Boolean  {
                Parents       Types::Serialiser::BooleanBase
                public methods (0)
                private methods (0)
                internals: 0
            },
            id                   "anyoneWithLink",
            kind                 "drive#permission",
            role                 "reader",
            type                 "anyone"
        }

=head2 getFileMetadata(%opt)

Get metadata of file. Return hashref with metadata if success, die in otherwise

    %opt: 
        -file_id            => Id of file on google disk
    Return:
            {                                                                                                                                                         alternateLink                  "https://drive.google.com/file/d/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut/view?usp=drivesdk",
            appDataContents                JSON::PP::Boolean  {
                Parents       Types::Serialiser::BooleanBase
                public methods (0)
                private methods (0)
                internals: 0
            },
            capabilities                   {
                canCopy   JSON::PP::Boolean  {
                    Parents       Types::Serialiser::BooleanBase
                    public methods (0)
                    private methods (0)
                    internals: 1
                },
                canEdit   var{capabilities}{canCopy}
            },
            copyable                       var{capabilities}{canCopy},
            copyRequiresWriterPermission   var{appDataContents},
            createdDate                    "2018-10-04T12:05:15.896Z",
            downloadUrl                    "https://doc-0g-7o-docs.googleusercontent.com/docs/securesc/ck8i7vfbvef13kb30b8mkrcjv4ihp2uj/3mfn1kbr655euhlo7tctg5mmn8oirg
        gf/1538654400000/10526805100525201667/10526805100525201667/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut?e=download&gd=true",
            editable                       var{capabilities}{canCopy},
            embedLink                      "https://drive.google.com/file/d/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut/preview?usp=drivesdk",
            etag                           ""omwGuTP8OdxhZkubyp-j43cFdJQ/MTUzODY1NDcxNTg5Ng"",
            explicitlyTrashed              var{appDataContents},
            fileExtension                  "",
            fileSize                       1000000,
            headRevisionId                 "0B4HgPHxdPy22UmZXSFVRTkRLbXhFakdzZjFSUGkrNWZIVFN3PQ",
            iconLink                       "https://drive-thirdparty.googleusercontent.com/16/type/application/octet-stream",
            id                             "10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut",
            kind                           "drive#file",
            labels                         {
                hidden       var{appDataContents},
                restricted   var{appDataContents},
                starred      var{appDataContents},
                trashed      var{appDataContents},
                viewed       var{appDataContents}
            },
            lastModifyingUser              {
                    displayName           "Ларри Уолл",
                    emailAddress          "perlgogledrivemodule@gmail.com",
                    isAuthenticatedUser   var{capabilities}{canCopy},
                    kind                  "drive#user",
                    permissionId          10526805100525201667
            },
            lastModifyingUserName          "Ларри Уолл",
            markedViewedByMeDate           "1970-01-01T00:00:00.000Z",
            md5Checksum                    "ded2a2983b3e1743152d8224549510e1",
            mimeType                       "application/octet-stream",
            modifiedByMeDate               "2018-10-04T12:05:15.896Z",
            modifiedDate                   "2018-10-04T12:05:15.896Z",
            originalFilename               "gogle_upload_file",
            ownerNames                     [
                [0] "Ларри Уолл"
            ],
            owners                         [
                [0] {
                    displayName           "Ларри Уолл",
                    emailAddress          "perlgogledrivemodule@gmail.com",
                    isAuthenticatedUser   var{capabilities}{canCopy},
                    kind                  "drive#user",
                    permissionId          10526805100525201667
                }
            ],
            parents                        [
                [0] {
                    id           "0AIHgPHxdPy22Uk9PVA",
                    isRoot       var{capabilities}{canCopy},
                    kind         "drive#parentReference",
                    parentLink   "https://www.googleapis.com/drive/v2/files/0AIHgPHxdPy22Uk9PVA",
                    selfLink     "https://www.googleapis.com/drive/v2/files/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut/parents/0AIHgPHxdPy22Uk9PVA"
                }
            ],
            quotaBytesUsed                 1000000,
            selfLink                       "https://www.googleapis.com/drive/v2/files/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut",
            shared                         var{appDataContents},
            spaces                         [
                [0] "drive"
            ],
            title                          "gogle_upload_file",
            userPermission                 {
                etag       ""omwGuTP8OdxhZkubyp-j43cFdJQ/N52l-iUAo-dARaTch8nQXOzl348"",
                id         "me",
                kind       "drive#permission",
                role       "owner",
                selfLink   "https://www.googleapis.com/drive/v2/files/10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut/permissions/me",
                type       "user"
            },
            version                        2,
            webContentLink                 "https://drive.google.com/uc?id=10Z5YDCHn3gnj0S4_Lf0poc2Lm5so0Sut&export=download",
            writersCanShare                var{capabilities}{canCopy}
        }

=head2 shareFile(%opt)

Share file for download. Return download link if success, die in otherwise

    %opt: 
        -file_id            => Id of file on google disk

=head1 DEPENDENCE

L<Net::Google::OAuth>, L<LWP::UserAgent>, L<JSON::XS>, L<URI>, L<HTTP::Request>, L<File::Basename> 

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
