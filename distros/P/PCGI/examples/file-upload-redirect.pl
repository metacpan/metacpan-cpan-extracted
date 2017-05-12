#!/usr/bin/perl -w

use strict;
use PCGI qw(:all);

my $upload_dir = '/upload/dir'; # must be writable

my $q = PCGI->new();

if( $q->env('REQUEST_METHOD') eq 'POST' ) {
  if( $q->errstr ) {
    $q->header( content_type => 'text/plain' );
    $q->sendheader;
    print $q->errstr; # fatal request error
  } else {
      # Trying to move file
    my $mess;
    my $file = $q->FILE('file');
    if( defined $file ) {
      my $new_path = $upload_dir.'/'.$file->{base};
      if( rename $file->{temp}, $new_path ) {
        $mess = "Successfuly uploaded to $new_path";
      } else {
        $mess = "Can't move $file->{temp} to $new_path";
      }
    }
    $q->header( location => $q->env('SCRIPT_NAME').( $mess? '?mess='.urlencode($mess) : '' ) );
    $q->sendheader;
  }
} else {
  $q->sendheader;

  print qq{<HTML>\n};
  print qq{<BODY>\n};
  print qq{<FORM action="" enctype=multipart/form-data method=POST>\n};
  print qq{Select file <INPUT type=file name=file>\n};
  print qq{<INPUT type=submit value="Sumbit">\n};
  print qq{</FORM>\n};
  print qq{<HR>\n};

  # Showing message
  my $mess = $q->GET('mess');
  if( defined $mess ) {
    print qq{$mess<br>\n};
  }

  print qq{</BODY>\n};
  print qq{</HTML>\n};
}
