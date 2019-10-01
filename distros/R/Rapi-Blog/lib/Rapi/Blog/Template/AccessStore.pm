package Rapi::Blog::Template::AccessStore;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'RapidApp::Template::AccessStore';
use Types::Standard ':all';

use Rapi::Blog::Scaffold;
use Rapi::Blog::Template::Dispatcher;

use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;

sub _cache_slots { (shift)->local_cache->{template_row_slot} //= {} }

has 'BlogCfg',      is => 'ro', required => 1, isa => HashRef;
has 'ScaffoldSet',  is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Scaffold::Set'];
has 'scaffold_cfg', is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Scaffold::Config'];

sub Dispatcher_for {
  my ($self,@args) = @_;
  my $path = join('/',@args);  
  $self->_cache_slots->{$path}{Dispatcher} ||= Rapi::Blog::Template::Dispatcher->new(
    path => $path, AccessStore => $self, ctx => RapidApp->active_request_context
  )->resolve
}

sub PostDispatcher_for {
  my $self = shift;
  my $Dispatcher = $self->Dispatcher_for(@_) or return undef;
  $Dispatcher->type eq 'Post' ? $Dispatcher : undef
}

sub Post_name_for {
  my $self = shift;
  my $Dispatcher = $self->PostDispatcher_for(@_) or return undef;
  $Dispatcher->name
}


#has 'scaffold_dir',  is => 'ro', isa => InstanceOf['Path::Class::Dir'], required => 1;
#has 'scaffold_cnf',  is => 'ro', isa => HashRef, required => 1;
#has 'static_paths',  is => 'ro', isa => ArrayRef[Str], default => sub {[]};
#has 'private_paths', is => 'ro', isa => ArrayRef[Str], default => sub {[]};
#has 'default_ext',   is => 'ro', isa => Maybe[Str],    default => sub {undef};

around 'template_external_tpl' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  $self->Dispatcher_for($template)->claimed ? 1 : $self->$orig(@args)
};


# Deny post templates access to to privileged attributes such as the catalyst context object). 
# This could be expanded later on to allow only certain posts to be able to access these attributes.
around 'template_admin_tpl' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  $self->Dispatcher_for($template)->restrict ? 0 : $self->$orig(@args)
};




sub templateData {
  my ($self, $template) = @_;
  die 'template name argument missing!' unless ($template);
  
  $self->Dispatcher_for($template)->template_vars
}

# -----------------
# Access class API:

around '_get_default_template_vars' => sub {
  my ($orig,$self,@args) = @_;
  my $c = RapidApp->active_request_context;
  
  my $template = join('/',@args);
  my $recaptcha_config = $self->BlogCfg->{recaptcha_config};
  
  my $vars = {
    %{ $self->$orig(@args) },
    %{ $self->templateData($template) || {} },
    
    BlogCfg         => $self->BlogCfg,
    scaffold        => $self->scaffold_cfg,
    list_posts      => sub { $self->Model->resultset('Post')     ->list_posts(@_)      },
    list_tags       => sub { $self->Model->resultset('Tag')      ->list_tags(@_)       },
    list_categories => sub { $self->Model->resultset('Category') ->list_categories(@_) },
    list_sections   => sub { $self->Model->resultset('Section')  ->list_sections(@_)   },
    list_users      => sub { $self->Model->resultset('User')     ->list_users(@_)      },
    
    # TODO: consider mount_url
    request_path => sub { $c ? join('','/',$c->req->path) : undef },
    
    User => sub { Rapi::Blog::Util->get_User },
    
    # Path to the 'Remote' controller
    remote_action_path => sub { $c ? join('',$c->mount_url,'/remote') : undef },
    
    add_post_path => sub {
      my $ns = $c->module_root_namespace;
      if(my $mode = shift) {
        $mode = lc($mode);
        # Note: 'direct' is not useful un this context since add relies on opening new tab
        die "add_post_path(): bad argument '$mode' -- must be undef or 'navable'"
          unless ($mode eq 'navable');
        return join('',$c->mount_url,'/rapidapp/module/',$mode,'/',$ns,'/main/db/db_post/add')
      }
      else {
        return join('',$c->mount_url,'/',$ns,'/#!/',$ns,'/main/db/db_post/add')
      }
    },
    
    resolve_section_id => sub {
      if(my $id = shift) {
        my $Section = $self->Model->resultset('Section')
          ->search_rs({ 'me.id' => $id })
          ->first;
        return $Section ? $Section->name : $id
      }
    },
    
    # Expose this here so its available to non-priv templates:
    mount_url => sub { $c->mount_url },
    
    accessed_site => sub {
      $c && $c->req or return undef;
      my $uri = $c->req->uri or return undef;
      my $host = $c->req->env->{HTTP_HOST} || $uri->host_port;
      my $proto = $c->req->env->{HTTP_X_FORWARDED_PROTO} || $uri->scheme || 'http';
      join('',$proto,'://',$host)
    },
    
    local_info => sub {
      my $new     = shift;
      
      my $uri     = $c->req->uri or return undef;
      my $session = $c->session or return undef;
      my $err     = $session->{local_info}{$uri->path};
      
      if(defined $new) {
        if(!$new || lc($new) eq 'clear') {
          exists $session->{local_info}{$uri->path} and delete $session->{local_info}{$uri->path}
        }
        else {
          $session->{local_info}{$uri->path} = $new
        }
      }

      $err
    },
    
    recaptcha_script_tag => sub {
      $recaptcha_config
        ? '<script src="https://www.google.com/recaptcha/api.js" async defer></script>'
        : ''
    },
    
    recaptcha_form_item => sub {
      $recaptcha_config
        ? join('',
          '<div class="g-recaptcha" data-sitekey="',
          $recaptcha_config->{public_key},
          '"></div>'
        ) : ''
    },
    
    
  };
  
  #if (my $Scaffold = $self->DispatchRule_for($template)->Scaffold) {
  #  $vars->{scaffold} = $Scaffold->config;
  #}
  
  return $vars
  
};

around '_get_admin_template_vars' => sub {
  my ($orig,$self,@args) = @_;

  return {
    %{ $self->$orig(@args) },
    
    ensure_logged_out => sub {
      if (Rapi::Blog::Util->get_User) {
        RapidApp->active_request_context->logout
      }
      ''
    }
    
    
  };  

};


# -----------------
# Store class API:


use DateTime;
use Date::Parse;
use Path::Class qw/file dir/;

has 'get_Model', is => 'ro', isa => Maybe[CodeRef], default => sub {undef};

has 'Model', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die "Must supply 'Model' or 'get_Model'" unless $self->get_Model;
  $self->get_Model->()
}, isa => Object;


sub internal_post_path { (shift)->scaffold_cfg->internal_post_path }
sub view_wrappers      { (shift)->scaffold_cfg->view_wrappers      }
sub default_view_path  { (shift)->scaffold_cfg->default_view_path  }
sub preview_path       { (shift)->scaffold_cfg->preview_path       }


#has 'internal_post_path', is => 'ro', isa => Str, required => 1;
##has 'view_wrappers',      is => 'ro', isa => ArrayRef[HashRef], default => sub {[]};
#has 'default_view_path',  is => 'ro', isa => Maybe[Str], default => sub {undef};
##has 'preview_path',       is => 'ro', isa => Maybe[Str], default => sub {undef};


sub get_uid {
  my $self = shift;
  
  if(my $c = RapidApp->active_request_context) {
    return $c->user->id if ($c->can('user'));
  }
  
  return 0;
}

sub cur_ts {
  my $self = shift;
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub owns_tpl {
  my ($self, $template) = @_;
  $self->Dispatcher_for($template)->claimed
}

sub template_exists {
  my ($self, $template) = @_;
  $self->Dispatcher_for($template)->exists
}


sub template_mtime {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{template_mtime} //= $self->_template_mtime($template)
}

sub _template_mtime {
  my ($self, $template) = @_;
  
  $self->Dispatcher_for($template)->mtime
}

sub template_content {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{template_content} //= $self->_template_content($template)
}

sub _template_content {
  my ($self, $template) = @_;
  
  $self->Dispatcher_for($template)->content
}


sub create_template {
  my ($self, $template, $content) = @_;
  
  my $name = $self->Post_name_for($template) or return undef;
  
  my $create = {
    name => $name,
    body => $content,
    published => 1
  };
  
  $self->Model->resultset('Post')->create($create) ? 1 : 0;
}


sub update_template {
  my ($self, $template, $content) = @_;
  my $name = $self->Post_name_for($template) or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->update({ body => $content }) ? 1 : 0;
}


sub delete_template {
  my ($self, $template) = @_;
  my $name = $self->Post_name_for($template) or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->delete ? 1 : 0;
}

around 'get_template_format' => sub {
  my ($orig, $self, @args) = @_;
  my $template = join('/',@args);
  
  # By rule all local tempaltes (Post rows) are markdown
  return $self->Post_name_for($template)
    ? 'markdown'
    : $self->$orig(@args)
};

sub list_templates {
  my $self = shift;
  [ map { join('',$self->internal_post_path,$_) } $self->Model->resultset('Post')->get_column('name')->all ]
}

around 'template_post_processor_class' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  # By rule, never use a post processor with a wrapper view:
  return undef if $self->Dispatcher_for($template)->find_parent_type('ViewWrapper');
  
  # Render markdown with our MarkdownElement post-processor if the next template
  # (i.e. which is including us) is one of our wrapper/views. This will defer
  # rendering of markdown to the client-side with the marked.js library
  if($self->process_Context && $self->get_template_format($template) eq 'markdown') {
    if(my $next_template = $self->process_Context->next_template) {
      if($self->Dispatcher_for($next_template)->is_type('ViewWrapper')) {
        return 'Rapi::Blog::Template::Postprocessor::MarkdownElement'
      }
    }
  }

  return $self->$orig(@args)
};


sub template_psgi_response {
  my ($self, $template, $c) = @_;
  $self->Dispatcher_for($template)->maybe_psgi_response
}


1;