#!/usr/bin/perl -w

use strict;
use PCGI qw(:all);

my $upload_dir = '/upload/dir'; # must be writable

my $q = PCGI->new();

$q->sendheader;

print qq{<HTML>\n};
print qq{<BODY>\n};
print qq{<FORM action="" enctype=multipart/form-data method=POST>\n};
print qq{Select file <INPUT type=file name=file>\n};
print qq{<INPUT type=submit value="Sumbit">\n};
print qq{</FORM>\n};
print qq{<HR>\n};

if( $q->env('REQUEST_METHOD') eq 'POST' ) {
  if( $q->errstr ) {
    print $q->errstr, "<br>\n"; # fatal request error
  } else {
    my $file = $q->FILE('file');
    if( $file ) {
        # Showing all available information about file
      print qq{Client filename: <b>$file->{full}</b><br>\n};
      print qq{Basename of client filename: <b>$file->{base}</b><br>\n};
      print qq{File real size: <b>$file->{size}</b><br>\n};
      print qq{File real path: <b>$file->{temp}</b><br>\n};
      print qq{Possible MIME type: <b>$file->{mime}</b><br>\n};
      print qq{<hr>\n};
        # Trying to move file
      my $new_path = $upload_dir.'/'.$file->{base};
      if( rename $file->{temp}, $new_path ) {
        print qq{Successfuly moved to $new_path<br>\n};
      } else {
        print qq{Can't move $file->{temp} to $new_path<br>\n};
      }
    }
  }
}

print qq{</BODY>\n};
print qq{</HTML>\n};
