package OpenInteract::Startup;

# $Id: Startup.pm,v 1.37 2003/03/13 03:26:34 lachoy Exp $

use strict;
use Cwd            qw( cwd );
use Data::Dumper   qw( Dumper );
use File::Basename qw( dirname );
use File::Path     qw();
use Getopt::Long   qw( GetOptions );
use OpenInteract::Config;
use OpenInteract::Config::GlobalOverride;
use OpenInteract::Error;
use OpenInteract::Package;
use OpenInteract::PackageRepository;
use SPOPS::ClassFactory;

$OpenInteract::Startup::VERSION = sprintf("%d.%02d", q$Revision: 1.37 $ =~ /(\d+)\.(\d+)/);

use constant DEBUG => 0;

my $TEMP_LIB_DIR = 'tmplib';
my $REPOS_CLASS  = 'OpenInteract::PackageRepository';
my $PKG_CLASS    = 'OpenInteract::Package';

sub main_initialize {
    my ( $class, $p ) = @_;

    # Ensure we can find the base configuration, and use it or read it in

    return undef unless ( $p->{base_config} or $p->{base_config_file} );
    my $bc = $p->{base_config} ||
             $class->read_base_config({ filename => $p->{base_config_file} });

    # Create our main config object

    my $C = $class->create_config({ base_config  => $bc });

    # Initialize the package repository class -- it's a SPOPS class,
    # but a really simple one

    $REPOS_CLASS->class_initialize( $C );

    # Read in our fundamental modules -- these should be in our @INC
    # already, since the 'request_class' is in
    # 'OpenInteract/OpenInteract' and the 'stash_class' is in
    # 'MyApp/MyApp'

    $class->require_module({ class => [ $bc->{request_class}, $bc->{stash_class} ] });

    # Either use a package list provided or read in all the packages from
    # the website package database

    my $packages = [];
    my $repository = $REPOS_CLASS->fetch( undef, { directory => $bc->{website_dir} } );
    if ( my $package_list = $p->{package_list} ) {
        foreach my $pkg_name ( @{ $p->{package_list} } ) {
            my $pkg_info = $repository->fetch_pacakge_by_name({ name => $pkg_name });
            push @{ $packages }, $pkg_info  if ( $pkg_info );
        }
    }
    else {
        $packages = $repository->fetch_all_packages();
    }

    # We keep track of the package names currently installed and use them
    # elsewhere in the system

    $C->{package_list} = [ map { $_->{name} } @{ $packages } ];
    foreach my $pkg_info ( @{ $packages } ) {
        $class->process_package( $pkg_info, $C );
    }

    $class->_process_global_overrides( $C );
    $class->_require_extra_classes( $C );

    # Store the configuration for later use

    my $stash_class = $bc->{stash_class};
    $stash_class->set_stash( 'config', $C );

    # Create an instance of $R since later steps might need it --
    # particularly SPOPS initialization which may want a connection to
    # the datasource during setup. (Crossing fingers this doesn't mess
    # something up, particularly w/ parent/child sharing issues...)

    my $request_class = $bc->{request_class};
    my $R = $request_class->instance;
    $R->{stash_class} = $stash_class;

    # The config object should now have all actions and SPOPS definitions
    # read in, so run any necessary configuration options

    my $init_class = $class->finalize_configuration({ config => $C });

    # Tell OpenInteract::Request to setup aliases if they haven't already

    if ( $p->{alias_init} ) {
        $request_class->setup_aliases;
    }

    # Initialize all the SPOPS object classes

    if ( $p->{spops_init} ) {
        $class->initialize_spops({ config => $C, class => $init_class });
    }

    # Read in all the classes for all configured conductors

    my @conductor_classes = ();
    foreach my $conductor ( keys %{ $C->{conductor} } ) {
        push @conductor_classes, $C->{conductor}{ $conductor }{class};
    }
    $class->require_module({ class => \@conductor_classes });

    # Read in the modules referred to in the 'system_alias' key from
    # the configuration -- EXCEPT for anything beginning with the
    # website name since that's an SPOPS object and has already been
    # created

    my @system_alias_classes = grep ! /^$bc->{website_name}/, values %{ $C->{system_alias} };
    $class->require_module({ class => \@system_alias_classes });

    DEBUG && _w( 2, "Contents of INC: @INC" );

    # All done! Return the configuration object so the user can
    # do whatever else is necessary

    return ( $init_class, $C );
}


sub setup_static_environment_options {
    my ( $class, $usage, $options, $params ) = @_;
    $options ||= {};
    my ( $OPT_website_dir );
    $options->{'website_dir=s'} = \$OPT_website_dir;

    # Get the options

    GetOptions( %{ $options } );

    if ( ! $OPT_website_dir and $ENV{OIWEBSITE} ) {
        warn "Using ($ENV{OIWEBSITE}) for 'website_dir'.\n";
        $OPT_website_dir = $ENV{OIWEBSITE};
    }

    unless ( -d $OPT_website_dir ) {
        die "$usage\n Parameter 'website_dir' must refer to an OpenInteract website directory!\n";
    }
    return $class->setup_static_environment( $OPT_website_dir, undef, $params );
}


# Use this if you want to setup the OpenInteract environment outside
# of the web application server -- just pass in the website directory!

sub setup_static_environment {
    my ( $class, $website_dir, $su_passwd, $params ) = @_;
    die "Directory ($website_dir) is not a valid directory!\n" unless ( -d $website_dir );
    $params ||= {};

    my $bc = $class->read_base_config({ dir => $website_dir });
    unless ( $bc and ref $bc eq 'HASH' ) {
        die "No base configuration file found in website directory ($website_dir)" ;
    }

    $class->create_temp_lib( $bc, $params->{temp_lib} );

    unshift @INC, $website_dir;

    my ( $init, $C ) = $class->main_initialize({ base_config => $bc,
                                                 alias_init  => 1,
                                                 spops_init  => 1 });
    my $REQUEST_CLASS = $C->{server_info}{request_class};
    my $R = $REQUEST_CLASS->instance;

    $R->{stash_class} = $C->{server_info}{stash_class};
    $R->stash( 'config', $C );

    # If we were given the superuser password, retrieve the user and
    # check the password

    if ( $su_passwd ) {
        my $user = $R->user->fetch( 1, { skip_security => 1 });
        die "Cannot create superuser!" unless ( $user );
        unless ( $user->check_password( $su_passwd ) ) {
            die "Password for superuser does not match!\n";
        }
        $R->{auth}{user} = $user;
    }

    return $R;
}



# Slimmed down initialization procedure -- just do everything
# necessary to read the config and set various values there

sub create_config {
    my ( $class, $p ) = @_;
    my $bc = $p->{base_config} ||
             $class->read_base_config({ filename    => $p->{base_config_file},
                                        website_dir => $p->{website_dir} });
    return undef unless ( $bc );

    # Create the configuration file and set the base directory as configured;
    # also set other important classes from the config

    my $config_file  = join( '/', $bc->{website_dir},
                                  $bc->{config_dir}, $bc->{config_file} );
    my $C = eval { OpenInteract::Config->instance( $bc->{config_type}, $config_file ) };
    if ( $@ ) {
        die "Cannot read configuration file! Error: $@\n";
    }

    # This information will be set for the life of the config object,
    # which should be as long as the apache child is alive if we're using
    # mod_perl, and will be set in the returned config object in any case

    $C->{dir}{base}                  = $bc->{website_dir};
    $C->{dir}{interact}              = $bc->{base_dir};
    $C->{server_info}{request_class} = $bc->{request_class};
    $C->{server_info}{stash_class}   = $bc->{stash_class};
    $C->{server_info}{website_name}  = $bc->{website_name};
    return $C;
}


# Method to copy all .pm files from all packages in a website to a
# separate directory -- if it currently exists we clear it out first.

sub create_temp_lib {
    my ( $class, $base_config, $opt ) = @_;
    $opt ||= '';
    my $site_dir = $base_config->{website_dir};

    my $lib_dir  = $base_config->{templib_dir}
                   || "$site_dir/$TEMP_LIB_DIR";
    unshift @INC, $lib_dir;

    if ( -d $lib_dir and $opt eq 'lazy' ) {
        DEBUG && _w( 1, "Temp lib dir [$lib_dir] already exists and we're lazy;",
                        "not copying modules to temp lib dir" );
        return [];
    }

    File::Path::rmtree( $lib_dir ) if ( -d $lib_dir );
    mkdir( $lib_dir, 0777 );

    my $site_repos = $REPOS_CLASS->fetch( undef,
                                          { directory => $base_config->{website_dir} } );
    my $packages = $site_repos->fetch_all_packages();
    my ( @all_files );
    foreach my $package ( @{ $packages } ) {
        DEBUG && _w( 2, "Trying to copy files for package $package->{name}" );
        my $files_copied = $PKG_CLASS->copy_modules( $package, $lib_dir );
        push @all_files, @{ $files_copied };
    }
    DEBUG && _w( 3, "Copied ", scalar @all_files, " module files to [$lib_dir]" );

    # Now change permissions so all the files and directories are
    # world-everything, letting the process's umask kick in

    chmod( 0666, @all_files );

    my %tmp_dirs = map { $_ => 1 } map { dirname( $_ ) } @all_files;
    chmod( 0777, keys %tmp_dirs );

    return \@all_files;
}


sub read_package_list {
    my ( $class, $p ) = @_;
    return [] unless ( $p->{filename} or $p->{config} );
    my $filename = $p->{filename} ||
                   join( '/', $p->{config}->get_dir( 'config' ), $p->{config}{package_list} );
    open( PKG, $filename ) || die "Cannot open package list ($filename): $!";
    my @packages = ();
    while ( <PKG> ) {
        chomp;
        next if /^\s*\#/;
        next if /^\s*$/;
        s/^\s*//;
        s/\s*$//;
        push @packages, $_;
    }
    close( PKG );
    return \@packages;
}



# simple key-value config file

sub read_base_config {
    my ( $class, $p ) = @_;
    unless ( $p->{filename} ) {
        my $dir = $p->{dir} || $p->{website_dir};
        if ( $dir ) {
            $p->{filename} = $class->create_base_config_filename( $dir );
        }
    }
    return undef   unless ( -f $p->{filename} );
    open( CONF, $p->{filename} ) || die "$!\n";
    my $vars = {};
    while ( <CONF> ) {
        chomp;
        DEBUG && _w( 1, "Config line read: $_" );
        next if ( /^\s*\#/ );
        next if ( /^\s*$/ );
        s/^\s*//;
        s/\s*$//;
        my ( $var, $value ) = split /\s+/, $_, 2;
        $vars->{ $var } = $value;
    }
    return $vars;
}

sub create_base_config_filename {
    my ( $class, $dir ) = @_;
    return join( '/', $dir, 'conf', 'base.conf' );
}

# Params:
#  filename - file with modules to read, one per line (skip blanks, commented lines)
#  class    - arrayref of classes to require
# (pick one)

sub require_module {
    my ( $class, $p ) = @_;
    my @success = ();
    if ( $p->{filename} ) {
        DEBUG && _w( 1, "Trying to open file $p->{filename}" );
        return [] unless ( -f $p->{filename} );
        open( MOD, $p->{filename} ) || die "Cannot open $p->{filename}: $!";
        while ( <MOD> ) {
            next if ( /^\s*$/ );
            next if ( /^\s*\#/ );
            chomp;
            DEBUG && _w( 1, "Trying to require $_" );
            eval "require $_";
            if ( $@ ) { _w( 0, sprintf( " --require error: %-40s: %s", $_, $@ ) )  }
            else      { push @success, $_ }
        }
        close( MOD );
    }
    elsif ( $p->{class} ) {
        $p->{class} = [ $p->{class} ] unless ( ref $p->{class} eq 'ARRAY' );
        foreach ( @{ $p->{class} } ) {
            DEBUG && _w( 1, "Trying to require class ($_)" );
            eval "require $_";
            if ( $@ ) { _w( 0, sprintf( " --require error: %-40s (from %s): %s", $_, $p->{pkg_link}{$_}, $@ ) ) }
            else      { push @success, $_ }
        }
    }
    return \@success;
}



# Params:
#  config = config object
#  package = name of package
#  package_dir = arrayref of base package directories (optional, read from config if not passed)

sub process_package {
    my ( $class, $pkg_info, $CONF ) = @_;
    return undef unless ( $pkg_info );
    return undef unless ( $CONF );

    my $pkg_name = join( '-', $pkg_info->{name}, $pkg_info->{version} );
    DEBUG && _w( 1, "Trying to process package ($pkg_name)" );

    my $site_pkg_dir = join( '/', $pkg_info->{website_dir}, $pkg_info->{package_dir} );
    my $base_pkg_dir = join( '/', $pkg_info->{base_dir}, $pkg_info->{package_dir} );
    DEBUG && _w( 1, "Pkg dirs: ($base_pkg_dir, $site_pkg_dir) for $pkg_name" );

    # Plow through the directories and find the module listings (to
    # include), action config (to parse and set) and the SPOPS config (to
    # parse and set). Base package first so its info can be overridden.

    foreach my $package_dir ( $base_pkg_dir, $site_pkg_dir ) {
        my $conf_pkg_dir = "$package_dir/conf";

        # If the package does not have a 'list_module.dat', that's ok and the
        # 'require_module' class method will simply return an empty list.

        $class->require_module({ filename => "$conf_pkg_dir/list_module.dat" });

        # Read in the 'action' information and set in the config object

        $class->read_action_definition({ filename => "$conf_pkg_dir/action.perl",
                                         config   => $CONF,
                                         package  => $pkg_info });

        # Read in the SPOPS information and set in the config object; note
        # that we cannot *process* the SPOPS config yet because we must be
        # able to relate SPOPS objects, which cannot be done until all the
        # definitions are read in. (Yes, we could use 'map' here and above,
        # but it's confusing to people first reading the code)

        $class->read_spops_definition({ filename => "$conf_pkg_dir/spops.perl",
                                        config   => $CONF,
                                        package  => $pkg_info });
    }
}



# Read in the action config info and set the information in the CONFIG
# object. note that we overwrite whatever information is in the CONFIG
# object -- this is a feature, not a bug, since it allows the base
# installation to define lots of information and the website to only
# override what it needs.

# Also save the key under which this was retrieved under 'key'

sub read_action_definition {
    my ( $class, $p ) = @_;
    DEBUG && _w( 1, "Reading action definitions from ($p->{filename})" );

    # $CONF is easier to read and more consistent

    my $CONF = $p->{config};
    my $action_info = eval { $class->read_perl_file({ filename => $p->{filename} }) };
    return undef  unless ( $action_info );
    my @class_list = ();
    foreach my $action_key ( keys %{ $action_info } ) {
        $CONF->{action}{ $action_key }{key} = $action_key;
        foreach my $action_conf ( keys %{ $action_info->{ $action_key } } ) {
            $CONF->{action}{ $action_key }{ $action_conf } =
                                   $action_info->{ $action_key }{ $action_conf };
        }
        if ( ref $p->{package} ) {
            $CONF->{action}{ $action_key }{package_name}    = $p->{package}{name};
            $CONF->{action}{ $action_key }{package_version} = $p->{package}{version};
        }
    }
}



# See comments in read_action_definition

sub read_spops_definition {
    my ( $class, $p ) = @_;
    DEBUG && _w( 1, "Reading SPOPS definitions from ($p->{filename})" );

    # $CONF is easier to read and more consistent
    my $CONF = $p->{config};
    my $spops_info = eval { $class->read_perl_file({ filename => $p->{filename} }) };
    return undef unless ( $spops_info );
    my @class_list = ();
    foreach my $spops_key ( keys %{ $spops_info } ) {
        $CONF->{SPOPS}{ $spops_key }{key} = $spops_key;
        foreach my $spops_conf ( keys %{ $spops_info->{ $spops_key } } ) {
            $CONF->{SPOPS}{ $spops_key }{ $spops_conf } =
                                   $spops_info->{ $spops_key }{ $spops_conf };
        }
        if ( ref $p->{package} ) {
            $CONF->{SPOPS}{ $spops_key }{package_name}    = $p->{package}{name};
            $CONF->{SPOPS}{ $spops_key }{package_version} = $p->{package}{version};
        }
    }
}


# Read in a perl structure (probably generated by Data::Dumper) from a
# file and return the actual structure. We should probably use
# SPOPS::HashFile for this for consistency...

sub read_perl_file {
    my ( $class, $p ) = @_;
    return undef unless ( -f $p->{filename} );
    eval { open( INFO, $p->{filename} ) || die $! };
    if ( $@ ) {
        warn "Cannot open config file for evaluation ($p->{filename}): $@ ";
        return undef;
    }
    local $/ = undef;
    no strict;
    my $info = <INFO>;
    close( INFO );
    my $data = eval $info;
    if ( $@ ) {
        die "Cannot read data structure! from $p->{filename}\nError: $@";
    }
    return $data;
}


# Everything has been read in, now just finalize aliases and so on

sub finalize_configuration {
    my ( $class, $p ) = @_;
    my $CONF = $p->{config};
    my $REQUEST_CLASS      = $CONF->{server_info}{request_class};
    my $STASH_CLASS        = $CONF->{server_info}{stash_class};

    # Create all the packages and subroutines on the fly as necessary

    DEBUG && _w( 1, "Trying to configure SPOPS classes with SPOPS::ClassFactory" );
    my $init_class = SPOPS::ClassFactory->create( $CONF->{SPOPS} );

    # Setup the default responses, template classes, etc. for all the
    # actions read in.

    $CONF->flatten_action_config;
    DEBUG && _w( 2, "Config: \n", Dumper( $CONF ) );
    DEBUG && _w( 1, "Configuration read into Request ok." );

    # We also want to go through each alias in the 'SPOPS' config key
    # and setup aliases to the proper class within our Request class; so
    # $request_alias is just a reference to where we'll actually be storing
    # this stuff

    my $request_alias = $REQUEST_CLASS->ALIAS;
    DEBUG && _w( 1, "Setting up SPOPS aliases" );
    foreach my $init_alias ( keys %{ $CONF->{SPOPS} } ) {
        next if ( $init_alias =~ /^_/ );
        my $info        = $CONF->{SPOPS}{ $init_alias };
        my $class_alias = $info->{class};
        my @alias_list  = ( $init_alias );
        push @alias_list, @{ $info->{alias} } if ( $info->{alias} );
        foreach my $alias ( @alias_list ) {
            DEBUG && _w( 1, "Tag $alias in $STASH_CLASS to be $class_alias" );
            $request_alias->{ $alias }{ $STASH_CLASS } = $class_alias;
        }
    }

    DEBUG && _w( 1, "Setting up System aliases" );
    foreach my $alias ( keys %{ $CONF->{system_alias} } ) {
        $request_alias->{ $alias }{ $STASH_CLASS } = $CONF->{system_alias}{ $alias };
    }
    DEBUG && _w( 1, "Setup object and system aliases ok" );
    return $init_class;
}


# Plow through a list of classes and call the class_initialize
# method on each; ok to call OpenInteract::Startup->initialize_spops( ... )
# from the mod_perl child init handler

sub initialize_spops {
    my ( $class, $p ) = @_;
    return undef unless ( ref $p->{class} );
    return undef unless ( ref $p->{config} );
    my @success = ();

 # Just cycle through and initialize each

    foreach my $spops_class ( @{ $p->{class} } ) {
        eval { $spops_class->class_initialize( $p->{config} ); };
        push @success, $spops_class unless ( $@ );
        DEBUG && _w( 1, sprintf( "%-40s: %-30s","init: $spops_class", ( $@ ) ? $@ : 'ok' ) );
    }
    return \@success;
}


# Do any global overrides for both SPOPS and the action table entries.

sub _process_global_overrides {
    my ( $class, $config ) = @_;
    my $override_spops_file = join( '/', $config->{dir}{base},
                                         $config->{override}{spops_file} );
    my $override_action_file = join( '/', $config->{dir}{base},
                                          $config->{override}{action_file} );

    if ( -f $override_spops_file ) {
        my $override_spops = OpenInteract::Config::GlobalOverride->new(
                                        { filename => $override_spops_file } );
        $override_spops->apply_rules( $config->{SPOPS} );
    }
    if ( -f $override_action_file ) {
        my $override_action = OpenInteract::Config::GlobalOverride->new(
                                        { filename => $override_action_file } );
        $override_action->apply_rules( $config->{action} );
    }
}


sub _require_extra_classes {
    my ( $class, $config ) = @_;
    my ( %require_class );

    my $action_require = $class->_find_extra_action_classes( $config );
    my $spops_require  = $class->_find_extra_spops_classes( $config );

    # Read in all the classes specified by the packages

    my $successful_action = $class->require_module({
                               class    => [ keys %{ $action_require } ],
					           pkg_link => $action_require });
    if ( scalar @{ $successful_action } != scalar keys %{ $action_require } ) {
        my %all_tried = map { $_ => 1 } keys %{ $action_require };
        delete $all_tried{ $_ } for ( @{ $successful_action } );
        _w( 0, "Some action classes were not required: ",
               join( ', ', keys %all_tried ) );
    }

    my $successful_spops = $class->require_module({
                               class    => [ keys %{ $spops_require } ],
					           pkg_link => $spops_require });
    if ( scalar @{ $successful_spops } != scalar keys %{ $spops_require } ) {
        my %all_tried = map { $_ => 1 } keys %{ $spops_require };
        delete $all_tried{ $_ } for ( @{ $successful_spops } );
        _w( 0, "Some SPOPS classes were not required: ",
               join( ', ', keys %all_tried ) );
    }
}


sub _find_extra_action_classes {
    my ( $class, $config ) = @_;
    my %map = ();
    my $action = $config->{action};
    foreach my $key ( keys %{ $action } ) {
        next unless ( $key and $action->{ $key });
        my $package = $action->{ $key }{package_name};
        if ( $action->{ $key }{class} ) {
            $map{ $action->{ $key }{class} } = $package
        }
        if ( $action->{ $key }{filter} ) {
            if ( ref $action->{ $key }{filter} eq 'ARRAY' ) {
                $map{ $_ } = $package for ( @{ $action->{ $key }{filter} } );
            }
            else {
                $map{ $action->{ $key }{filter} } = $package
            }
        }
        if ( $action->{ $key }{error} ) {
            if ( ref $action->{ $key }{error} eq 'ARRAY' ) {
                $map{ $_ } = $package for ( @{ $action->{ $key }{error} } );
            }
            else {
               $map{ $action->{ $key }{error} } = $package;
            }
        }
    }
    return \%map;
}


sub _find_extra_spops_classes {
    my ( $class, $config ) = @_;
    my %map = ();
    my $spops = $config->{SPOPS};
    foreach my $key ( keys %{ $spops } ) {
        next unless ( $key and $spops->{ $key });
        my $package = $spops->{ $key }{package_name};
        if ( ref $spops->{ $key }{isa} eq 'ARRAY' ) {
            map { $map{ $_ } = $package } @{ $spops->{ $key }{isa} };
        }
    }
    return \%map;
}



sub _w {
  return unless ( DEBUG >= shift );
  my ( $pkg, $file, $line ) = caller;
  my @ci = caller(1);
  warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}

1;

__END__

=head1 NAME

OpenInteract::Startup -- Bootstrapper that reads in modules and initializes the environment

=head1 SYNOPSIS

 # Startup an OpenInteract environment outside Apache and mod_perl

 use strict;
 use OpenInteract::Startup;

 my $R =  OpenInteract::Startup->setup_static_environment(
                                      '/home/httpd/MySite' );

 # Same thing, but read the website directory from the command-line
 # parameter '--website_dir' or the environment variable 'OIWEBSITE'

 my $R =  OpenInteract::Startup->setup_static_environment_options();

 # For usage in Apache/mod_perl, see OpenInteract::ApacheStartup

=head1 DESCRIPTION

This module has a number of routines that are (hopefully) independent
of the OpenInteract implementation. One of its primary goals is to
make it simple to initialize OpenInteract not only in a mod_perl
context but also a single-use context. For example, when you create a
script to be run as a cron job to do some sort of data checking (or
whatever), you should not be required to put 50 lines of
initialization in your script just to create the framework.

This script should also minimize the modules you have to include
yourself, making it easier to add backward-compatible
functionality. Most of the time, you only need to have a 'use'
statement for this module which takes care of everything else.

=head1 METHODS

All methods use the class method invocation syntax, such as:

 OpenInteract::Startup->require_module({ class => [ $my_class ] });

B<main_initialize( \%params )>

This will frequently be the only method you call of this class. This
routine goes through a number of common steps:

=over 4

=item 1.

read in the base configuration file

=item 2.

require the config class, request class and stash class

=item 3.

create the config object

=item 4.

process all packages (see L<process_package()> below)

=item 5.

finalize the configuration (see L<finalize_configuration()> below

=item 6.

set the config object into the stash class

=item 7.

create aliases in the request object (optional)

=item 8.

create/initialize all SPOPS object classes (optional)

=back

The return value is a list with two members. The first is an arrayref
of all SPOPS object class names that currently exist. The second is a
fully setup I<OpenInteract::Config> object. Note that his may change in
the future to be a single return value of the config object with the
class names included as a parameter of it.

Parameters:

You B<must> pass in either 'base_config' or 'base_config_file'.

=over 4

=item *

B<base_config> (\%)

A hashref with the information from the base configuration file

=item *

B<base_config_file> ($)

A filename where the base configuration can be found

=item *

B<alias_init> (bool) (optional)

A true value will initialize aliases within the request class; the
default is to not perform the initialization.

=item *

B<spops_init> (bool) (optional)

A true value will create/initialize all SPOPS classes (see
L<SPOPS::ClassFactory> for more information); the default is to not
perform the initialization.

B<package_extra> (\@) (optional)

A list of packages not included in the filename of packages to read in
but you want to include anyway (maybe you are testing a new package
out). The packages included will be put at the end of the packages to
be read in, although it is feasible that we break this into two extra
package listings -- those to be read in before everything else (but
still after 'base') and those to be read in after everything else. See
if there is a need...

=back

B<setup_static_environment( $website_dir, [ $superuser_password ] )>

Sometimes you want to setup OI even when you are not in a web
environment -- for instance, you might need to do data reporting, data
import/export, or other tasks.

With this method, all you need to pass in is the root directory of
your website. It will deal with everything else, including:

=over 4

=item *

Reading in the server configuration

=item *

Reading in all SPOPS and action table configurations -- this includes
setting up @INC properly.

=item *

Setting up all aliases -- SPOPS object and otherwise

=item *

Creating a database handle

=back

If you pass in as the second argument a superuser password, it will
create the user and check the password. If the password matches, you
(and OpenInteract) will have access to the superuser object in the
normal place (C<$R-E<gt>{auth}-E<gt>{user}>).

If you do not wish to do this, you need to pass in a true value for
'skip_log' and 'skip_security' whenever you modify and/or retrieve
objects.

Returns: A "fully-stocked" C<OpenInteract::Request> object.

Example:

 #!/usr/bin/perl

 use strict;
 use OpenInteract::Startup;

 my $R = OpenInteract::Startup->setup_static_environment( '/home/httpd/my' );

 my $news_list = eval { $R->news->fetch_group({ where => 'title like ?',
                                                value => [ '%iraq%' ],
                                                skip_security => 1 }) };
 foreach my $news ( @{ $news_list } ) {
   print "Date:  $news->{posted_on}\n",
         "Title: $news->{title}\n"
         "Story: $news->{news_item}\n";
 }

Easy!

B<setup_static_environment_options( $usage, [ \%options ] )>

Same as C<setup_static_environment()>, but this method will try to
pull the 'website_dir' parameter from the command line (using the long
option '--website_dir') or if not found there the environment variable
'OIWEBSITE'.

The parameter C<$usage> is for displaying if the 'website_dir'
parameter can be found in neither.

The optional parameter C<\%options> is for parsing additional
commandline options. The keys of the hashref should be formatted in
the manner L<Getopt::Long> expects, and the values should be some type
of reference (depending on the key and your intentions).

Example:

 #!/usr/bin/perl

 use strict;
 use OpenInteract::Startup;

 my $usage = "$0 --website_dir=/path/to/site --title=title";
 my ( $OPT_title );
 my %options = ( 'title=s' => \$OPT_title );
 my $R = OpenInteract::Startup->setup_static_environment_options(
                                                      $usage, \%options );

 my $news_iter = eval { $R->news->fetch_iterator({ where => 'title like ?',
                                                   value => [ "%$OPT_title%" ],
                                                   skip_security => 1 }) };
 while ( my $news = $news_iter->get_next ) {
   print "Date:  $news->{posted_on}\n",
         "Title: $news->{title}\n"
         "Story: $news->{news_item}\n";
 }

B<read_package_list( \%params )>

Reads in a list of packages from a file, one package per line.

Returns: arrayref of package names.

Parameters:

Choose one or the other

=over 4

=item *

B<config> (\%)

An OpenInteract::Config object which has 'package_list' as a key; this
file is assumed to be in the 'config' directory, also found on the
object.

=item *

B<filename> ($)

A scalar specifying where the packages can be read from.

=back

B<read_base_config( \%params )>

Reads in the base configuration file, which is a simple per-line
whitespace-separated key-value format.

Returns a hashref with all information.

Parameters:

=over 4

=item *

B<filename> ($)

A scalar specifying where the file is located; it must have a
fully-qualified path.

=item *

B<dir> ($)

A scalar specifying the website directory which has the file
'conf/base.conf' under it.

=back

B<require_module( \%params )>

Calls C<require> on one or a number of modules. You can specify a
filename composed of module names (one module per line) and all will
be read in. You can also specify a number of modules to read in.

Returns: arrayref of modules successfully read in.

Parameters (choose one of the two):

=over 4

=item *

B<filename> ($)

Name of file which has modules to read in; one module per line, blank
lines and lines beginning with a comment (#) are skipped

=item *

B<class> ($ | \@)

Single classname or arrayref of classnames to read in.

=back

B<process_package( \%params )>

Do initial work to process a particular package. This includes reading
in all external modules and reading both the action configuration and
SPOPS configuration files for inclusion in the config object. We also
include any modules used in the action definition (if you specify a
'class' in a action definition) as well as those in the 'isa' property
of a SPOPS class definition.

We also add the package directory to @INC, which means any 'use' or
'require' statements that need modules within the package will be able
to work. (See the I<OpenInteract Guide to Packages> for more
information on what goes into a package and how it is laid out.)

Note that we do B<not> create/configure the SPOPS classes yet, since
that process requires that all SPOPS classes to be used exist in the
configuration. (See L<SPOPS::ClassFactory> for more details.)

Parameters:

=over 4

=item *

B<package> ($)

Name of package to be processed; this should correspond to a
particular directory in the package directory

=item *

B<config> (obj)

An L<OpenInteract::Config> object or hashref with configuration
information.

=item *

B<package_dir> (\@) (optional)

Directories where this package might be kept; if not passed in, it
will be found from the config object

=back

B<read_action_definition( \%params )>

Read in a action definition file (a perl data structure) and set its
information in the config object. Multiple actions can be configured,
and we do a 'require' on any actions referenced.

Parameters:

=over 4

=item *

B<filename> ($)

File where the action definion is.

=item *

B<config> (obj)

OpenInteract::Config object where we set the action information.

=item *

B<package> (\%)

Hashref with information about a package so we can set name/version
info.

=back

B<read_spops_definition( \%params )>

Read in a module definition file (a perl data structure) and set its
information in the config object. Multiple SPOPS objects can be
configured, and we do a 'require' on any modules referenced.

Parameters:

=over 4

=item *

B<filename> ($)

File where the module definion is.

=item *

B<config> (obj)

OpenInteract::Config object where we set the module information.

=item *

B<package> (obj)

Hashref with information about a package so we can set name/version
info.

=back

B<read_perl_file( \%params )>

Simple routine to read in a file generated by or compatible with a
perl data structure and return its value. For instance, your file
could have something like the following:

 $action = {
            'boxes' => {
                'class'     => 'OpenInteract::Handler::Boxes',
                'security'  => 'no',
            }, ...
 };

And the return value would be the hashref that C<$module> is set
to. The actual name of the variable is irrelevant, just the data
structure assigned to it.

Return value is the data structure in the file, or undef if the file
does not exist or the data structure is formatted incorrectly. If the
latter happens, check your error log (STDERR) and a warning will
appear.

Parameters:

=over 4

=item *

B<filename> ($)

File to read data structure from.

=back

Note: we should modify this to use L<SPOPS::HashFile>...

B<finalize_configuration( \%params )>

At this point, all the SPOPS and module information should be read
into the configuration object and we are ready to finish up the
configuration procedure. This means call the final SPOPS
configuration, which creates classes as necessary and puts
configuration information and routines to link the objects
together. We also call the various routines in the 'request_class'
(usually OpenInteract::Request) to create necessary aliases for classes
from both SPOPS and base system elements.

Return value is an arrayref of all SPOPS classes that are
configured. Each one needs to be initialized before use, which can
handily be done for you in the C<initialize_spops> method.

Parameters:

=over 4

=item *

B<config> (obj)

An OpenInteract::Config configuration object. Note that the keys
'request_class' and 'stash_class' must be defined in the config object
prior to calling this routine.

=back

B<initialize_spops( \%params )>

Call the C<class_initialize> method for each of the SPOPS classes
specified. This must be done before the package can be used.

Returns an arrayref of classes successfully initialized.

Parameters:

=over 4

=item *

B<class> (\@)

An arrayref of classes to initialize.

=item *

B<config> (obj)

An L<OpenInteract::Config> configuration object, needed by the
C<class_initialize> method within the SPOPS classes.

=back

=head1 TO DO

B<Find common code with SPOPS::Initialize>

L<SPOPS::Initialize> is new in version 0.40 and contains common code
for initializing SPOPS object classes. We should be able to use it to
perform some of our actions.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters L<chris@cwinters.com>
