package Rapi::Blog;

use strict;
use warnings;

# ABSTRACT: RapidApp-powered blog

use RapidApp 1.3001;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;
require Module::Locate;
use Path::Class qw/file dir/;
use YAML::XS 0.64 'LoadFile';

our $VERSION = 1.0003;
our $TITLE = "Rapi::Blog v" . $VERSION;

has 'site_path',        is => 'ro', required => 1;
has 'scaffold_path',    is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'builtin_scaffold', is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'scaffold_config',  is => 'ro', isa => HashRef, default => sub {{}};
has 'fallback_builtin_scaffold', is => 'ro', isa => Bool, default => sub {0};

has '+base_appname', default => sub { 'Rapi::Blog::App' };
has '+debug',        default => sub {1};

has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $self->_get_share_dir;
};

sub _get_share_dir {
  my $self = shift || __PACKAGE__;
  $ENV{RAPI_BLOG_SHARE_DIR} || (
    try{dist_dir('Rapi-Blog')} || (
      -d "$FindBin::Bin/share" ? "$FindBin::Bin/share"       : 
      -d "$FindBin::Bin/../share" ? "$FindBin::Bin/../share" :
      join('',$self->_module_locate_dir,'/../../share')
    )
  )
}

sub _module_locate_dir {
  my $self = shift;
  my $pm_path = Module::Locate::locate('Rapi::Blog') or die "Failed to locate Rapi::Blog?!";
  file($pm_path)->parent->stringify
}

has '+inject_components', default => sub {
  my $self = shift;
  my $model = 'Rapi::Blog::Model::DB';
  
  my $db = $self->site_dir->file('rapi_blog.db');
  
  Module::Runtime::require_module($model);
  $model->config->{connect_info}{dsn} = "dbi:SQLite:$db";

  return [
    [ $model => 'Model::DB' ],
    [ 'Rapi::Blog::Controller::Remote' => 'Controller::Remote' ]
  ]
};

has 'site_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $Dir = dir( $self->site_path )->absolute;
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

has 'scaffold_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
	
	my $path;
	
	if(my $scaffold_name = $self->builtin_scaffold) {
		die join('',
		  " Error: don't use both 'builtin_scaffold' and 'scaffold_path' options"
		) if ($self->scaffold_path);
		my $Dir = $self->_get_builtin_scaffold_dir($scaffold_name)->absolute;
    -d $Dir or die "builtin scaffold '$scaffold_name' not found\n";
		
		$path = $Dir->stringify;
	}
	else {
		$path = $self->scaffold_path || $self->site_dir->subdir('scaffold');
	}
  
  my $Dir = dir( $path );
  if(! -d $Dir) {
    if($self->fallback_builtin_scaffold) {
      my $scaffold_name = 'bootstrap-blog';
      warn join('', 
        "\n ** WARNING: local scaffold directory not found;\n  --> using builtin ",
        "scaffold '$scaffold_name' (fallback_builtin_scaffold is set to true)\n\n"
      );
      $Dir = $self->_get_builtin_scaffold_dir($scaffold_name);
      -d $Dir or die join('',
        " Fatal error: fallback scaffold not found (this could indicate a ",
        "problem with your Rapi::Blog installation)\n\n"
      );
    }
    else {
      die "Scaffold directory '$Dir' not found.\n";
    }
  }
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

sub _get_builtin_scaffold_dir {
	my ($self, $scaffold_name) = @_;
	$scaffold_name ||= 'bootstrap-blog';
	
	my $Scaffolds = dir( $self->share_dir )->subdir('scaffolds')->absolute;
	-d $Scaffolds or die join('',
    " Fatal error: Unable to locate scaffold share dir (this could indicate a ",
    "problem with your Rapi::Blog installation)\n\n"
  );
	
	$Scaffolds->subdir($scaffold_name)
}

has 'scaffold_cnf', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $defaults = {
    favicon            => 'favicon.ico',
    landing_page       => 'index.html',
    internal_post_path => 'private/post/',
    not_found          => 'rapidapp/public/http-404.html',
    view_wrappers      => [],
    static_paths       => ['/'],
    private_paths      => [],
    default_ext        => 'html',
  
  };
  
  my $cnf = clone( $self->scaffold_config );
  
  my $yaml_file = $self->scaffold_dir->file('scaffold.yml');
  if (-f $yaml_file) {
    my $data = LoadFile( $yaml_file );
    %$cnf = ( %$data, %$cnf );
  }
  
  %$cnf = ( %$defaults, %$cnf );

  return $cnf

}, isa => HashRef;

has 'default_view_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  return $self->scaffold_cnf->{default_view_path} if ($self->scaffold_cnf->{default_view_path});
  
  # first marked 'default' or first type 'include' or first anything
  my @wrappers = grep { $_->{path} } @{$self->scaffold_cnf->{view_wrappers} || []};
  my $def = List::Util::first { $_->{default} } @wrappers;
  $def ||= List::Util::first { $_->{type} eq 'include' } @wrappers;
  $def ||= $self->scaffold_cnf->{view_wrappers}[0];
  
  unless($def) {
    warn "\n ** Waring: scaffold has no suitable view_wrappers to use as 'default_view_path'\n\n";
    return undef;
  }

  return $def->{path}
};

has 'preview_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->scaffold_cnf->{preview_path} || $self->default_view_path
};


sub _build_version { $VERSION }
sub _build_plugins { [qw/
  RapidApp::RapidDbic
  RapidApp::AuthCore
  RapidApp::NavCore
  RapidApp::CoreSchemaAdmin
/]}

sub _build_base_config {
  my $self = shift;
  
  my $tpl_dir = join('/',$self->share_dir,'templates');
  -d $tpl_dir or die join('',
    "template dir ($tpl_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  my $loc_assets_dir = join('/',$self->share_dir,'assets');
  -d $loc_assets_dir or die join('',
    "assets dir ($loc_assets_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  my $config = {
  
    'RapidApp' => {
      module_root_namespace => 'adm',
      local_assets_dir => $loc_assets_dir,
    },
    
    'Model::RapidApp::CoreSchema' => {
      sqlite_file => $self->site_dir->file('rapidapp_coreschema.db')->stringify
    },
    
    'Plugin::RapidApp::AuthCore' => {
      linked_user_model => 'DB::User'
    },
    
    'Controller::SimpleCAS' => {
      store_path => $self->site_dir->subdir('cas_store')->stringify
    },
    
    'Plugin::RapidApp::TabGui' => {
      title => $TITLE,
      nav_title => 'Administration',
      banner_template => file($tpl_dir,'banner.html')->stringify,
      dashboard_url => '/tpl/dashboard.md',
			navtree_init_width => 190,
    },
    
    'Controller::RapidApp::Template' => {
      root_template_prefix  => '/',
      root_template         => $self->scaffold_cnf->{landing_page},
      read_alias_path => '/tpl',  #<-- already the default
      edit_alias_path => '/tple', #<-- already the default
      default_template_extension => undef,
      include_paths => [ $tpl_dir ],
      access_class => 'Rapi::Blog::Template::AccessStore',
      access_params => {
        scaffold_dir  => $self->scaffold_dir,
        scaffold_cnf  => $self->scaffold_cnf,
        static_paths  => $self->scaffold_cnf->{static_paths},
        private_paths => $self->scaffold_cnf->{private_paths},
        default_ext   => $self->scaffold_cnf->{default_ext},
        
        internal_post_path => $self->scaffold_cnf->{internal_post_path},
        view_wrappers      => $self->scaffold_cnf->{view_wrappers},
        default_view_path  => $self->default_view_path,
        preview_path       => $self->preview_path,

        get_Model => sub { $self->base_appname->model('DB') } 
      } 
    }
  };
  
  if(my $favname = $self->scaffold_cnf->{favicon}) {
    my $Fav = $self->scaffold_dir->file($favname);
    $config->{RapidApp}{default_favicon_url} = $Fav->stringify if (-f $Fav);
  }
  
  return $config
}

1;

__END__

=head1 NAME

Rapi::Blog - Plack-compatible, RapidApp-based blog engine

=head1 SYNOPSIS

 use Rapi::Blog;
 
 my $app = Rapi::Blog->new({
  site_path     => '/path/to/some-site',
  scaffold_path => '/path/to/some-site/scaffold', # default
 });

 # Plack/PSGI app:
 $app->to_app

Create a new site from scratch using the L<rabl.pl> utility script:

 rabl.pl create /path/to/some-site
 cd /path/to/some-site && plackup

=head1 DESCRIPTION

This is a L<Plack>-compatible blogging platform written using L<RapidApp>. This module was first 
released during The Perl Conference 2017 in Washington D.C. where a talk/demo was given on the 
platform:

=begin HTML

  <p><a href="http://rapi.io/tpc2017"><img 
     src="https://raw.githubusercontent.com/vanstyn/Rapi-Blog/master/share/tpc2017-video-preview.png" 
     width="800"
     alt="Rapi::Blog talk/video"
     title="Rapi::Blog talk/video"
  /></a></p>

=end HTML

L<rapi.io/tpc2017|http://rapi.io/tpc2017>

See L<Rapi::Blog::Manual> for more information and usage.

=head1 CONFIGURATION

C<Rapi::Blog> extends L<RapidApp::Builder> and supports all of its options, as well as the following
params specific to this module:

=head2 site_path

Only required param - path to the directory containing the site.

=head2 scaffold_path

Path to the directory containing the "scaffold" of the site. This is like a document root with
some extra functionality.

If not supplied, defaults to C<'scaffold/'> within the C<site_path> directory.

=head2 builtin_scaffold

Alternative to C<scaffold_path>, the name of one of the builtin skeleton scaffolds to use as the
live scaffold. This is mainly useful for dev and content-only testing. As of version C<1.0000>) there
are two built-in scaffolds:

=head3 bootstrap-blog

This is the default out-of-the-box scaffold which is based on the "Blog" example from the Twitter
Bootstrap HTML/CSS framework (v3.3.7): L<http://getbootstrap.com/examples/blog/>. This mainly exists
to serve as a useful reference implementation of the basic features/directives provided by the
Template API.

=head3 keep-it-simple

Based on the "Keep It Simple" website template by L<http://www.Styleshout.com>

=head2 fallback_builtin_scaffold

If set to true and the local scaffold directory doesn't exist, the default builtin skeleton scaffold
'bootstrap-blog' will be used instead. Useful for testing and content-only scenarios.

Defaults to false.

=head1 METHODS

=head2 to_app

PSGI C<$app> CodeRef. Derives from L<Plack::Component>

=head1 SEE ALSO

=over

=item * 

L<rabl.pl>

=item *

L<Rapi::Blog::Manual>

=item * 

L<RapidApp>

=item * 

L<RapidApp::Builder>

=item * 

L<Plack>

=item *

L<http://rapi.io/blog>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


