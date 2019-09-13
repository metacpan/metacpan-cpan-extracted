package Rapi::Blog::Util;

use strict;
use warnings;

use RapidApp::Util ':all';

use DateTime;

sub _dt_base_opts {(
  time_zone => 'local'
)}

sub now_ts { &dt_to_ts( &now_dt ) }
sub now_dt { DateTime->now( &_dt_base_opts ) }

sub dt_to_ts {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $dt = shift;
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

# This is overkill and probably silly; I wrote it to be able to rule out possible time-zone
# inflate/deflate conversion issues. As a sanity check, I can always compare apples to 
# apples with the DateTime/db-date-string conversion funcs in this package
sub ts_to_dt {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $ts = shift;
  length($ts) == 19 or die "Bad timestamp '$ts' - should be exactly 19 characters long (YYYY-MM-DD hh:mm:ss)";
  
  my ($date,$time) = split(/\s/,$ts,2);
  length($date) == 10 or die "Bad date part '$date' - should be exactly 10 characters long (YYYY-MM-DD)";
  length($time) == 8  or die "Bad time part '$time' - should be exactly 8 characters long (hh:mm:ss)";
  
  my @d = split(/\-/,$date);
  my @t = split(/\:/,$time);
  scalar(@d) == 3 or die "Bad date part '$date' - didn't split ('-') into exactly 3 items";
  scalar(@t) == 3 or die "Bad time part '$time' - didn't split (':') into exactly 3 items";
  
  my %o = ( &_dt_base_opts );
  ($o{year},$o{month},$o{day},$o{hour},$o{minute},$o{second}) = (@d,@t);
  
  DateTime->new(%o)
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


sub get_scaffold_cfg {
  if(my $c = RapidApp->active_request_context) {
    return try{$c->template_controller->Access->scaffold_cfg};
  }
  return undef;
}

1;
