package TaskForest::REST;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

sub methodNotAllowed {
    my ($hash, $allow) = @_;

    $hash->{response_headers}->header("Allow",  $allow);
    $hash->{http_status} = RC_METHOD_NOT_ALLOWED;
    $hash->{http_content} = '';

}

# 'correct' GET functionality.
# needs a reference to a check_existence and get_modified_tags() and a get_content() function
sub GET {
    my ($q, $parent_hash, $h, $hash, $resource_functions) = @_;

    my $exists                 = $resource_functions->{check_existence}->($q, $parent_hash, $h, $hash);

    if (!$exists) {
        $parent_hash->{http_status} = RC_NOT_FOUND;
        $parent_hash->{content} = "404 - Not Found";
        return;
    }
    
    my ($last_modified, $etag) = $resource_functions->{get_modified_tags}->($q, $parent_hash, $h, $hash);
    my $if_modified_since      = $parent_hash->{request_headers}->if_modified_since;
    my $if_none_match          = $parent_hash->{request_headers}->header('if-none-match');
    
    if (
        ($if_modified_since && $last_modified <= $if_modified_since)
        ||
        ($if_none_match     && $etag eq $if_none_match)
        ) {
        # don't need to send anything back;
        $parent_hash->{http_content} = "";
        $parent_hash->{http_status} = RC_NOT_MODIFIED;
        $parent_hash->{response_headers}->last_modified($last_modified);
        $parent_hash->{response_headers}->header('ETag', $etag);
        $parent_hash->{response_headers}->header('Cache-Control', 'Public');
        return;
    }

    # get the contents and populate the hash as needed
    $resource_functions->{get_content}->($q, $parent_hash, $h, $hash);
    $parent_hash->{http_status} = RC_OK;
    $parent_hash->{response_headers}->last_modified($last_modified);
    $parent_hash->{response_headers}->header('ETag', $etag);
    $parent_hash->{response_headers}->header('Cache-Control', 'Public');
}


# 'correct' HEAD functionality.
# needs a reference to a check_existence and get_modified_tags() function
sub HEAD {
    my ($q, $parent_hash, $h, $hash, $resource_functions) = @_;

    my $exists                 = $resource_functions->{check_existence}->($q, $parent_hash, $h, $hash);

    if (!$exists) {
        $parent_hash->{http_status} = RC_NOT_FOUND;
        $parent_hash->{content} = "404 - Not Found";
        return;
    }
    
    my ($last_modified, $etag) = $resource_functions->{get_modified_tags}->($q, $parent_hash, $h, $hash);
    my $if_modified_since      = $parent_hash->{request_headers}->if_modified_since;
    my $if_none_match          = $parent_hash->{request_headers}->header('if-none-match');
    
    if (
        ($if_modified_since && $last_modified <= $if_modified_since)
        ||
        ($if_none_match     && $etag eq $if_none_match)
        ) {
        # don't need to send anything back;
        $parent_hash->{http_content} = "";
        $parent_hash->{http_status} = RC_NOT_MODIFIED;
        $parent_hash->{response_headers}->last_modified($last_modified);
        $parent_hash->{response_headers}->header('ETag', $etag);
        return;
    }

    # get the contents and populate the hash as needed
    $parent_hash->{http_content} = '';
    $parent_hash->{http_status} = RC_OK;
    $parent_hash->{response_headers}->last_modified($last_modified);
    $parent_hash->{response_headers}->header('ETag', $etag);
}



# 'correct' PUT functionality.
# needs a the following funcitons :
#  get content
#  put content
#  get_modified_tags
sub PUT {
    my ($q, $parent_hash, $h, $hash, $resource_functions) = @_;


    my $status = $resource_functions->{put_content}->($q, $parent_hash, $h, $hash);
    $parent_hash->{http_status} = $status;  # not 201 CREATED because we want it to look just like an update
 
    return unless $status == RC_OK;
    
    my ($last_modified, $etag) = $resource_functions->{get_modified_tags}->($q, $parent_hash, $h, $hash);

    # get the contents and populate the hash as needed
    $resource_functions->{get_content}->($q, $parent_hash, $h, $hash);
    $parent_hash->{response_headers}->last_modified($last_modified);
    $parent_hash->{response_headers}->header('ETag', $etag);
}

# 'correct' DELETE functionality.
# needs a the following funcitons :
#  delete_resource
sub DELETE {
    my ($q, $parent_hash, $h, $hash, $resource_functions) = @_;


    $hash->{http_status} = $resource_functions->{delete_resource}->($q, $parent_hash, $h, $hash);
    $hash->{http_content} = '';
}


sub deleteFile {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $file_name = $hash->{_resource_file_name};

    unlink $file_name;

    
    if (-e $file_name) {
        $parent_hash->{http_content} = "500 - Internal Server Error";
        return RC_INTERNAL_SERVER_ERROR;
    }
    return RC_NO_CONTENT;
}



sub checkExistenceForFile {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $file_name = $hash->{_resource_file_name};

    return -e $file_name;
}



sub getModifiedTagsForFile {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $file_name = $hash->{_resource_file_name};

    my @stat = stat($file_name);
    my $last_modified = $stat[9];
    my $etag = $stat[7].$stat[9];

    return ($last_modified, $etag);
}


sub getContentForTextFile {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $file_name = $hash->{_resource_file_name};

    if (open (F, "$file_name")) {
        my @lines = <F>;
        close F;

        $hash->{file_contents}  = join("", map { s/\r//; $_; } @lines);
        $hash->{full_file_name} = $file_name;
    }
}    


sub putContentForTextFile {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $file_name = $hash->{_resource_file_name};

    if (!defined($h->{file_contents})) {
        return RC_BAD_REQUEST;
    }

    if (open (F, ">$file_name")) {
        $h->{file_contents} =~ s/\r//g;
        print F $h->{file_contents};
        close F;
        return RC_OK;
    }
    else {
        $parent_hash->{http_content} = "500 - Internal Server Error";
        return RC_INTERNAL_SERVER_ERROR;
    }
}    

sub getDirListing {
    my ($q, $parent_hash, $h, $hash) = @_;
    my $dir = $hash->{_resource_file_name};

    if (opendir(DIR, $dir)) {
        my @files = grep { -f "$dir/$_" } readdir(DIR);
        closedir DIR;
        my $n0 = 0;
        foreach my $file (@files) {
            push (@{$hash->{files}}, { file_name => $file,
                                       n0        => $n0,
                                       n1        => $n0 + 1,
                                       oddeven   => !($n0 % 2),
                  });
        }
        $hash->{no_files} = (@{$hash->{files}})? 1 : 0;
    }
}
    


                

1;
