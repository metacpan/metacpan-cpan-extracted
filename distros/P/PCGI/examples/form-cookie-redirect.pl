#!/usr/bin/perl -w

use strict;
use PCGI qw(:all);

my $q = PCGI->new();

if( $q->env('REQUEST_METHOD') eq 'POST' ) {
  if( $q->errstr ) {
    $q->header( content_type => 'text/plain' );
    $q->sendheader;
    print $q->errstr; # fatal request error
  } else {
      # Get POST parameter 'color' and set cookie
    my $color = $q->POST('color');
    if( defined $color ) {
      $q->setcookie( color => $color );
    }
    $q->header( location => $q->env('SCRIPT_NAME') );
    $q->sendheader;
  }
} else {
  $q->sendheader;

  print qq{<HTML>\n};

  my $color = $q->COOKIE('color');
  if( defined $color ) {
    print qq{<BODY bgcolor=$color>\n};
  } else {
    print qq{<BODY>\n};
  }

  print qq{<FORM action="" method=POST>\n};
  print qq{Select color <SELECT name=color>\n};
  print qq{<OPTION value="">\n};
  print qq{<OPTION value=green>green\n};
  print qq{<OPTION value=blue>blue\n};
  print qq{<OPTION value=yellow>yellow\n};
  print qq{</SELECT>\n};
  print qq{<INPUT type=submit value="Sumbit">\n};
  print qq{</FORM>\n};
  print qq{</BODY>\n};
  print qq{</HTML>\n};
}
