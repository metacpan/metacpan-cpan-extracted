package Rapi::Blog::CatalystApp;
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Common Catalyst plugin loaded on all Rapi::Blog apps

use strict;
use warnings;

use RapidApp::Util qw(:all);


around 'authenticate' => sub {
  my ($orig, $c, @args) = @_;
  
  my $opt = $args[0];
  if((ref($opt)||'') eq 'HASH' && $opt->{username}) {
    my $User = $c->model('DB::User')->search_rs({ 'me.username' => $opt->{username} })->first;
    if ($User && $User->has_column('disabled') && $User->disabled) {
      $c->log->debug("Denied login for '$opt->{username}' -- account disabled");
      return 0;
    }
  }
  
  $c->$orig(@args);

};



1;