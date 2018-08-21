package Rapi::Blog::Module::SectionTree;
use strict;
use warnings;
use Moose;
extends 'RapidApp::Module::Tree';

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

has '+root_node_text',      default => 'Sections';
has '+show_root_node',      default => 1;
has '+fetch_nodes_deep',    default => 1;
has '+use_contextmenu',     default => 1;
has '+no_dragdrop_menu',    default => 1;
has '+setup_tbar',          default => 1;
has '+no_recursive_delete', default => 0;

has '+add_button_text',       default => 'Add Section';
has '+add_button_iconCls',    default => 'icon-folder-add';
has '+delete_button_text',    default => 'Delete Section';
has '+delete_button_iconCls', default => 'icon-folder-delete';

sub BUILD {
  my $self = shift;
  
  $self->root_node->{iconCls} = 'icon-sitemap-color';
  
  $self->apply_extconfig(
    tabTitle   => 'Manage Sections',
    tabIconCls => 'icon-sitemap-color',
    border     => \1,
    autoScroll => \1
  );

}

sub is_admin {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User;
  $User && $User->admin ? 1 : 0
}

around 'content' => sub {
  my ($orig, $self, @args) = @_;
  my $cfg = $self->$orig(@args);
  
  unless ($self->is_admin) {
    my @ops = qw/add delete rename copy move/;
    $cfg->{$_.'_node_url'} = undef for (@ops);
  }

  return $cfg
};


sub get_node_id {
  my ($self, $node) = @_;
  
  my $id = (reverse split(/\//,$node))[0];
  $id = undef if ($id eq $self->root_node_name);

  $id
}

sub Rs  { (shift)->c->model('DB::Section') }
sub pRs { (shift)->c->model('DB::Post')    }

sub Sections_of {
  my ($self, $id) = @_;
  $self->Rs
    ->search_rs({ 'me.parent_id' => $id })
    ->all
}

sub Posts_of {
  my ($self, $id) = @_;
  $self->pRs
    ->search_rs({ 'me.section_id' => $id })
    ->all
}

sub get_Section {
  my ($self, $id) = @_;
  $self->Rs->find($id)
}

sub get_Post {
  my ($self, $id) = @_;
  $self->pRs->find($id)
}

sub get_post_id {
  my ($self, $id) = @_;
  my ($junk,$post_id) = split(/^p-/,$id,2);
  $post_id
}

sub fetch_nodes {
  my ($self, $node) = @_;
  
  my $id = $self->get_node_id($node);
  
  my @nodes = ();
  
  push @nodes, { 
    id               => 'unsectioned', 
    text             => '<i style="opacity:0.6;">unsectioned</i>',
    iconCls          => 'icon-outbox',
    allowAdd         => \0,
    rootValidActions => \1,
  } unless($id); 
  
  foreach my $Section ($self->Sections_of($id)) {
    my $cfg = {
      id   => $Section->id,
      text => $Section->name
    };
    
    $cfg->{expanded} = \1 unless ($Section->sections->count > 0);
    
    push @nodes, $cfg;
  }
  
  if($id) {
    $id = undef if ($id eq 'unsectioned');
    foreach my $Post ($self->Posts_of($id)) {
      my $cfg = {
        id          => join('-','p',$Post->id),
        text        => $Post->title,
        iconCls     => 'icon-post',
        leaf        => \1,
        expanded    => \1,
        allowDrop   => \0,
        allowAdd    => \0,
        allowDelete => \0
      };
      push @nodes, $cfg;
    }
  }
  
  \@nodes
}



sub add_node {
  my ($self,$name,$node,$params) = @_;
  
  die usererr "Create Section: PERMISSION DENIED" unless ($self->is_admin);

  my $id = $self->get_node_id($node);
  
  # should be redundant:
  die usererr "Cannot add a Section to a post" if ($self->get_post_id($id));
  
  my $Section = $self->Rs->create({
    parent_id => $id,
    name      => $name
  });
  
  return {
    msg    => 'Created',
    success  => \1,
    child => {
      id   => $Section->id,
      text => $Section->name
    }

  };
}


sub rename_node {
  my ($self,$node,$name,$params) = @_;
  
  die usererr "Rename: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id = $self->get_node_id($node);
  die "Cannot rename the root node" unless ($id);
  
  # strip whitespace
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  
  if(my $post_id = $self->get_post_id($id)) {
    my $Post = $self->get_Post($post_id) or die "Post id '$post_id' not found";
    
    $Post->update({ title => $name });
    
    return {
      msg    => 'Renamed',
      success  => \1,
      new_text => $Post->title,
    };
  }
  else {
    my $Section = $self->get_Section($id) or die "Section id '$id' not found";
    
    $Section->update({ name => $name });
    
    return {
      msg    => 'Renamed',
      success  => \1,
      new_text => $Section->name,
    };
  }
}

sub delete_node {
  my $self = shift;
  my $node = shift;
  
  die usererr "Delete: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id = $self->get_node_id($node);
  die "Cannot rename the root node" unless ($id);
  
  # should be redundant:
  die usererr "Posts not allowed to be deleted from here" if ($self->get_post_id($id));
  
  my $Section = $self->get_Section($id) or die "Section id '$id' not found";
  
  $Section->delete;
  
  return {
    msg    => "Deleted",
    success  => \1
  };
}


sub move_node {
  my $self = shift;
  my $node = shift;
  my $target = shift;
  my $point = shift;
  
  die usererr "Move Section: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id  = $self->get_node_id($node);
  my $tid = $self->get_node_id($target);
  
  $tid = undef if ($tid eq 'unsectioned');
  
  # should be redundant:
  die usererr "Posts cannot contain sub-items" if ($self->get_post_id($tid));
  
  if(my $post_id = $self->get_post_id($id)) {
    my $Post = $self->get_Post($post_id) or die "Post id '$post_id' not found";
    
    $Post->section_id($tid);
    $Post->update
  }
  else {
    my $Section = $self->get_Section($id) or die "Section id '$id' not found";
    
    $Section->parent_id($tid);
    $Section->update
  }
}




1;
