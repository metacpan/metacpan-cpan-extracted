###########################################
package Net::Google::Drive::Simple::V3;
###########################################

use strict;
use warnings;
use parent qw< Net::Google::Drive::Simple::Core >;

use URI             ();
use URI::QueryParam ();
use Log::Log4perl qw(:easy);

use constant {
    'HTTP_METHOD_GET'    => 'GET',
    'HTTP_METHOD_POST'   => 'POST',
    'HTTP_METHOD_PATCH'  => 'PATCH',
    'HTTP_METHOD_DELETE' => 'DELETE',

    'TYPE_STRING'  => 'string',
    'TYPE_INTEGER' => 'integer',
    'TYPE_LONG'    => 'long',
    'TYPE_BOOLEAN' => 'boolean',
    'TYPE_OBJECT'  => 'object',
    'TYPE_BYTES'   => 'bytes',
};

our $VERSION = '3.00';

# TODO:
# * requestId are random UUIDs that we should probably generate (drive_create)
# * Support for Request Body values
# * Support fields format: https://developers.google.com/drive/api/guides/fields-parameter
# * Add validation for path parameters
# * Specific types (like ISO 639-1)
# * Extended upload support: https://developers.google.com/drive/api/guides/manage-uploads

# These are only the defaults
my %default_deprecated_param_names = (
    'corpus'                => 'corpora',
    'includeTeamDriveItems' => 'includeItemsFromAllDrives',
    'supportsTeamDrives'    => 'supportsAllDrives',
    'teamDriveId'           => 'driveId',
);

###########################################
sub new {
###########################################
    my ( $class, %options ) = @_;
    return $class->SUPER::new(
        %options,
        'api_base_url'   => 'https://www.googleapis.com/drive/v3/',
        'api_upload_url' => 'https://www.googleapis.com/upload/drive/v3/files',

        # to make sure api_test() works:
        'api_file_url' => 'https://www.googleapis.com/drive/v3/files',
    );
}

###########################################
sub _validate_param_type {
###########################################
    my ( $self, $method, $param_data, $param_values ) = @_;

    my %validation_types = (
        TYPE_STRING()  => sub { defined and length },
        TYPE_INTEGER() => sub { defined and m{^[0-9]+$}xms },
        TYPE_LONG()    => sub { defined and m{^[0-9]+$}xms },
        TYPE_BOOLEAN() => sub { defined and m{^[01]$}xms },
        TYPE_OBJECT()  => sub { ref eq 'HASH' },
        TYPE_BYTES()   => sub { defined and length },
    );

    foreach my $param_name ( sort keys %{$param_values} ) {
        if ( !exists $param_data->{$param_name} ) {
            LOGDIE("[$method] Parameter name '$param_name' does not exist");
        }
    }

    foreach my $param_name ( sort keys %{$param_data} ) {
        my ( $param_type, $is_required ) = @{ $param_data->{$param_name} };
        my $param_value = $param_values->{$param_name};

        # You did not provide a parameter that is needed
        if ( !exists $param_values->{$param_name} ) {
            $is_required
              and LOGDIE("[$method] Parameter '$param_name' is required");

            next;
        }

        my $validation_cb = $validation_types{$param_type};
        if ( !$validation_cb ) {
            LOGDIE("[$method] Parameter type '$param_type' does not exist");
        }

        local $_ = $param_value;
        my $success = $validation_cb->()
          or LOGDIE("[$method] Parameter type '$param_name' does not validate as '$param_type'");
    }

    return 1;
}

###########################################
sub _handle_complex_types {
###########################################
    my ( $self, $method, $options ) = @_;

    if ( my $perm_for_view = $options->{'includePermissionsForView'} ) {
        $perm_for_view eq 'published'
          or LOGDIE("[$method] Parameter 'includePermissionsForView' must be: published");
    }

    my $page_size = $options->{'pageSize'};
    if ( defined $page_size ) {
        $page_size >= 1 && $page_size <= 1_000
          or LOGDIE("[$method] Parameter 'pageSize' must be: 1 to 1000");
    }

    if ( my $upload_type = $options->{'uploadType'} ) {
        $upload_type =~ /^( media | multipart | resumable )$/xms
          or LOGDIE("[$method] Parameter 'uploadType' must be: media|multipart|resumable");
    }

    return 1;
}

###########################################
sub _generate_uri {
###########################################
    my ( $self, $path, $options ) = @_;
    my $uri = URI->new( $path =~ /^http/xms ? $path : $self->{'api_base_url'} . $path );

    $options
      and $uri->query_form($options);

    return $uri;
}

###########################################
sub _handle_deprecated_params {
###########################################
    my ( $self, $method, $info, $options ) = @_;

    foreach my $dep_name ( sort keys %{$options} ) {
        my $alt = $info->{'deprecated_param_names'}{$dep_name}
          || $default_deprecated_param_names{$dep_name};

        if ($alt) {
            WARN("[$method] Parameter name '$dep_name' is deprecated, use '$alt' instead");
        }
    }

    return;
}

###########################################
sub _prepare_body_options {
###########################################
    my ( $self, $options, $body_param_names ) = @_;

    my $body_options = {
        map +( exists $options->{$_} ? ( $_ => delete $options->{$_} ) : () ),
        @{$body_param_names},
    };

    return $body_options;
}

###########################################
sub _handle_api_method {
###########################################
    my ( $self, $info, $options ) = @_;
    my $method = $info->{'method_name'};

    # We yank out all the body parameters so we don't validate them
    # TODO: Support body parameter validation
    my $body_options = $self->_prepare_body_options( $options, $info->{'body_parameters'} );

    # We validate the options left
    $self->_validate_param_type( $method, $info->{'query_parameters'}, $options );

    # We might have a more complicated type checking specified
    if ( my $param_check = $info->{'parameter_checks'} ) {
        foreach my $name ( sort keys %{$param_check} ) {
            defined $options->{$name}
              or next;

            my $cb = $param_check->{$name};
            ref $cb eq 'CODE'
              or LOGDIE("[$method] Parameter '$name' missing validation callback");

            local $_ = $options->{$name};
            my $error_str = $cb->();
            $error_str
              and LOGDIE("[$method] Parameter '$name' failed validation: $error_str");
        }
    }

    # We check for deprecated parameters (from a list of known deprecated parameters)
    $self->_handle_deprecated_params( $method, $info, $options );

    # We handle some more specific validation rules (from a list of known parameters)
    $self->_handle_complex_types( $method, $options );

    $self->init();

    # We generate the URI path
    my $uri = $self->_generate_uri( $info->{'path'}, $options );

    # GET requests cannot have a body
    if (   $info->{'http_method'} eq HTTP_METHOD_GET()
        || $info->{'http_method'} eq HTTP_METHOD_DELETE() ) {
        undef $body_options;
    }

    # We make the request and get a response
    return $self->http_json( $uri, [ $info->{'http_method'}, $body_options ] );
}

# --- about

###########################################
sub about {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('about() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 1 ],
        },
        'path'        => 'about',
        'method_name' => 'about',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

# --- changes

###########################################
sub getStartPageToken {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    my $info = {
        'query_parameters' => {
            'driveId'            => [ TYPE_STRING(),  0 ],
            'fields'             => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'  => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives' => [ TYPE_BOOLEAN(), 0 ],    # Deprecated
            'teamDriveId'        => [ TYPE_STRING(),  0 ],    # Deprecated
        },

        'path'        => 'changes/startPageToken',
        'http_method' => HTTP_METHOD_GET(),
        'method_name' => 'getStartPageToken',
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub changes {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('changes() missing parameters');

    my $info = {
        'query_parameters' => {
            'pageToken'                 => [ TYPE_STRING(),  1 ],
            'driveId'                   => [ TYPE_STRING(),  0 ],
            'fields'                    => [ TYPE_STRING(),  0 ],
            'includeCorpusRemovals'     => [ TYPE_BOOLEAN(), 0 ],
            'includeItemsFromAllDrives' => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'includeRemoved'            => [ TYPE_BOOLEAN(), 0 ],
            'includeTeamDriveItems'     => [ TYPE_BOOLEAN(), 0 ],
            'pageSize'                  => [ TYPE_INTEGER(), 0 ],
            'restrictToMyDrive'         => [ TYPE_BOOLEAN(), 0 ],
            'spaces'                    => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'teamDriveId'               => [ TYPE_STRING(),  0 ],
        },

        'parameter_checks' => {
            'spaces' => sub {
                /^( drive | appDataFolder | photos )$/xms
                  or return 'must be: drive|appDataFolder|photos';

                return 0;
            },
        },

        'path'        => 'changes',
        'http_method' => HTTP_METHOD_GET(),
        'method_name' => 'changes',
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub watch_changes {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 0 ],
        },

        'body_parameters' => [
            qw<
              kind
              id
              resourceId
              resourceUri
              token
              expiration
              type
              address
              payload
              params
            >
        ],

        'path'        => 'changes/watch',
        'http_method' => HTTP_METHOD_POST(),
        'method_name' => 'watch_changes',
    };

    $options->{'kind'} = 'api#channel';

    return $self->_handle_api_method( $info, $options );
}

# --- channels

###########################################
sub stop_channels {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('stop_channels() missing parameters');

    my $info = {
        'body_parameters' => [
            qw<
              kind
              id
              resourceId
              resourceUri
              token
              expiration
              type
              address
              payload
              params
            >
        ],

        'parameter_checks' => {
            'type' => sub {
                m{^web_?hook$}xms
                  or return 'must be: webhook|web_hook';

                return 0;
            },
        },

        'path'        => 'channels/stop',
        'http_method' => HTTP_METHOD_POST(),
        'method_name' => 'stop_channels',
    };

    $options->{'kind'} = 'api#channel';

    return $self->_handle_api_method( $info, $options );
}

# --- comments

###########################################
sub create_comment {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('create_comment() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('create_comment() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 1 ],
        },

        'body_parameters' => [
            qw<
              content
              anchor
              quotedFileContent
            >
        ],

        'path'        => "files/$fileId/comments",
        'method_name' => 'create_comment',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub delete_comment {
###########################################
    my ( $self, $fileId, $commentId ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('create_comment() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('create_comment() missing comment ID');

    my $info = {
        'path'        => "files/$fileId/comments/$commentId",
        'method_name' => 'delete_comment',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub get_comment {
###########################################
    my ( $self, $fileId, $commentId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('get_comment() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('get_comment() missing comment ID');

    ref $options eq 'HASH'
      or LOGDIE('get_comment() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields'         => [ TYPE_STRING(),  1 ],
            'includeDeleted' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/comments/$commentId",
        'method_name' => 'get_comment',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub comments {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('comments() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('comments() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields'            => [ TYPE_STRING(),  1 ],
            'includeDeleted'    => [ TYPE_BOOLEAN(), 0 ],
            'pageSize'          => [ TYPE_INTEGER(), 0 ],
            'pageToken'         => [ TYPE_STRING(),  0 ],
            'startModifiedTime' => [ TYPE_STRING(),  0 ],
        },

        'path'        => "files/$fileId/comments",
        'method_name' => 'comments',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub update_comment {
###########################################
    my ( $self, $fileId, $commentId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_comment() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('update_comment() missing comment ID');

    ref $options eq 'HASH'
      or LOGDIE('update_comment() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 1 ],
        },

        'body_parameters' => [
            qw<
              content
            >
        ],

        'path'        => "files/$fileId/comments/$commentId",
        'method_name' => 'update_comment',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    return $self->_update_api_method( $info, $options );
}

# --- files

###########################################
sub copy_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('copy_file() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('copy_file() missing parameters');

    # TODO: ocrLanguage is ISO 639-1 code

    my $info = {
        'query_parameters' => {
            'fields'                    => [ TYPE_STRING(),  0 ],
            'ignoreDefaultVisibility'   => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'keepRevisionForever'       => [ TYPE_BOOLEAN(), 0 ],
            'ocrLanguage'               => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              appProperties
              contentHints
              contentRestrictions
              copyRequiresWriterPermission
              description
              id
              mimeType
              modifiedTime
              name
              parents
              properties
              starred
              viewedByMeTime
              writersCanShare
            >
        ],

        'path'        => "files/$fileId/copy",
        'method_name' => 'copy_file',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, $options );
}

# Metadata only
###########################################
sub create_file {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('create_file() missing parameters');

    my $info = {
        'query_parameters' => {
            'enforceSingleParent'       => [ TYPE_BOOLEAN(), 0 ],
            'ignoreDefaultVisibility'   => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'keepRevisionForever'       => [ TYPE_BOOLEAN(), 0 ],
            'ocrLanguage'               => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'useContentAsIndexableText' => [ TYPE_BOOLEAN(), 0 ]
        },

        'body_parameters' => [
            qw<
              appProperties
              contentHints
              contentRestrictions
              copyRequiresWriterPermission
              createdTime
              description
              folderColorRgb
              id
              mimeType
              modifiedTime
              name
              originalFilename
              parents
              properties
              shortcutDetails.targetId
              starred
              viewedByMeTime
              writersCanShare
            >
        ],

        'path'        => 'files',
        'method_name' => 'create_file',
        'http_method' => HTTP_METHOD_POST(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] Creating files in multiple folders is no longer supported");
    }

    return $self->_update_api_method( $info, $options );
}

# Uploading file
###########################################
sub upload_file {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('upload_file() missing parameters');

    # TODO: Use this
    my $max_filesize = 5_120_000_000_000;    # 5120GB

    my $info = {
        'query_parameters' => {
            'uploadType'                => [ TYPE_STRING(),  1 ],
            'enforceSingleParent'       => [ TYPE_BOOLEAN(), 0 ],
            'ignoreDefaultVisibility'   => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'keepRevisionForever'       => [ TYPE_BOOLEAN(), 0 ],
            'ocrLanguage'               => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'useContentAsIndexableText' => [ TYPE_BOOLEAN(), 0 ]
        },

        'body_parameters' => [
            qw<
              appProperties
              contentHints
              contentRestrictions
              copyRequiresWriterPermission
              createdTime
              description
              folderColorRgb
              id
              mimeType
              modifiedTime
              name
              originalFilename
              parents
              properties
              shortcutDetails.targetId
              starred
              viewedByMeTime
              writersCanShare
            >
        ],

        'path'        => $self->{'api_upload_url'},
        'method_name' => 'upload_file',
        'http_method' => HTTP_METHOD_POST(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] Creating files in multiple folders is no longer supported");
    }

    return $self->_update_api_method( $info, $options );
}

###########################################
sub delete_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('delete_file() missing file ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'enforceSingleParent' => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'  => [ TYPE_BOOLEAN(), 0 ],
            'supportsAllDrives'   => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId",
        'method_name' => 'delete_file',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root");
    }

    return $self->http_json( $info, $options );
}

###########################################
sub export_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('export_file() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('export_file() missing parameters');

    my $info = {
        'query_parameters' => {
            'mimeType' => [ TYPE_STRING(), 1 ],
            'fields'   => [ TYPE_STRING(), 0 ],
        },

        'path'        => "files/$fileId/export",
        'method_name' => 'export_file',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub generateIds {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    my $info = {
        'query_parameters' => {
            'count'  => [ TYPE_INTEGER(), 0 ],
            'fields' => [ TYPE_STRING(),  0 ],
            'space'  => [ TYPE_STRING(),  0 ],
            'type'   => [ TYPE_STRING(),  0 ],
        },

        'parameter_checks' => {
            'spaces' => sub {
                /^( files | shortcuts )$/xms
                  or return 'must be: files|shortcuts';

                return 0;
            }
        },

        'path'        => 'files/generateIds',
        'method_name' => 'generateIds',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub get_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('get_file() missing file ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'acknowledgeAbuse'          => [ TYPE_BOOLEAN(), 0 ],
            'fields'                    => [ TYPE_STRING(),  0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId",
        'method_name' => 'get_file',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub files {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    # TODO: orderBy
    # 'createdTime', 'folder', 'modifiedByMeTime', 'modifiedTime', 'name', 'name_natural', 'quotaBytesUsed', 'recency', 'sharedWithMeTime', 'starred', and 'viewedByMeTime'.
    # ?orderBy=folder,modifiedTime desc,name

    # TODO: Steal the struct to query syntax from MetaCPAN::Client
    #       https://developers.google.com/drive/api/guides/search-files
    #if ( my $query_str = $options->{'q'} ) {...}

    my $info = {
        'query_parameters' => {
            'corpora'                   => [ TYPE_STRING(),  0 ],
            'corpus'                    => [ TYPE_STRING(),  0 ],    # deprecated
            'driveId'                   => [ TYPE_STRING(),  0 ],
            'fields'                    => [ TYPE_STRING(),  0 ],
            'includeItemsFromAllDrives' => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'includeTeamDriveItems'     => [ TYPE_BOOLEAN(), 0 ],    # deprecated
            'orderBy'                   => [ TYPE_STRING(),  0 ],
            'pageSize'                  => [ TYPE_INTEGER(), 0 ],
            'pageToken'                 => [ TYPE_STRING(),  0 ],
            'q'                         => [ TYPE_STRING(),  0 ],
            'spaces'                    => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],    # deprecated
            'teamDriveId'               => [ TYPE_STRING(),  0 ],    # deprecated
            'trashed'                   => [ TYPE_BOOLEAN(), 0 ],    # not documented
        },

        'parameter_checks' => {
            'corpora' => sub {
                /^( user | drive | domain | allDrives )$/xms
                  or return 'must be: user|drive|domain|allDrives';

                if ( $_ eq 'drive' ) {
                    defined $options->{'driveId'}
                      or return 'if corpora is drive, parameter driveId must be set';
                }

                return 0;
            },

            'corpus' => sub {
                /^( domain | user )$/xms
                  or return 'must be: domain|user';

                return 0;
            },

            'spaces' => sub {
                /^( drive | appDataFolder )$/xms
                  or return 'must be: drive|appDataFolder';

                return 0;
            },
        },

        'path'        => 'files',
        'method_name' => 'files',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

# Update with upload
###########################################
sub update_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_file() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('update_file() missing parameters');

    my $info = {
        'query_parameters' => {
            'uploadType'                => [ TYPE_STRING(),  1 ],
            'addParents'                => [ TYPE_STRING(),  0 ],
            'enforceSingleParent'       => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'keepRevisionForever'       => [ TYPE_BOOLEAN(), 0 ],
            'ocrLanguage'               => [ TYPE_STRING(),  0 ],
            'removeParents'             => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'useContentAsIndexableText' => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              appProperties
              contentHints
              contentRestrictions
              copyRequiresWriterPermission
              description
              folderColorRgb
              mimeType
              modifiedTime
              name
              originalFilename
              properties
              starred
              trashed
              viewedByMeTime
              writersCanShare
            >
        ],

        'path'        => $self->{'api_upload_file'} . "/$fileId",
        'method_name' => 'update_file',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] Adding files to multiple folders is no longer supported. Use shortcuts instead");
    }

    return $self->_handle_api_method( $info, $options );
}

# Metadata
###########################################
sub update_file_metadata {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_file_metadata() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('update_file_metadata() missing parameters');

    my $info = {
        'query_parameters' => {
            'addParents'                => [ TYPE_STRING(),  0 ],
            'enforceSingleParent'       => [ TYPE_BOOLEAN(), 0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'keepRevisionForever'       => [ TYPE_BOOLEAN(), 0 ],
            'ocrLanguage'               => [ TYPE_STRING(),  0 ],
            'removeParents'             => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'useContentAsIndexableText' => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              appProperties
              contentHints
              contentRestrictions
              copyRequiresWriterPermission
              description
              folderColorRgb
              mimeType
              modifiedTime
              name
              originalFilename
              properties
              starred
              trashed
              viewedByMeTime
              writersCanShare
            >
        ],

        'path'        => "files/$fileId",
        'method_name' => 'update_file_metadata',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] Adding files to multiple folders is no longer supported. Use shortcuts instead");
    }

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub watch_file {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('watch_file() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('watch_file() missing parameters');

    my $info = {
        'query_parameters' => {
            'acknowledgeAbuse'   => [ TYPE_BOOLEAN(), 0 ],
            'fields'             => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'  => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives' => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              kind
              id
              resourceId
              resourceUri
              token
              expiration
              type
              address
              payload
              params
            >
        ],

        'path'        => "files/$fileId/watch",
        'method_name' => 'watch_file',
        'http_method' => HTTP_METHOD_POST(),
    };

    $options->{'kind'} = 'api#channel';

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub empty_trash {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    my $info = {
        'query_parameters' => {
            'enforceSingleParent' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => 'files/trash',
        'method'      => 'empty_trash',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    if ( defined $options->{'enforceSingleParent'} ) {
        LOGDIE("[$info->{'method_name'}] If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root");
    }

    return $self->_handle_api_method( $info, {} );
}

# --- permissions

###########################################
sub create_permission {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('create_permission() missing file ID');

    ref $options eq 'HASH'
      or LOGDIE('create_permission() missing parameters');

    my $info = {
        'query_parameters' => {
            'emailMessage'          => [ TYPE_STRING(),  0 ],
            'enforceSingleParent'   => [ TYPE_BOOLEAN(), 0 ],
            'fields'                => [ TYPE_STRING(),  0 ],
            'moveToNewOwnersRoot'   => [ TYPE_BOOLEAN(), 0 ],
            'sendNotificationEmail' => [ TYPE_BOOLEAN(), 0 ],
            'supportsAllDrives'     => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'    => [ TYPE_BOOLEAN(), 0 ],
            'transferOwnership'     => [ TYPE_BOOLEAN(), 0 ],
            'useDomainAdminAccess'  => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              role
              type
              allowFileDiscovery
              domain
              emailAddress
              pendingOwner
              view
            >
        ],

        'deprecated_param_names' => {
            'enforceSingleParent' => 'moveToNewOwnersRoot',
        },

        'path'        => "files/$fileId/permissions",
        'method_name' => 'create_permission',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub delete_permission {
###########################################
    my ( $self, $fileId, $permissionId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('delete_permission() missing file ID');

    defined $permissionId && length $permissionId
      or LOGDIE('delete_permission() missing permission ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'supportsAllDrives'    => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'   => [ TYPE_BOOLEAN(), 0 ],
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/permissions/$permissionId",
        'method_name' => 'delete_permission',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub get_permission {
###########################################
    my ( $self, $fileId, $permissionId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('get_permission() missing file ID');

    defined $permissionId && length $permissionId
      or LOGDIE('get_permission() missing permission ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'fields'               => [ TYPE_STRING(),  0 ],
            'supportsAllDrivee'    => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'   => [ TYPE_BOOLEAN(), 0 ],
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/permissions/$permissionId",
        'method_name' => 'get_permission',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub permissions {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('permissions() missing file ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'fields'                    => [ TYPE_STRING(),  0 ],
            'includePermissionsForView' => [ TYPE_STRING(),  0 ],
            'pageSize'                  => [ TYPE_INTEGER(), 0 ],
            'pageToken'                 => [ TYPE_STRING(),  0 ],
            'supportsAllDrives'         => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'        => [ TYPE_BOOLEAN(), 0 ],
            'useDomainAdminAccess'      => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/permissions",
        'method_name' => 'permissions',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub update_permission {
###########################################
    my ( $self, $fileId, $permissionId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_permission() missing file ID');

    defined $permissionId && length $permissionId
      or LOGDIE('update_permission() missing permission ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'fields'               => [ TYPE_STRING(),  0 ],
            'removeExpiration'     => [ TYPE_BOOLEAN(), 0 ],
            'supportsAllDrives'    => [ TYPE_BOOLEAN(), 0 ],
            'supportsTeamDrives'   => [ TYPE_BOOLEAN(), 0 ],
            'transferOwnership'    => [ TYPE_BOOLEAN(), 0 ],
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/permissions/$permissionId",
        'method_name' => 'update_permission',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    return $self->_handle_api_method( $info, $options );
}

# --- replies

###########################################
sub create_reply {
###########################################
    my ( $self, $fileId, $commentId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('create_reply() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('create_reply() missing comment ID');

    ref $options eq 'HASH'
      or LOGDIE('create_reply() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 1 ],
        },

        'body_parameters' => [
            qw<
              action
              content
            >
        ],

        'parameter_checks' => {
            'action' => sub {
                m{^( resolve | reopen )$}xms
                  or return 'must be: resolve|reopen';

                return 0;
            },
        },

        'path'        => "files/$fileId/comments/$commentId/replies",
        'method_name' => 'create_reply',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub delete_reply {
###########################################
    my ( $self, $fileId, $commentId, $replyId ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('delete_reply() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('delete_reply() missing comment ID');

    my $info = {
        'path'        => "files/$fileId/comments/$commentId/replies/$replyId",
        'method_name' => 'delete_reply',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub get_reply {
###########################################
    my ( $self, $fileId, $commentId, $replyId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('get_reply() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('get_reply() missing comment ID');

    defined $replyId && length $replyId
      or LOGDIE('get_reply() missing reply ID');

    ref $options eq 'HASH'
      or LOGDIE('get_reply() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields'         => [ TYPE_STRING(),  1 ],
            'includeDeleted' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "files/$fileId/comments/$commentId/replies/$replyId",
        'method_name' => 'get_reply',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub replies {
###########################################
    my ( $self, $fileId, $commentId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('replies() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('replies() missing comment ID');

    ref $options eq 'HASH'
      or LOGDIE('replies() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields'         => [ TYPE_STRING(),  1 ],
            'includeDeleted' => [ TYPE_BOOLEAN(), 0 ],
            'pageSize'       => [ TYPE_INTEGER(), 0 ],
            'pageToken'      => [ TYPE_STRING(),  0 ],
        },

        'path'        => "files/$fileId/comments/$commentId/replies",
        'method_name' => 'replies',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub update_reply {
###########################################
    my ( $self, $fileId, $commentId, $replyId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_reply() missing file ID');

    defined $commentId && length $commentId
      or LOGDIE('update_reply() missing comment ID');

    defined $replyId && length $replyId
      or LOGDIE('update_reply() missing reply ID');

    ref $options eq 'HASH'
      or LOGDIE('update_reply() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 1 ],
        },

        'body_parameters' => {
            'content' => [ TYPE_STRING(), 1 ],
        },

        'path'        => "files/$fileId/comments/$commentId/replies/$replyId",
        'method_name' => 'update_reply',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    return $self->_handle_api_method( $info, $options );
}

# --- revisions

###########################################
sub delete_revision {
###########################################
    my ( $self, $fileId, $revisionId ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('delete_revision() missing file ID');

    my $info = {
        'path'        => "files/$fileId/revisions/$revisionId",
        'method_name' => 'delete_revision',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub get_revision {
###########################################
    my ( $self, $fileId, $revisionId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('get_revision() missing file ID');

    defined $revisionId && length $revisionId
      or LOGDIE('get_revision() missing revision ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'acknowledgeAbuse' => [ TYPE_BOOLEAN(), 0 ],
            'fields'           => [ TYPE_STRING(),  0 ],
        },

        'path'        => "files/$fileId/revisions/$revisionId",
        'method_name' => 'get_revision',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub revisions {
###########################################
    my ( $self, $fileId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('revisions() missing file ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'fields'    => [ TYPE_STRING(),  0 ],
            'pageSize'  => [ TYPE_INTEGER(), 0 ],
            'pageToken' => [ TYPE_STRING(),  0 ],
        },

        'path'        => "files/$fileId/revisions",
        'method_name' => 'revisions',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub update_revision {
###########################################
    my ( $self, $fileId, $revisionId, $options ) = @_;

    defined $fileId && length $fileId
      or LOGDIE('update_revision() missing file ID');

    defined $revisionId && length $revisionId
      or LOGDIE('update_revision() missing revision ID');

    ref $options eq 'HASH'
      or LOGDIE('update_revision() missing parameters');

    my $info = {
        'query_parameters' => {
            'fields' => [ TYPE_STRING(), 0 ],
        },

        'body_parameter' => [
            qw<
              keepForever
              publishAuto
              published
              publishedOutsideDomain
            >
        ],

        'path'        => "files/$fileId/revisions/$revisionId",
        'method_name' => 'update_revision',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    return $self->_handle_api_method( $info, $options );
}

# --- drives

###########################################
sub create_drive {
###########################################
    my ( $self, $options ) = @_;

    ref $options eq 'HASH'
      or LOGDIE('create_drive() missing parameters');

    my $info = {
        'query_parameters' => {
            'requestId' => [ TYPE_STRING(), 1 ],
        },

        'body_parameters' => {
            'name'    => [ TYPE_STRING(), 1 ],
            'themeId' => [ TYPE_STRING(), 0 ],
        },

        'path'        => 'drives',
        'method_name' => 'create_drive',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub delete_drive {
###########################################
    my ( $self, $driveId ) = @_;

    defined $driveId && length $driveId
      or LOGDIE('delete_drive() missing drive ID');

    my $info = {
        'path'        => "drives/$driveId",
        'method_name' => 'delete_drive',
        'http_method' => HTTP_METHOD_DELETE(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub get_drive {
###########################################
    my ( $self, $driveId, $options ) = @_;

    defined $driveId && length $driveId
      or LOGDIE('get_drive() missing drive ID');

    $options //= {};

    my $info = {
        'query_parameters' => {
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => "drives/$driveId",
        'method_name' => 'get_drive',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub hide_drive {
###########################################
    my ( $self, $driveId ) = @_;

    defined $driveId && length $driveId
      or LOGDIE('hide_drive() missing drive ID');

    my $info = {
        'path'        => "drives/$driveId/hide",
        'method_name' => 'hide_drive',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub drives {
###########################################
    my ( $self, $options ) = @_;

    $options //= {};

    my $info = {
        'query_parameters' => {
            'pageSize'             => [ TYPE_INTEGER(), 0 ],
            'pageToken'            => [ TYPE_STRING(),  0 ],
            'q'                    => [ TYPE_STRING(),  0 ],
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'path'        => 'drives',
        'method_name' => 'drives',
        'http_method' => HTTP_METHOD_GET(),
    };

    return $self->_handle_api_method( $info, $options );
}

###########################################
sub unhide_drive {
###########################################
    my ( $self, $driveId ) = @_;

    defined $driveId && length $driveId
      or LOGDIE('unhide_drive() missing drive ID');

    my $info = {
        'path'        => "drives/$driveId/unhide",
        'method_name' => 'unhide_drive',
        'http_method' => HTTP_METHOD_POST(),
    };

    return $self->_handle_api_method( $info, {} );
}

###########################################
sub update_drive {
###########################################
    my ( $self, $driveId, $options ) = @_;

    defined $driveId && length $driveId
      or LOGDIE('update_drive() missing drive ID');

    ref $options eq 'HASH'
      or LOGDIE('update_drive() missing parameters');

    my $info = {
        'query_parameters' => {
            'useDomainAdminAccess' => [ TYPE_BOOLEAN(), 0 ],
        },

        'body_parameters' => [
            qw<
              backgroundImageFile
              colorRgb
              name
              restrictions
              themeId
            >
        ],

        'path'        => "drives/$driveId",
        'method_name' => 'update_drive',
        'http_method' => HTTP_METHOD_PATCH(),
    };

    return $self->_handle_api_method( $info, $options );
}

# Helper methods

###########################################
sub children {
###########################################
    my ( $self, $path, $opts, $search_opts ) = @_;

    DEBUG("Determine children of $path");
    LOGDIE("No $path given") unless defined $path;

    $search_opts //= {};

    my ( $folder_id, $parent ) = $self->_path_resolve( $path, $search_opts );

    return unless defined $folder_id;

    DEBUG("Getting content of folder $folder_id");
    my $children = $self->children_by_folder_id( $folder_id, $opts, $search_opts ) or return;

    return $children;
}

# "'page' => 1" is now "'auto_paging' => 1"
###########################################
sub children_by_folder_id {
###########################################
    my ( $self, $folder_id, $opts, $search_opts ) = @_;

    $folder_id
      or LOGDIE("Must provide a folder id");

    $self->init();

    $search_opts = {} unless defined $search_opts;
    $opts        = {} unless defined $opts;

    exists $search_opts->{'page'}
      and LOGDIE("Search option 'page' is deprecated, use 'auto_paging'");

    exists $search_opts->{'title'}
      and LOGDIE("Search option 'title' is deprecated, set 'q' parameter accordingly");

    $search_opts->{'auto_paging'} //= 1;

    # Append or create a search in folder
    if ( defined $opts->{'q'} && length $opts->{'q'} ) {
        $opts->{'q'} .= ' AND ';
    }
    else {
        $opts->{'q'} = '';
    }

    $opts->{'q'} .= "'$folder_id' in parents";

    # Find only those not in the trash
    # possibly go through all paged results
    my @children;
    while (1) {
        my $data = $self->files($opts)
          or return;

        my @items = @{ $data->{'files'} || [] };

        while ( my $item = shift @items ) {
            if ( $item->{'labels'}{'trashed'} ) {
                DEBUG("Skipping $item->{'title'} (item in trash)");
                next;
            }

            # use the Item.pm object with AUTOLOAD, is_folder, and is_file
            # TODO: I dislke the AUTOLOAD format...
            push @children, $self->data_factory($item);
        }

        if ( $search_opts->{'auto_paging'} && $data->{'nextPageToken'} ) {
            $opts->{'pageToken'} = $data->{'nextPageToken'};
        }
        else {
            last;
        }
    }

    return \@children;
}

###########################################
sub _path_resolve {
###########################################
    my ( $self, $path, $search_opts );

    $search_opts = {} if !defined $search_opts;

    my @parts = grep length, split '/', $path;

    my @ids       = qw(root);
    my $folder_id = my $parent = 'root';
    DEBUG("Parent: $parent");

  PART:
    foreach my $part (@parts) {
        DEBUG("Looking up part $part (folder_id=$folder_id)");

        # We append to 'q' parameter in case the user provided it
        my $title = $part =~ s{\'}{\\\'}xmsgr;
        if ( defined $search_opts->{'q'} && length $search_opts->{'q'} ) {
            $search_opts->{'q'} .= ' AND ';
        }
        else {
            $search_opts->{'q'} = '';
        }
        $search_opts->{'q'} .= "title = '$title'";

        my $children = $self->children_by_folder_id( $folder_id, {}, $search_opts )
          or return;

        for my $child (@$children) {
            DEBUG("Found child: $child->{'title'}");

            if ( $child->{'title'} eq $part ) {
                $folder_id = $child->{'id'};
                unshift @ids, $folder_id;
                $parent = $folder_id;
                DEBUG("Parent: $parent");
                next PART;
            }
        }

        my $msg = "Child $part not found";
        $self->error($msg);
        ERROR($msg);
        return;
    }

    # parent of root is root
    if ( @ids == 1 ) {
        push @ids, $ids[0];
    }

    return @ids;
}

# TODO: Placed here until I have a use for it
#my %IMPORT_FORMATS = (
#    'application/x-vnd.oasis.opendocument.presentation'                         => ['application/vnd.google-apps.presentation'],
#    'text/tab-separated-values'                                                 => ['application/vnd.google-apps.spreadsheet'],
#    'image/jpeg'                                                                => ['application/vnd.google-apps.document'],
#    'image/bmp'                                                                 => ['application/vnd.google-apps.document'],
#    'image/gif'                                                                 => ['application/vnd.google-apps.document'],
#    'application/vnd.ms-excel.sheet.macroenabled.12'                            => ['application/vnd.google-apps.spreadsheet'],
#    'application/vnd.openxmlformats-officedocument.wordprocessingml.template'   => ['application/vnd.google-apps.document'],
#    'application/vnd.ms-powerpoint.presentation.macroenabled.12'                => ['application/vnd.google-apps.presentation'],
#    'application/vnd.ms-word.template.macroenabled.12'                          => ['application/vnd.google-apps.document'],
#    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'   => ['application/vnd.google-apps.document'],
#    'image/pjpeg'                                                               => ['application/vnd.google-apps.document'],
#    'application/vnd.google-apps.script+text/plain'                             => ['application/vnd.google-apps.script'],
#    'application/vnd.ms-excel'                                                  => ['application/vnd.google-apps.spreadsheet'],
#    'application/vnd.sun.xml.writer'                                            => ['application/vnd.google-apps.document'],
#    'application/vnd.ms-word.document.macroenabled.12'                          => ['application/vnd.google-apps.document'],
#    'application/vnd.ms-powerpoint.slideshow.macroenabled.12'                   => ['application/vnd.google-apps.presentation'],
#    'text/rtf'                                                                  => ['application/vnd.google-apps.document'],
#    'application/vnd.oasis.opendocument.spreadsheet'                            => ['application/vnd.google-apps.spreadsheet'],
#    'text/plain'                                                                => ['application/vnd.google-apps.document'],
#    'application/x-vnd.oasis.opendocument.spreadsheet'                          => ['application/vnd.google-apps.spreadsheet'],
#    'application/x-vnd.oasis.opendocument.text'                                 => ['application/vnd.google-apps.document'],
#    'image/png'                                                                 => ['application/vnd.google-apps.document'],
#    'application/msword'                                                        => ['application/vnd.google-apps.document'],
#    'application/pdf'                                                           => ['application/vnd.google-apps.document'],
#    'application/x-msmetafile'                                                  => ['application/vnd.google-apps.drawing'],
#    'application/vnd.openxmlformats-officedocument.spreadsheetml.template'      => ['application/vnd.google-apps.spreadsheet'],
#    'application/vnd.ms-powerpoint'                                             => ['application/vnd.google-apps.presentation'],
#    'application/vnd.ms-excel.template.macroenabled.12'                         => ['application/vnd.google-apps.spreadsheet'],
#    'image/x-bmp'                                                               => ['application/vnd.google-apps.document'],
#    'application/rtf'                                                           => ['application/vnd.google-apps.document'],
#    'application/vnd.openxmlformats-officedocument.presentationml.template'     => ['application/vnd.google-apps.presentation'],
#    'image/x-png'                                                               => ['application/vnd.google-apps.document'],
#    'text/html'                                                                 => ['application/vnd.google-apps.document'],
#    'application/vnd.oasis.opendocument.text'                                   => ['application/vnd.google-apps.document'],
#    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => ['application/vnd.google-apps.presentation'],
#    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'         => ['application/vnd.google-apps.spreadsheet'],
#    'application/vnd.google-apps.script+json'                                   => ['application/vnd.google-apps.script'],
#    'application/vnd.openxmlformats-officedocument.presentationml.slideshow'    => ['application/vnd.google-apps.presentation'],
#    'application/vnd.ms-powerpoint.template.macroenabled.12'                    => ['application/vnd.google-apps.presentation'],
#    'text/csv'                                                                  => ['application/vnd.google-apps.spreadsheet'],
#    'application/vnd.oasis.opendocument.presentation'                           => ['application/vnd.google-apps.presentation'],
#    'image/jpg'                                                                 => ['application/vnd.google-apps.document'],
#    'text/richtext'                                                             => ['application/vnd.google-apps.document']
#);
#
#my @ERXPORT_FORMATS = (
#    'application/vnd.google-apps.document' => [
#        'application/rtf',
#        'application/vnd.oasis.opendocument.text',
#        'text/html',
#        'application/pdf',
#        'application/epub+zip',
#        'application/zip',
#        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
#        'text/plain'
#    ],
#
#    'application/vnd.google-apps.spreadsheet' => [
#        'application/x-vnd.oasis.opendocument.spreadsheet',
#        'text/tab-separated-values',
#        'application/pdf',
#        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
#        'text/csv',
#        'application/zip',
#        'application/vnd.oasis.opendocument.spreadsheet'
#    ],
#
#    'application/vnd.google-apps.jam'        => ['application/pdf'],
#        'application/vnd.google-apps.script' => ['application/vnd.google-apps.script+json'],
#
#    'application/vnd.google-apps.presentation' => [
#        'application/vnd.oasis.opendocument.presentation',
#        'application/pdf',
#        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
#        'text/plain'
#    ],
#    'application/vnd.google-apps.form'    => ['application/zip'],
#    'application/vnd.google-apps.drawing' => [ 'image/svg+xml', 'image/png', 'application/pdf', 'image/jpeg' ],
#    'application/vnd.google-apps.site'    => ['text/plain']
#);

1;

__END__

=head1 SYNOPSIS

    my $gd_v3 = Net::Google::Drive::Simple->new( 'version' => 3 );
    # same as:
    my $gd_v3 = Net::Google::Drive::Simple::V3->new();

    $gd->changes(...);
    $gd->create_comment(...);
    $gd->delete_file(...);

=head1 DESCRIPTION

This is a complete implementation of the Google Drive API V3. You can
use all the documented methods below.

=head1 METHODS

=head2 C<new>

    my $gd = Net::Google::Drive::Simple::V3->new();

Create a new instance.

You can also create an instance using L<Net::Google::Drive::Simple>:

    my $gd = Net::Google::Drive::Simple->new( 'version' => 3 );

=head2 C<about>

    my $about = $gd->about({%params});

This serves the path to C</about>.

It's also referred to as C<about.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/about/get>.

=head2 C<getStartPageToken>

    my $data = $gd->getStartPageToken({%params});

This serves the path to C</changes/startPageToken>.

This is also known as C<changes_getStartPageToken>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/changes/getStartPageToken>.

=head2 C<changes>

    my $changes_list = $gd->changes({%params});

This serves the path to C</changes>.

This is also known as C<changes.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/changes/list>.

=head2 C<watch_changes>

    my $data = $gd->watch_changes({%params});

This serves the path to C</changes/watch>.

This is also known as C<changes.watch>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/changes/watch>.

=head2 C<stop_channels>

    $gd->stop_channels({%params});

This serves the path to C</channels/stop>.

This is also known as C<channels.stop>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/channels/stop>.

=head2 C<create_comment>

    my $comment = $gd->create_comment( $fileId, {%params} );

This serves the path to C</files/$fileId/comments>.

This is also known as C<comments.create>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/comments/create>.

=head2 C<delete_comment( $fileId, $commentId )>

    $gd->delete_comment( $fileId, $commentId );

This serves the path to C</files/$fileId/comments/$commentId>.

This is also known as C<comments.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/comments/delete>.

=head2 C<get_comment( $fileId, $commentId, $params )>

    my $comment = $gd->get_comment( $fileId, $commentId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId>.

This is also known as C<comments.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/comments/get>.

=head2 C<comments>

    my $comments = $gd->comments( $fileId, {%params} );

This serves the path to C</files/$fileId/comments>.

This is also known as C<comments.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/comments/list>.

=head2 C<update_comment>

    my $comment = $gd->update_comment( $fileId, $commentId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId>.

This is also known as C<comments.update>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/comments/update>.

=head2 C<copy_file>

    my $file = $gd->copy_file( $fileId, {%params} );

This serves the path to C</files/$fileId/copy>.

This is also known as C<files.copy>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/copy>.

=head2 C<create_file>

    my $file = $gd->create_file({%params});

This serves the path to C</files>.

This is also known as C<files.create>.

This one is for creating metadata for a file.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/create>.

=head2 C<upload_file>

    my $file = $gd->upload_file({%params});

This serves the path to C</files>.

This is also known as C<files.create>.

This one is for uploading a file, even though it shares a moniker with the
C<create_file()> method in the Google Drive API.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/create>.

=head2 C<delete_file>

    $gd->delete_file( $fileId, {%params} );

This serves the path to C</files/$fileId>.

This is also known as C<files.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/delete>.

=head2 C<export_file>

    my $file_content_in_bytes = $gd->export_file( $fileId, {%params} );

This serves the path to C</files/$fileId/export>.

This is also known as C<files.export>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/export>.

=head2 C<generateIds>

    my $data = $gd->generateIds({%params});

This serves the path to C</files/generateIds>.

This is also known as C<files.generateIds>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/generateIds>.

=head2 C<get_file>

    my $file = $gd->get_file( $fileId, {%params} );

This serves the path to C</files/$fileId>.

This is also known as C<files.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/get>.

=head2 C<files>

    my $files = $gd->files({%params});

This serves the path to C</files>.

This is also known as C<files.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/list>.

=head2 C<update_file>

    my $file = $gd->update_file( $fileId, {%params} );

This serves the path to C</files/$fileId>.

This is also known as C<files.update>.

This is for updating a file's metadata and content.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/update>.

=head2 C<update_file_metadata>

    my $file = $gd->update_file_metadata( $fileId, {%params} );

This serves the path to C</files/$fileId>.

This is also known as C<files.update>.

This one is only for updating a file's metadata, even though it shares
a moniker with the C<update_file()> method in the Google Drive API.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/update>.

=head2 C<watch_file>

    my $data = $gd->watch_file( $fileId, {%params} );

This serves the path to C</files/$fileId/watch>.

This is also known as C<files.watch>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/watch>.

=head2 C<empty_trash>

    $gd->empty_trash({%params})

This serves the path to C</files/trash>.

This is also known as C<files.emptyTrash>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/files/emptyTrash>.

=head2 C<create_permission>

    my $permission = $gd-><create_permission( $fileId, {%params} );

This serves the path to C</files/$fileId/permissions>.

This is also known as C<permissions.create>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/permissions/create>.

=head2 C<delete_permission>

    $gd->delete_permission( $fileId, $permissionId, {%params} );

This serves the path to C</files/$fileId/permissions/$permissionId>.

This is also known as C<permissions.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/permissions/delete>.

=head2 C<get_permission>

    my $permission = $gd->get_permission( $fileId, $permissionId, {%params} );

This serves the path to C</files/$fileId/permissions/$permissionId>.

This is also known as C<permissions.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/permissions/get>.

=head2 C<permissions>

    my $permissions = $gd->permissions( $fileId, {%params} );

This serves the path to C</files/$fileId/permissions>.

This is also known as C<permissions.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/permissions/list>.

=head2 C<update_permission>

    my $permission = $gd->update_permission( $fileId, $permissionId, {%params} );

This serves the path to C</files/$fileId/permissions/$permissionId>.

This is also known as C<permissions.update>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/permissions/update>.

=head2 C<create_reply>

    my $reply = $gd->create_reply( $fileId, $commentId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId/replies>.

This is also known as C<replies.create>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/replies/create>.

=head2 C<delete_reply( $fileId, $commentId, $replyId )>

    $gd->delete_reply( $fileId, $commentId, $replyId );

This serves the path to C</files/$fileId/comments/$commentId/replies/$replyId>.

This is also known as C<replies.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/replies/delete>.

=head2 C<get_reply>

    my $reply = %gd->get_reply( $fileId, $commentId, $replyId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId/replies/$replyId>.

This is also known as C<replies.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/replies/get>.

=head2 C<replies>

    my $replies = $gd->replies( $fileId, $commentId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId/replies>.

This is also known as C<replies.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/replies/list>.

=head2 C<update_reply>

    my $reply = $gd->update_reply( $fileId, $commentId, $replyId, {%params} );

This serves the path to C</files/$fileId/comments/$commentId/replies/$replyId>.

This is also known as C<replies.update>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/replies/update>.

=head2 C<delete_revision>

    $gd->delete_revision( $fileId, {%params} );

This serves the path to C</files/$fileId/revisions/$revisionId>.

This is also known as C<revisions.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/revisions/delete>.

=head2 C<get_revision( $fileId, $revisionId, $params )>

    my $revision = $gd->get_revision( $fileId, $revisionId, {%params} );

This serves the path to C</files/$fileId/revisions/$revisionId>.

This is also known as C<revisions.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/revisions/get>.

=head2 C<revisions>

    my $revisions = $gd->revisions( $fileId, {%params} );

This serves the path to C</files/$fileId/revisions>.

This is also known as C<revisions.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/revisions/list>.

=head2 C<update_revision>

    my $revision = $gd->update_revision( $fileId, $revisionId, {%params} );

This serves the path to C</files/$fileId/revisions/$revisionId>.

This is also known as C<revisions.update>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/revisions/update>.

=head2 C<create_drive>

    my $drive = $gd->create_drive({%params});

This serves the path to C</drives>.

This is also known as C<drives.create>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/create>.

=head2 C<delete_drive>

    $gd->delete_drive($driveId);

This serves the path to C</drives/$driveId>.

This is also known as C<drives.delete>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/delete>.

=head2 C<get_drive>

    my $drive = $gd->get_drive( $driveId, {%params} );

This serves the path to C</drives/$driveId>.

This is also known as C<drives.get>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/get>.

=head2 C<hide_drive>

    my $drive = $gd->hide_drive($driveId);

This serves the path to C</drives/$driveId/hide>.

This is also known as C<drives.hide>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/hide>.

=head2 C<drives>

    my $drives = $gd->drives({%params});

This serves the path to C</drives>.

This is also known as C<drives.list>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/list>.

=head2 C<unhide_drive>

    my $drive = $gd->unhide_drive($driveId);

This serves the path to C</drives/$driveId/unhide>.

This is also known as C<drives.unhide>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/unhide>.

=head2 C<update_drive>

    my $drive = $gd->update_drive( $driveId, {%params} );

This serves the path to C</drives/$driveId>.

This is also known as C<drives.update>.

You can read about the parameters on the Google Drive
L<API page|https://developers.google.com/drive/api/v3/reference/drives/update>.

=head2 C<children>

    my $children = $gd->children( "/path/to" )>

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

    https://developers.google.com/drive/v3/reference/files#resource

for details on which fields are available.

=head2 C<children_by_folder_id>

    my $children = $gd->children_by_folder_id($folderId);

    # Search with a particular query and stop at the first page
    my $children = $gd->children_by_folder_id(
        $folderId,
        { 'q' => q{name contains 'hello'} },
        { 'auto_paging' => 0 },
    );

Similar to C<children()> but uses a folder ID.

The second parameter is the parameters the C<files()> method receives.

The third parameter is for additional options on how to conduct this
search. Only one option is supported: C<auto_paging>.

When C<auto_paging> is turned on (which is the default), the search
will be done on every page of the results instead of stopping at the
first page.

=head1 LEGALESE

Copyright 2012-2019 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>
