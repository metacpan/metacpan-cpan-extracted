package Net::OBS::LWP::UserAgent;

use strict;
use warnings;
use Const::Fast;
use Carp;

use base 'LWP::UserAgent';

const my $MTIME_POS => 9;
const my $FILE_LENGTH_POS => 7;
const my $FILE_MODE_RW_ALL => '0777';

sub sigauth_credentials {
  my ($self, $creds) = @_;
  die "Credentials a not a HASH Ref!" if $creds && ref($creds) ne 'HASH';
  $self->{sigauth_credentials} = $creds if $creds;
  return $self->{sigauth_credentials};
}

sub mirror
{
    my($self, %opt) = @_;
    my $url         = $opt{url};
    my $file        = $opt{file};
    my $etag        = $opt{etag};

    my $request = $opt{request} || HTTP::Request->new('GET', $url);

    $self->prepare_cache_related_headers($request, %opt);

    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    croak($response->header('X-Died')) if $response->header('X-Died');

    # Only fetching a fresh copy of the would be considered success.
    # If the file was not modified, "304" would returned, which
    # is considered by HTTP::Status to be a "redirect", /not/ "success"
    if ( $response->is_success ) {
        my @stat        = stat $tmpfile or croak("Could not stat tmpfile '$tmpfile': $!");
        my $file_length = $stat[$FILE_LENGTH_POS];
        my ($content_length) = $response->header('Content-length');

        if ( defined $content_length and $file_length < $content_length ) {
            unlink $tmpfile || croak("Could not unlink $tmpfile: $!\n");
            croak("Transfer truncated: only $file_length out of $content_length bytes received\n");
        }
        elsif ( defined $content_length and $file_length > $content_length ) {
            unlink $tmpfile || croak("Could not unlink $tmpfile: $!\n");
            croak("Content-length mismatch: expected $content_length bytes, got $file_length\n");
        }
        # The file was the expected length.
        else {
            # Replace the stale file with a fresh copy
            if ( -e $file ) {
                # Some DOSish systems fail to rename if the target exists
                chmod $FILE_MODE_RW_ALL, $file
                  || croak("Cannot change mode for '$file': $!\n");
                unlink $file || croak("Could not unlink $file: $!\n");
            }
            rename $tmpfile, $file
                or croak("Cannot rename '$tmpfile' to '$file': $!\n");

            # make sure the file has the same last modification time
            if ( my $lm = $response->last_modified ) {
                utime $lm, $lm, $file || croak("Cannot set utime for '$file': $!\n");
            }
        }
    }
    # The local copy is fresh enough, so just delete the temp file
    else {
        unlink $tmpfile || croak("Could not unlink $tmpfile: $!\n");
    }
    return $response;
}

sub prepare_cache_related_headers {
    my ($self, $request, %opt) = @_;
    my $file        = $opt{file};
    my $etag        = $opt{etag};

    # If the file exists, add a cache-related header
    if ( -e $file ) {
        my ($mtime)   = ( stat $file )[$MTIME_POS];
        if ($etag) {
          $request->header('If-None-Match' => $etag);
          $self->default_header('If-None-Match' => $etag);
        } elsif ($mtime) {
          my $http_date = HTTP::Date::time2str($mtime);
          $request->header('If-Modified-Since' => $http_date);
          $self->default_header('If-Modified-Since' => $http_date);
        }
    }

    return;
}

1;
