package Rapi::Blog::Util;

use strict;
use warnings;

use RapidApp::Util ':all';

use DateTime;

sub now_ts {
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub get_uid {
  if(my $c = RapidApp->active_request_context) {
    return $c->user->linkedRow->id if ($c->can('user') && $c->user && $c->user->linkedRow);
  }
  return 0;
}

sub get_User {
  if(my $c = RapidApp->active_request_context) {
    return $c->user->linkedRow if ($c->can('user') && $c->user);
  }
  return undef;
}

1;
