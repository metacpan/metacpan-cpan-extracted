package Rapi::Blog::Module::PageBase;

use strict;
use warnings;

use Moose;
extends 'RapidApp::Module::DbicPropPage';

use RapidApp::Util ':all';
use Rapi::Blog::Util;


before 'content' => sub { (shift)->apply_permissions };

sub apply_permissions {
  my $self = shift;
  my $c = RapidApp->active_request_context or return;
  
  # System 'administrator' role trumps everything:
  return if ($c->check_user_roles('administrator'));
  
  my $uid = Rapi::Blog::Util->get_uid  or return $self->_perm_deny_all_changes;
  my $reqRow = $self->req_Row          or return $self->_perm_deny_all_changes;
  
  my $source_name = $self->ResultSource->source_name;
  
  # Note: 'Post' has its own module so isn't listed here
  if($source_name eq 'Comment') {
    if($reqRow->user_id == $uid) {
      # Allow user to edit their own comments but only for these columns:
      my @edit_cols = qw/body/;
      $self->apply_except_colspec_columns(\@edit_cols,
        allow_add => 0,
        allow_edit => 0
      );
    }
    else {
      # Deny all changes except to the user's own comments:
      $self->_perm_deny_all_changes;
    }
  
  }
  elsif($source_name eq 'User') {
    if($reqRow->id == $uid) {
      # Allow user to edit their own account but only for these columns:
      my @edit_cols = qw/username full_name set_pw/;
      $self->apply_except_colspec_columns(\@edit_cols,
        allow_add => 0,
        allow_edit => 0
      );
      
      
    
    }
    else {
      # Deny all changes except to the user's own account:
      $self->_perm_deny_all_changes;
      
      # And deny 
      my @deny_columns = qw/email admin author comment disabled set_pw preauth_actions/;
      $self->apply_colspec_columns(\@deny_columns, no_column => 1);
    }
  }
  else {
    # Deny all changes unless otherwise specified
    $self->_perm_deny_all_changes;
  }

}


sub _perm_deny_all_changes {
  my $self = shift;
  $self->apply_to_all_columns( allow_add => 0, allow_edit => 0 );
}

1;

