package Rapi::Blog;

use strict;
use warnings;

# ABSTRACT: RapidApp-powered blog

use RapidApp 1.3106;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;
require Module::Locate;
use Path::Class qw/file dir/;
use YAML::XS 0.64 'LoadFile';

use Rapi::Blog::Scaffold;
use Rapi::Blog::Scaffold::Set;

our $VERSION = 1.1002;
our $TITLE = "Rapi::Blog v" . $VERSION;

has 'site_path',        is => 'ro', required => 1;
has 'scaffold_path',    is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'builtin_scaffold', is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'scaffold_config',  is => 'ro', isa => HashRef, default => sub {{}};
has 'fallback_builtin_scaffold', is => 'ro', isa => Bool, default => sub {0};

has 'enable_password_reset', is => 'ro', isa => Bool, default => sub {1};
has 'enable_user_sign_up',   is => 'ro', isa => Bool, default => sub {1};
has 'enable_email_login',    is => 'ro', isa => Bool, default => sub {1};

has 'underlay_scaffolds', is => 'ro', isa => ArrayRef[Str], default => sub {[]};

has 'smtp_config', is => 'ro', isa => Maybe[HashRef], default => sub { undef };
has 'override_email_recipient', is => 'ro', isa => Maybe[Str], default => sub { undef };

has 'recaptcha_config', is => 'ro', isa => Maybe[HashRef[Str]], default => sub { undef };


has '+base_appname', default => sub { 'Rapi::Blog::App' };
has '+debug',        default => sub {1};

sub BUILD {
  my $self = shift;
  print STDERR join('',' -- ',(blessed $self),' v',$self->VERSION,' -- ',"\n") if ($self->debug);
}

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
    [ 'Rapi::Blog::Model::Mailer' => 'Model::Mailer' ],
    [ 'Rapi::Blog::Controller::Remote' => 'Controller::Remote' ],
    [ 'Rapi::Blog::Controller::Remote::PreauthAction' => 'Controller::Remote::PreauthAction' ]
  ]
};



has 'site_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $Dir = dir( $self->site_path )->absolute;
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];


has 'scaffolds', is => 'ro', lazy => 1, default => sub { undef };

has 'ScaffoldSet', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $scafs = $self->scaffolds || [];
  $scafs = [ $scafs ] unless (ref($scafs)||'' eq 'ARRAY');
  $scafs = [ $self->scaffold_dir ] unless (scalar(@$scafs) > 0);
  
  my @list = map { 
    Rapi::Blog::Scaffold->factory( $_ ) 
  } @$scafs, @{ $self->_get_underlay_scaffold_dirs };
  
  my $Set = Rapi::Blog::Scaffold::Set->new( Scaffolds => \@list );
    
  # Apply any custom configs to the *first* scaffold:
  $self->scaffold_config and $Set->first->config->_apply_params( $self->scaffold_config );
  
  $Set

}, isa => InstanceOf['Rapi::Blog::Scaffold::Set'];


# This exists to be able to provide access to the running Blog config, including within
# templates, without the risk associated with providing direct access to the Rapi::Blog 
# instance outright:
has 'BlogCfg', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my @keys = grep {
    my $Attr = $self->meta->get_attribute($_);
    
    !($_ =~ /^_/) # ignore attrs with private names (i.e. start with "_")
    && ($Attr->reader||'') eq $_ # only consider attributes with normal accessor names
    && $Attr->has_value($self) # and already have a value

  } $self->meta->get_attribute_list;

  # If any normal methods are desired in the future, add them to keys here
  
  my $cfg = { map { $_ => $self->$_ } @keys };

  $cfg
}, isa => HashRef;



# Single merged config object which considers, prioritizes and flattens the configs of all scaffolds
has 'scaffold_cfg', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my %merged = (
    map {
      %{ $_->config->_all_as_hash }
    } reverse ($self->ScaffoldSet->all)
  );
  
  Rapi::Blog::Scaffold::Config->new( %merged )

}, isa => InstanceOf['Rapi::Blog::Scaffold::Config'];



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


after 'bootstrap' => sub { 
  my $self = shift;
  
  my $c = $self->appname;
  $c->setup_plugins(['+Rapi::Blog::CatalystApp']);
  
};


sub _get_underlay_scaffold_dirs {
  my $self = shift;

  my $CommonUnderlay = dir( $self->share_dir )->subdir('common_underlay')->absolute;
  -d $CommonUnderlay or die join('',
    " Fatal error: Unable to locate common underlay scaffold dir (this could ",
    "indicate a problem with your Rapi::Blog installation)\n\n"
  );
  
  return [ 
    @{$self->underlay_scaffolds}, 
    $CommonUnderlay 
  ]
}


sub _enforce_valid_recaptcha_config {
  my $self = shift;
  my $cfg = $self->recaptcha_config or return 1; # No config at all is valid
  
  my @valid_keys = qw/public_key private_key verify_url strict_mode/;
  my %keys = map {$_=>1} @valid_keys;
  for my $k (keys %$cfg) {
    $keys{$k} or die join('',
      "Unknown recaptcha_config param '$k' - ",
      "only valid params are: ",join(', ',@valid_keys)
    )
  }
  
  die "Invalid recaptcha_config - both 'public_key' and 'private_key' params are required"
    unless ($cfg->{public_key} && $cfg->{private_key});
  
  if(exists $cfg->{strict_mode}) {
    my $v = $cfg->{strict_mode};
    my $disp = defined $v ? "'$v'" : 'undef';
    die "Bad value $disp for 'strict_mode' in recaptcha_config - must be either 1 (true) or 0 (false)\n"
      unless ("$v" eq '0' || "$v" eq '1')
  }
}


sub _build_version { $VERSION }
sub _build_plugins { [qw/
  RapidApp::RapidDbic
  RapidApp::AuthCore
  RapidApp::NavCore
  RapidApp::CoreSchemaAdmin
/]}

sub _build_base_config {
  my $self = shift;
  
  $self->_enforce_valid_recaptcha_config;
  
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
      
      load_modules => {
        sections => {
          class  => 'Rapi::Blog::Module::SectionTree',
          params => {}
        }
      },
      
    },
    
    'Plugin::RapidApp::NavCore' => {
      custom_navtree_nodes => [
        {
          text    => 'Taxonomies',
          iconCls => 'icon-fa-cogs',
          cls		=> 'pad-top-4px',
          expand => \1,
          children => [
            {
              text    => 'Tags',
              iconCls => 'icon-tags-blue',
              url     => '/adm/main/db/db_tag' 
            },
            {
              text    => 'Categories',
              iconCls => 'icon-images',
              url     => '/adm/main/db/db_category' 
            },
            {
              text    => 'Sections (Tree)',
              iconCls => 'icon-sitemap-color',
              url     => '/adm/sections' 
            },
            {
              text    => 'Sections (Grid)',
              iconCls => 'icon-chart-organisation',
              url     => '/adm/main/db/db_section' 
            },

          ]
        },
        {
          text     => 'Content',
          iconCls  => 'icon-folder-table',
          children => [
            {
              text    => 'Posts',
              iconCls => 'icon-posts',
              url     => '/adm/main/db/db_post' 
            },
            {
              text    => 'Comments',
              iconCls => 'icon-comments',
              url     => '/adm/main/db/db_comment' 
            },
          ]
        },
        
        {
          text    => 'Index &amp; tracking tables',
          iconCls => 'icon-database-gear',
          children => [
            {
              text    => 'Post-Category Links',
              iconCls => 'icon-logic-and',
              url     => '/adm/main/db/db_postcategory' 
            },
            {
              text    => 'Post-Tag Links',
              iconCls => 'icon-logic-and-blue',
              url     => '/adm/main/db/db_posttag' 
            },
            {
              text    => 'Track Section-Posts',
              iconCls => 'icon-table-relationship',
              url     => '/adm/main/db/db_trksectionpost' 
            },
            {
              text    => 'Track Section-Sections',
              iconCls => 'icon-table-relationship',
              url     => '/adm/main/db/db_trksectionsection' 
            },
          ]
        },
        
        {
          text    => 'Stats &amp; settings',
          iconCls => 'icon-group-gear',
          children => [
            {
              text    => 'Users',
              iconCls => 'icon-users',
              url     => '/adm/main/db/db_user' 
            },
            {
              text    => 'Roles',
              iconCls => 'ra-icon-user-prefs',
              url     => '/adm/main/db/rapidapp_coreschema_role' 
            },
            {
              text    => 'Hits',
              iconCls => 'icon-world-gos',
              url     => '/adm/main/db/db_hit' 
            },
            {
              text    => 'Sessions',
              iconCls => 'ra-icon-environment-network',
              url     => '/adm/main/db/db_session' 
            },
            
            {
              text    => 'All Saved Views',
              iconCls => 'ra-icon-data-views',
              url     => '/adm/main/db/rapidapp_coreschema_savedstate' 
            },
            
            {
              text    => 'Default Views by Source',
              iconCls => 'ra-icon-data-preferences',
              url     => '/adm/main/db/rapidapp_coreschema_defaultview' 
            },
          ]
        },
        
      ]
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
      root_template         => $self->scaffold_cfg->landing_page,
      read_alias_path => '/tpl',  #<-- already the default
      edit_alias_path => '/tple', #<-- already the default
      default_template_extension => undef,
      include_paths => [ $tpl_dir ],
      access_class => 'Rapi::Blog::Template::AccessStore',
      access_params => {
      
        BlogCfg            => $self->BlogCfg,
        ScaffoldSet        => $self->ScaffoldSet,
        scaffold_cfg       => $self->scaffold_cfg,
        
        #internal_post_path => $self->scaffold_cfg->internal_post_path,
        #default_view_path  => $self->scaffold_cfg->default_view_path,
        
      
        #scaffold_dir  => $self->scaffold_dir,
        #scaffold_cnf  => $self->scaffold_cnf,
        #static_paths  => $self->scaffold_cnf->{static_paths},
        #private_paths => $self->scaffold_cnf->{private_paths},
        #default_ext   => $self->scaffold_cnf->{default_ext},
        #
        #internal_post_path => $self->scaffold_cnf->{internal_post_path},
        #view_wrappers      => $self->scaffold_cnf->{view_wrappers},
        #default_view_path  => $self->default_view_path,
        #preview_path       => $self->preview_path,
        #
        #underlay_scaffold_dirs => $self->_get_underlay_scaffold_dirs,

        get_Model => sub { $self->base_appname->model('DB') } 
      } 
    },
    
    'Model::Mailer' => {
      smtp_config => $self->smtp_config,
      ( $self->override_email_recipient ? (envelope_to => $self->override_email_recipient) : () )
    }
    
  };
  
  if(my $faviconPath = $self->ScaffoldSet->first_config_value_filepath('favicon')) {
    $config->{RapidApp}{default_favicon_url} = $faviconPath;
  }
  
  if(my $loginTpl = $self->ScaffoldSet->first_config_value_file('login')) {
    $config->{'Plugin::RapidApp::AuthCore'}{login_template} = $loginTpl;
  }
  
  if(my $errorTpl = $self->ScaffoldSet->first_config_value_file('error')) {
    $config->{'RapidApp'}{error_template} = $errorTpl;
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

=head2 smtp_config

Optional HashRef of L<Email::Sender::Transport::SMTP> params which will be used by the app for
sending E-Mails, such as password resets and other notifications. The options are passed directly
to C<Email::Sender::Transport::SMTP->new()>. If the special param C<transport_class> is included,
it will be used as the transport class instead of C<Email::Sender::Transport::SMTP>. If this is
supplied, it should still be a valid L<Email::Sender::Transport> class.

If this option is not supplied, E-Mails will be sent via the localhost using C<sendmail> via 
the default L<Email::Sender::Transport::Sendmail> options.

=head2 override_email_recipient

If set, all e-mails generated by the system will be sent to the specified address instead of normal 
recipients.

=head2 recaptcha_config

Optional HashRef config to enable Google reCAPTCHA v2 validation on supported forms. An account and API 
key pair must be setup with Google first. This config supports the following params:

=head3 public_key

Required. The public, or "SITE KEY" provided by the Google reCAPTCHA settings, after being setup in the 
Google reCAPTCHA system L<www.google.com/recaptcha/admin|http://www.google.com/recaptcha/admin>

=head3 private_key

Required. The private, or "SECRET KEY" provided by the Google reCAPTCHA settings, after being setup in the 
Google reCAPTCHA system L<www.google.com/recaptcha/admin|http://www.google.com/recaptcha/admin>. Both the
C<public_key> and the C<private_key> are provided as a pair and both are required.

=head3 verify_url

Optional URL to use when performing the actual reCAPCTHA validation with Google. Defaults to 
C<https://www.google.com/recaptcha/api/siteverify> which should probably never need to be changed.

=head3 strict_mode

Optional mode (turned off by default) which can be enabled to tighten the enforcement reCAPTCHA, 
requiring it in all locations which is is setup on the server side, regardless of whether or not the 
client form is actually prompting the user with the appropriate reCAPTCHA "I am not a robot" checkbox
dialog. In those cases of client-side forms not properly setup, they will never be able to submit 
because they will always fail reCAPTCHA validation.

When this mode is off (the default) reCAPTCHA validation is only performed when both the client and
the server are properly setup. The downside of this is that it leaves open the scenario of a spammer
direct posting to the server instead of using the actual form. Whether or not this mode should be 
used should be based on need -- if spammers exploit this, turn it on. Otherwise, it is best to leave
it off as it turning it on has the potential to make the site less resilient and reliable.

This param accepts only 2 possible values: 1 (enabled) or 0 (disabled, which is the default).


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


