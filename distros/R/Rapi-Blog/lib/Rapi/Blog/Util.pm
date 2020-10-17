package Rapi::Blog::Util;

use strict;
use warnings;

use RapidApp::Util ':all';

use DateTime;
use HTTP::Request::Common;
use LWP::UserAgent;
use Rapi::Blog::Util::ppRender;

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


sub recaptcha_active {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $c = shift || RapidApp->active_request_context or return 0;
  
  my $cfg = $c->ra_builder->recaptcha_config;
  
  # When 'strict_mode' is active, we force recaptcha verification in all places it is supported
  # (i.e. force ->opportunistic_recaptcha_verify to behave the same as ->recaptcha_verify)
  # This prevents circumventing recaptcha validation by clients constructing their own POST request.
  # The downside is that if front-side templates fail to properly enable the reCAPTCHA client side 
  # setup, the associated forms will always fail to submit because reCAPTCHA will always fail
  return 1 if ($cfg->{strict_mode});

     $cfg->{public_key}
  && $cfg->{private_key}
  && $c->req->method eq 'POST'
  && exists $c->req->params->{'g-recaptcha-response'}
}

# opportunistic_recaptcha_verify only runs, and possibly fails, if all the needed reCAPTCHA pieces
# are active. When 'strict_mode' is turned on, this method behaves the same as recaptcha_verify.
# See the POD for more information of 'strict_mode'
sub opportunistic_recaptcha_verify {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $c = shift || RapidApp->active_request_context or return 1;
  &recaptcha_active($c) ? &recaptcha_verify($c) : 1
}


sub recaptcha_verify {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $c = shift || RapidApp->active_request_context;
  
  &recaptcha_active($c) or return 0;
  
  my $cfg  = $c->ra_builder->recaptcha_config;

  my $packet = {
    secret   => $cfg->{private_key},
    response => $c->req->params->{'g-recaptcha-response'},
    #remoteip => $c->req->address
  };
  my $content_payload = join('&',map { join('=',$_,$packet->{$_}) } keys %$packet);
  
  my $url  = $cfg->{verify_url} || 'https://www.google.com/recaptcha/api/siteverify';
  
  # for refernece, this is how to turn of certificate validation, which should not be needed
  # as long as the remote endpoint is a Google system
  #local $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
  
  my $ua = LWP::UserAgent->new;
  $ua->agent('rapi-blog/' . $Rapi::Blog::VERSION);
  $ua->timeout(30); # 30 seconds

  my $req = HTTP::Request->new( 'POST', $url );
  $req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
  $req->content( $content_payload );

  $c->log->info('Validating reCAPTCHA: POST -> '.$url);
  my $res = $ua->request($req);

  if($res->is_success) {
    my $data = decode_json_utf8( $res->decoded_content );

    my $success = $data->{success};
    $success = $$success if (ref($success)||'' eq 'SCALAR');
    
    return $success ? 1 : 0
  }
  else {
    $c->log->error('reCAPTCHA validation failed');
    return 0;
  }
}

sub sanitize_input {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $content = shift;
  
  my $c = RapidApp->active_request_context or die join('',
    'Failed to obtain request context $c - ',
    'sanitize_input() can only be called during a request'
  );
  
  my $Scrubber = $c->ra_builder->input_Scrubber or die "Failed to load HTML::Scrubber object";
  
  $Scrubber->scrub( $content )
}

1;
