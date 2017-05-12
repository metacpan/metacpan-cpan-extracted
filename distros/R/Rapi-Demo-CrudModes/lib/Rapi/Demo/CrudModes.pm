package Rapi::Demo::CrudModes;

use strict;
use warnings;

# ABSTRACT: RapidApp demo application

use RapidApp 1.0600;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use Path::Class qw(file dir);
use Module::Runtime;
use Scalar::Util 'blessed';
use Cwd;

my $Bin = file($0)->parent; # Like FindBin

our $VERSION = '1.01';

has '+base_appname', default => sub { 'CrudModes::Demo' };
has '+debug',        default => sub {1};

sub _build_plugins {[
  'RapidApp::RapidDbic'
]}

sub _build_base_config {
  my $self = shift;
  
  $self->_init_local_data if $self->clear_data_dir || ! (-d $self->data_dir);

  my $module_params = {
    
    # Everything instant (same as default):
    instant => {
      use_add_form  => 0,
      use_edit_form => 1,
      persist_immediately => {
        create => 1, update => 1, destroy => 1
      },
      confirm_on_destroy => 0
    },
    
    # Alternate -  nothing instant
    save => {
      use_add_form  => 0,
      use_edit_form => 0,
      persist_immediately => {
        create => 0, update => 0, destroy => 0
      },
      confirm_on_destroy => 1,
    },
    
    # Mixed - only 'update' requires save, but use add form + edit form
    mixed => {
      use_add_form  => 1,
      use_edit_form => 1,
      persist_immediately => {
        create => 1, update => 0, destroy => 1
      },
      confirm_on_destroy => 1,
    }
  };

  return {
    'RapidApp' => {
      local_assets_dir => $self->_assets_dir,
      load_modules => {
      
        'alpha_grid_instant' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::Grid',
          params => $module_params->{instant}
        },
        'alpha_grid_save' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::Grid',
          params => $module_params->{save}
        },
        'alpha_grid_mixed' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::Grid',
          params => $module_params->{mixed}
        },
        
        
        'alpha_dv_instant' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::DV',
          params => $module_params->{instant}
        },
        'alpha_dv_save' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::DV',
          params => $module_params->{save}
        },
        'alpha_dv_mixed' => {
          class  => 'Rapi::Demo::CrudModes::Module::Alpha::DV',
          params => $module_params->{mixed}
        },

      }
    },
    'Plugin::RapidApp::TabGui' => {
      navtree_init_width => 180,
      dashboard_url      => '/tple/dashboard',
      navtree_disabled   => 1
    },

    'Controller::RapidApp::Template' => {
      include_paths => $self->_template_include_paths,
      default_template_extension => 'html',
      
    },
    'Controller::SimpleCAS' => {
      store_path	=> $self->cas_store_dir
    },
    'Model::RapidApp::CoreSchema' => {
      sqlite_file => file( $self->coreschema_db )->absolute->stringify
    }
  }
}


has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $ENV{RAPI_DEMO_CRUDMODES_SHARE_DIR} || (
    try{dist_dir('Rapi-Demo-CrudModes')} || (
      -d "$FindBin::Bin/share" ? "$FindBin::Bin/share" : "$FindBin::Bin/../share" 
    )
  )
};

has 'data_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  # Default to the cwd
  dir( cwd(), 'crudmodes_data')->stringify;
};


has 'crudmodes_db', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  file( $self->data_dir, 'crudmodes.db' )->stringify
};

has 'cas_store_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  dir( $self->data_dir, 'cas_store' )->stringify
};

# Set to true to force init the local data dir on every startup,
# even if it already exists (DANGEROUS!)
has 'clear_data_dir', is => 'ro', isa => Bool, default => sub {0};

has 'coreschema_db', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  file( $self->data_dir, 'crudmodes_coreschema.db' )->stringify
};

has 'cas_store_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  dir( $self->data_dir, 'cas_store' )->stringify
};

has 'local_template_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  dir( $self->data_dir, 'templates' )->stringify
};


has '_template_include_paths', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  # overlay local, writable templates with installed, 
  # read-only templates installed in the share dir
  return [ $self->local_template_dir, $self->_tpl_dir ];
}, isa => ArrayRef[Str];


has '_assets_dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $loc_assets_dir = join('/',$self->share_dir,'assets');
  -d $loc_assets_dir or die join('',
    "assets dir ($loc_assets_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  return $loc_assets_dir;
}, isa => Str;

has '_tpl_dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $tpl_dir = join('/',$self->share_dir,'templates');
  -d $tpl_dir or die join('',
    "template dir ($tpl_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  return $tpl_dir;
}, isa => Str;

has '_init_data_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  dir( $self->share_dir, '_init_data_dir' )->stringify
}, init_arg => undef;



has '+inject_components', default => sub {
  my $self = shift;
  my $model = 'Rapi::Demo::CrudModes::Model::DB';
  
  my $db = file( $self->crudmodes_db );

  Module::Runtime::require_module($model);
  $model->config->{connect_info}{dsn} = "dbi:SQLite:$db";

  return [
    [ $model => 'Model::DB' ]
  ]
};


after 'bootstrap' => sub {
  my $self = shift;
  
  my $c = $self->appname;
  $c->model('DB')->_auto_deploy_schema
};

sub _init_local_data {
  my ($self, $ovr) = @_;
  
  $ovr = 1 if ($self->clear_data_dir);
  
  my ($src,$dst) = (dir($self->_init_data_dir),dir($self->data_dir));
  
  die "_init_local_data(): ERROR: init data dir '$src' not found!" unless (-d $src);

  if(-d $dst) {
    if($ovr) {
      $dst->rmtree;
    }
    else {
      die "_init_cas(): Destination dir '$dst' already exists -- call with true arg to overwrite.";
    }
  }
  
  print STDERR "\n Initializing local data_dir $dst/\n" if ($self->debug);
  
  $self->_recurse_copy($src,$dst);
  
  print STDERR "\n" if ($self->debug);
}


sub _recurse_copy {
  my ($self, $Src, $Dst, $lvl) = @_;
  
  $lvl ||= 0;
  $lvl++;
  
  die "Destination path '$Dst' already exists!" if (-e $Dst);
  
  print STDERR join('',
    '  ',('  ' x $lvl),$Dst->basename,
    $Dst->is_dir ? '/' : '', "\n"
  ) if ($self->debug);

  if($Src->is_dir) {
    $Dst->mkpath;
    for my $Child ($Src->children) {
      my $meth = $Child->is_dir ? 'subdir' : 'file';
      $self->_recurse_copy($Child,$Dst->$meth($Child->basename),$lvl);
    }
  }
  else {
    $Dst->spew( scalar $Src->slurp );
  }
}



1;


__END__

=head1 NAME

Rapi::Demo::CrudModes - RapidApp DBIC-driven module config examples 

=head1 SYNOPSIS

 use Rapi::Demo::CrudModes;
 my $app = Rapi::Demo::CrudModes->new;

 # Plack/PSGI app:
 $app->to_app

Or, from the command-line:

 plackup -MRapi::Demo::CrudModes -e 'Rapi::Demo::CrudModes->new->to_app'


=head1 DESCRIPTION

...

=head1 CONFIGURATION

...

=head1 SEE ALSO

=over

=item * 

L<RapidApp>

=item * 

L<RapidApp::Builder>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



