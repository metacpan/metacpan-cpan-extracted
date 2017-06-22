package Rapi::Blog::Module::PostPage;

use strict;
use warnings;

use Moose;
extends 'RapidApp::Module::DbicRowDV';

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use Path::Class qw(file dir);

has '+template', default => 'templates/dv/postview.html';

has '+tt_include_path', default => sub {
  my $self = shift;
  dir( $self->app->ra_builder->share_dir )->stringify;
};

has '+destroyable_relspec', default => sub {['*']};
has '+close_on_destroy'   , default => 1;
has '+confirm_on_destroy',  default => 0;

before 'content' => sub { (shift)->apply_permissions };

sub apply_permissions {
  my $self = shift;
  my $c = RapidApp->active_request_context or return;
  
  # System 'administrator' role trumps everything:
  return if ($c->check_user_roles('administrator'));

  my $Post = $self->req_Row or return;
  
  my @excl = ('create');
  
  if($Post->can_modify) {
    $Post->can_change_author or $self->apply_columns({ author => { allow_edit => 0 } });
  }
  else {
    push @excl, 'update';
  }
  
  $Post->can_delete or push @excl, 'destroy';
  
  $self->apply_extconfig( store_exclude_api => \@excl );
}


1;

