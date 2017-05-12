# $Id: Makefile.PL,v 1.51 2003/08/28 19:19:33 andreychek Exp $

use lib "./inc";
use strict;
use File::Copy;
use File::Path;
use File::NCopy           qw();
use ExtUtils::MakeMaker   qw( prompt );
use ExtUtils::AutoInstall qw();

# Perl version 5.005_03 is our minimum
eval "use 5.005_03";
if( $@ ) {
    print <<EOT;

 =============================================================
   Perl version 5.005_03 or later is required for OpenPlugin.
   Unfortunatly, you'll need to upgrade in order for it
   to work.  Try installing a new version of Perl to see
   what you're missing :-)
 =============================================================

EOT

   die "Perl version too old, quiting...\n";
}

my $op = OpenPlugin::Installer->new();
my @plugin_dependencies = $op->get_install_list;
my @optional_modules;

if ( $] >= 5.006 ) {
    @optional_modules = qw( Attribute::Handlers 0 );
}

ExtUtils::AutoInstall->import (
   -version             => '0.30',
   -config              => {
      force             => 0,
   },
   -core                => [
      'Class::Factory'      => '1.0',
      'Digest::MD5'         => '2.16',
      'MD5'                 => '',
      'Test::Harness'       => '2.0',
      'Test::More'          => '0.47',
      'Error'               => '',
      'Storable'            => '1.011',
      'Devel::StackTrace'   => '',
      'Time::HiRes'         => '1.20',
      'Archive::Tar'        => '0.23',
      @optional_modules,
      'Params::Validate'    => '',
      'XML::DOM'            => '1.29',
      'Log::Dispatch'       => '2.00',
      'Log::Log4perl'       => '0.25',
      'HTML::Template'      => '',
      'CGI::Application'    => '2.6',
      @plugin_dependencies,
   ],
);

config_openplugin();

WriteMakefile(
    NAME            => 'OpenPlugin',
    VERSION_FROM    => './OpenPlugin.pm',
    test            => { TESTS => $op->get_core_tests . $op->get_plugin_tests },
    ($] >= 5.005 ?
      (ABSTRACT_FROM    => 'OpenPlugin.pm',
       AUTHOR           => 'Eric Andreychek <eric at openthought.net>') : ()),
);

sub config_openplugin {
    unless (prompt("\nCan I install your data files now?", 'Y/n') =~ /^y/i) {
        print "Warning: skipping data file installation.\n";
        print "Normal OpenPlugin operation requires these data files!\n\n";
        return;
    }

    my $data_file = prompt("\n\nWhere would you like to put the OpenPlugin\n" .
                           "configuration files?\n", "/usr/local/etc");
    chomp $data_file;

    unless ( -d $data_file ) {
      mkdir $data_file, 0777 or die
          "Cannot create $data_file: $!";
    }

    if( -f "$data_file/OpenPlugin.conf" ) {
        File::Copy::copy("$data_file/OpenPlugin.conf",
                         "$data_file/OpenPlugin.conf.orig") or die
                            "Cannot backup config file: $!";
        print "\nFound existing [OpenPlugin.conf] file.  Backing up to [OpenPlugin.conf.orig].\n";
    }
    if( -f "$data_file/OpenPlugin-drivermap.conf" ) {
        File::Copy::copy("$data_file/OpenPlugin-drivermap.conf",
                         "$data_file/OpenPlugin-drivermap.conf.orig") or die
                            "Cannot backup config file: $!";
        print "Found existing [OpenPlugin-drivermap.conf] file.  Backing up to [OpenPlugin-drivermap.conf.orig].\n\n";
    }
    my $file = File::NCopy->new(recursive => 1);
    $file->copy("conf/*", "$data_file") or die
        "Cannot copy conf directory to $data_file: $!";

    print "OpenPlugin config files are now in $data_file\n";
    return {};
}

package OpenPlugin::Installer;

use strict;
use ExtUtils::MakeMaker qw(prompt);

###################
# Data Format
#
#  deps
# A reference to an array containing a list of all a particular
# driver's dependencies, in the format:
#   'Module' => 'Version'
#
#  meta
# Meta information for a particular driver.  The following meta information is
# recognized:
# -install -- Means this driver will be installed by default
# -force   -- Forces installation of a particular driver (driver is required)
# -test    -- Name of test to run if installing this driver

sub new {
    my $class = shift;

    my $self = {
        'Request' => {
            Apache2  => {
                deps => [ 'Apache2'   => '' ],
                meta => { -install            => 0,
                          -test               => 't/request_apache2.t' },
            },
            Apache  => {
                deps => [ 'Apache::Request'   => '0.30' ],
                meta => { -install            => 0,
                          -test               => 't/request_apache.t' },
            },
            CGI     => {
                deps => [ 'CGI'    => '', ],
                meta => { -install => 1,
                          -test    => 't/request_cgi.t' },
            },
        },
        Authenticate    => {
            #DBI     => {
            #    deps => [ DBI      => '', ],
            #    meta => { -install => 1,  },
            #},
            PAM     => {
                deps => [ 'Authen::PAM'   => '', ],
                meta => {},
            },
            SMB     => {
                deps => [ 'Authen::Smb'   => '', ],
                meta => {},
            },
        },
        Cache           => {
            File    => {
                deps => [ 'Digest::SHA1'  => '2.02',
                          'Cache::Cache'  => '', ],
                meta => { -install        => 1,
                          -test           => 't/cache_file.t'  },
            },
        },
        Config          => {
            Conf    => {
                deps => [ 'Config::General'   => '', ],
                meta => { -install            => 1,
                          -force              => 1,  },
            },
            Ini     => {
                deps => [],
                meta => { -install        => 1,
                          -force          => 1, },
            },
            Perl    => {
                deps => [ 'Data::Dumper'  => '', ],
                meta => {},
            },

            XML     => {
                deps => [ 'OpenThought::XML2Hash'  => '0.56', ],
                meta => {},
            },
        },
        Datasource      => {
            DBI     => {
                deps => [ DBI      => '', ],
                meta => { -install => 1,  },
            },
            LDAP    => {
                deps => [ 'Net::LDAP' => '', ],
                meta => {},
            },
        },
        Log             => {
            ApacheLog  => {
                deps => [ 'Apache::Log' => '', ],
                meta => {},
            },
            DBI  => {
                deps => [ 'DBI'   => '',
                          'Log::Dispatch::DBI' => '', ],
                meta => {},
            },
            Email  => {
                deps => [ 'Mail::Sendmail' => '', ],
                meta => {},
            },
            Jabber  => {
                deps => [ 'Unicode::String' => '',
                          'Net::SSLeay'     => '',
                          'IO::Socket::SSL' => '0.81',
                          'XML::Stream'     => '',
                          'Net::Jabber'     => '', ],
                meta => {},
            },
            Syslog  => {
                deps => [ 'Sys::Syslog' => '', ],
                meta => {},
            },
        },
        Session         => {
            ApacheSession  => {
                deps => [ 'MIME::Base64'    => '',
                          'DB_File'         => '',
                          'Apache::Session' => '1.54', ],
                meta => { -install          => 1,
                          -test             => 't/session_apachesession.t' },
            },
        },
    };

    bless( $self, $class );
    return $self;
}

sub get_core_tests {
    my $self = shift;

    # Leave a trailing space
    my $tests = "t/01_require.t t/02_config.t t/03_log.t t/04_exception.t ";

    return $tests;
}

# Get a hash (name, version) of modules to be installed
sub get_install_list {
    my $self = shift;

    $self->check_deps;
    $self->handle_input;

    my @install_list = $self->get_scheduled_driver_deps;

    if( @install_list ) {
        return @install_list;
    }
    else {
        return ();
    }
}

sub get_scheduled_driver_deps {
    my $self = shift;

    my @deps_list;
    foreach my $plugin ( $self->get_plugins ) {
        foreach my $driver ( $self->get_scheduled_drivers( $plugin )) {
            foreach my $dep ( $self->_get_driver_deps( $plugin, $driver )) {
                push @deps_list, $dep;
            }
        }
    }

    return @deps_list;
}

sub get_plugin_tests {
    my $self = shift;

    my $test_list;
    foreach my $plugin ( $self->get_plugins ) {
        foreach my $driver ( $self->get_installed_drivers( $plugin ) ){
            foreach my $test ( $self->_get_driver_test( $plugin, $driver )) {
                $test_list .= " $test";
            }
        }

        foreach my $driver ( $self->get_scheduled_drivers( $plugin ) ){
            foreach my $test ( $self->_get_driver_test( $plugin, $driver )) {
                $test_list .= " $test";
            }
        }
    }

    $test_list =~ s/\s+/ /g;
    return $test_list;
}

# The main look for the installation screen
sub handle_input {
    my $self = shift;

    my $action;
    while ( $action ne "d" ) {
        $action = "";
        $self->display_installation_screen;
        while ($action !~ m/^[ardAR]/) {
            $action = (prompt("\n[a]dd, [r]emove, [A]dd All, [R]emove All, [d]one:", "d"));
        }

        if( $action eq "a") {
            $self->add_driver;
        }
        elsif( $action eq "r") {
            $self->remove_driver;
        }
        elsif( $action eq "A") {
            $self->add_all_drivers;
        }
        elsif( $action eq "R") {
            $self->remove_all_drivers;
        }
    }
    print "\nDone.\n\n";
}

# Return a list of all plugins
sub get_plugins {
    my $self = shift;

    return sort keys %{ $self };
}

# Return a list of all drivers for a given plugin
sub get_drivers {
    my ( $self, $plugin ) = @_;

    return sort keys %{ $self->{ $plugin } };
}

# List drivers which currently are not scheduled to be installed
sub get_available_drivers {
    my ( $self, $plugin ) = @_;

    my @all_drivers = sort keys %{ $self->{ $plugin } };
    my @available_drivers;

    foreach my $driver ( @all_drivers ) {

        # If it's already installed, or scheduled to be installed, it's not
        # considered available
        unless(( $self->_to_be_installed( $plugin, $driver )) ||
               ( $self->_already_installed( $plugin, $driver))) {
            push @available_drivers, $driver;
        }
    }
    return @available_drivers;
}

# List drivers which are currently scheduled to be installed
sub get_scheduled_drivers {
    my ( $self, $plugin ) = @_;

    my @all_drivers = sort keys %{ $self->{ $plugin } };
    my @drivers_to_install;

    foreach my $driver ( @all_drivers ) {
        if( $self->_to_be_installed( $plugin, $driver )) {
            push @drivers_to_install, $driver;
        }
    }
    return @drivers_to_install;
}

# List drivers which are already installed
sub get_installed_drivers {
    my ( $self, $plugin ) = @_;

    my @all_drivers = sort keys %{ $self->{ $plugin } };
    my @installed_drivers;

    foreach my $driver ( @all_drivers ) {
        if( $self->_already_installed( $plugin, $driver )) {
            push @installed_drivers, $driver;
        }
    }
    return @installed_drivers;
}

# List drivers which are currently scheduled to be installed
sub get_scheduled_drivers {
    my ( $self, $plugin ) = @_;

    my @all_drivers = sort keys %{ $self->{ $plugin } };
    my @drivers_to_install;

    foreach my $driver ( @all_drivers ) {
        if( $self->_to_be_installed( $plugin, $driver )) {
            push @drivers_to_install, $driver;
        }
    }
    return @drivers_to_install;
}

# See which drivers we already have all the dependencies installed for
sub check_deps {
    my $self = shift;

    foreach my $plugin ( $self->get_plugins ) {
        foreach my $driver ( $self->get_drivers( $plugin ) ) {
            my $driver_test = 1;
            my %deps = $self->_get_driver_deps( $plugin, $driver );

            foreach my $module ( keys %deps ){
                unless (defined (ExtUtils::AutoInstall::_version_check(
                    ExtUtils::AutoInstall::_load($module),
                    $deps{$module} ||= 0 ))) {
                        $driver_test = 0;
                }
            }
            if( $driver_test ) {
                $self->_set_driver_installed( $plugin, $driver );
            }
        }
    }
}

# Remove a scheduled driver
sub remove_driver {
    my $self = shift;

    my @plugins = $self->get_plugins;
    $self->display_ordered_list( @plugins );

    my $msg = "Remove driver from which plugin?";
    my $plugin_num = $self->get_number_input( 1, scalar @plugins, $msg );
    return unless defined $plugin_num;

    my $plugin = $self->get_plugin_by_number( $plugin_num );

    my @drivers = $self->get_scheduled_drivers( $plugin );

    my $driver_num;
    if ( @drivers > 1 ) {
        $self->display_ordered_list( @drivers );
        my $msg = "Remove which driver?";
        my $driver_num = $self->get_number_input( 1, scalar @drivers, $msg );
        return unless defined $driver_num;
    }
    elsif ( @drivers == 1 ) {
        $driver_num = 0;
    }
    else {
        prompt("\n * No drivers from $plugin to remove: ",  "whoops");
        return;
    }

    my $driver = $self->get_scheduled_drivers_by_number( $plugin, $driver_num );
    if ( $self->_unschedule_driver( $plugin, $driver ) ) {
        prompt("\n * Removed the $driver driver from $plugin: ", "okay");
    }
    else {
        prompt("\n * $driver is either already installed on your system, or required: ", "okay");
    }

}

# Schedule a driver to be installed
sub add_driver {
    my $self = shift;

    my @plugins = $self->get_plugins;
    $self->display_ordered_list( @plugins );

    my $msg = "Add driver from which plugin?";
    my $plugin_num = $self->get_number_input( 1, scalar @plugins, $msg );
    return unless defined $plugin_num;

    my $plugin = $self->get_plugin_by_number( $plugin_num );

    my @drivers = $self->get_available_drivers( $plugin );

    my $driver_num;
    if ( @drivers > 1 ) {
        $self->display_ordered_list( @drivers );
        my $msg = "Add which driver?";

        $driver_num = $self->get_number_input( 1, scalar @drivers, $msg );
        return unless defined $driver_num;
    }
    elsif ( @drivers == 1 ) {
        $driver_num = 0;
    }
    else {
        prompt("\n * No more drivers from $plugin to install: ",  "bummer");
        return;
    }

    my $driver = $self->get_available_drivers_by_number( $plugin, $driver_num );
    $self->_schedule_driver( $plugin, $driver );
    prompt("\n * Scheduled the $driver driver from $plugin to be installed: ",
           "okay");
}

sub add_all_drivers {
    my $self = shift;

    foreach my $plugin ( $self->get_plugins ) {
        foreach my $driver ( $self->get_available_drivers( $plugin )) {
            print "P: $plugin, $driver\n";
            $self->_schedule_driver( $plugin, $driver );
        }
    }
}

sub remove_all_drivers {
    my $self = shift;

    foreach my $plugin ( $self->get_plugins ) {
        foreach my $driver ( $self->get_scheduled_drivers( $plugin )) {
            $self->_unschedule_driver( $plugin, $driver );
        }
    }
}

sub get_plugin_by_number {
    my ( $self, $number ) = @_;

    return (sort $self->get_plugins)[$number-1];
}

sub get_available_drivers_by_number {
    my ( $self, $plugin, $number ) = @_;

    return (sort $self->get_available_drivers( $plugin ))[$number-1];
}

sub get_scheduled_drivers_by_number {
    my ( $self, $plugin, $number ) = @_;

    return (sort $self->get_scheduled_drivers( $plugin ))[$number];
}

# Given a min and max number, a prompt and error message, this function gets a
# number as input from the user.  It keeps trying until they give a number
# within the limit
sub get_number_input {
    my ( $self, $min, $max, $prompt ) = @_;

    my $num = $min - 1;

    while(( $num < $min ) || ( $num > $max )) {
        $num = prompt( $prompt . ": [$min-$max]" );

        return undef if $num =~ m/^\s*$/g;

        if(( $num < $min ) || ( $num > $max )) {
            prompt( "\n * Is '$num' one of the choices?", "nope" );
            print "\n";
        }
    }

    return $num;
}

# Given a list of items, displays it line by line with prefixed numbers
sub display_ordered_list {
    my ( $self, @list ) = @_;

    print "\n";
    for( my $i = 1; $i <= $#list+1; $i++ ) {
        print "[$i] $list[$i-1]\n";
    }
    print "\n";
}


sub display_installation_screen {
    my $self = shift;

    my $i;
    foreach my $plugin ( $self->get_plugins ){
         $i += scalar $self->get_installed_drivers( $plugin );
    }
print qq{
\n\n\n\n\n\n\n\n\n\n\n
 OpenPlugin Driver Installation Screen

  I detected dependencies for ($i) drivers already installed on your system.
  You may now choose additional drivers to install.

------------------------------------------------------------------------------
Plugin       | Available Drivers            | Install
------------------------------------------------------------------------------
};
    foreach my $plugin ( $self->get_plugins ) {
        my $available_drivers;
        foreach my $driver ( $self->get_available_drivers( $plugin ) ){
             $available_drivers .= "$driver ";
        }

        my $drivers_to_install;
        foreach my $driver ( $self->get_scheduled_drivers( $plugin ) ){
             $drivers_to_install .= "$driver ";
        }
        #my $installed_drivers;
        #foreach my $driver ( $self->get_installed_drivers( $plugin ) ){
        #     $installed_drivers .= "$driver ";
        #}
format STDOUT =
@<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$plugin        $available_drivers              $drivers_to_install
.
        write;
    }
}

sub display_installed_drivers_screen {
    my $self = shift;

    my $i;
    foreach my $plugin ( $self->get_plugins ){
         $i += scalar $self->get_installed_drivers( $plugin );
    }
    foreach my $plugin ( $self->get_plugins ){
         $i += scalar $self->get_scheduled_drivers( $plugin );
    }
print qq{
\n\n\n\n\n\n\n\n\n\n\n
  When the installation is complete, the following $i drivers will be
  available to you:

------------------------------------------------------------------------------
Plugin       | Drivers
------------------------------------------------------------------------------
};
    foreach my $plugin ( $self->get_plugins ) {
        my $driver_list;
        foreach my $driver ( $self->get_installed_drivers( $plugin ) ){
             $driver_list .= "$driver ";
        }

        foreach my $driver ( $self->get_scheduled_drivers( $plugin ) ){
             $driver_list .= "$driver ";
        }
format STDOUT1 =
@<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$plugin        $driver_list
.
        write STDOUT1;
    }
    <STDIN>;
}

###################
# Private Functions

# Determine whether or not a driver is already installed
sub _already_installed {
    my ( $self, $plugin, $driver ) = @_;

    if( $self->{ $plugin }{ $driver }{'meta'}{'-installed'} ) {
        return 1;
    }
    else {
        return 0;
    }
}

# Set a driver as already being installed
sub _set_driver_installed {
    my ( $self, $plugin, $driver ) = @_;

    $self->{ $plugin }{ $driver }{'meta'}{ '-installed' } = 1;
    $self->{ $plugin }{ $driver }{'meta'}{ '-install' } = 0;
}

# Schedule a driver to be installed
sub _schedule_driver {
    my ( $self, $plugin, $driver ) = @_;

    return $self->{ $plugin }{ $driver }{'meta'}{ '-install' } = 1;
}

# Unschedule a driver from installtion
sub _unschedule_driver {
    my ( $self, $plugin, $driver ) = @_;

    if( $self->{ $plugin }{ $driver }{'meta'}{ '-force' } ) {
        return 0;
    }
    else {
        $self->{ $plugin }{ $driver }{'meta'}{ '-install' } = 0;
        return 1;
    }
}

# Determine whether or not a driver is scheduled for installation
sub _to_be_installed {
    my ( $self, $plugin, $driver ) = @_;

    if( $self->{ $plugin }{ $driver }{'meta'}{'-install'} ) {
        return 1;
    }
    else {
        return 0;
    }
}

# Get a list of dependencies for a given driver
sub _get_driver_deps {
    my ( $self, $plugin, $driver ) = @_;

    return @{ $self->{ $plugin }{ $driver }{'deps'} };
}

# Get a list of dependencies for a given driver
sub _get_driver_test {
    my ( $self, $plugin, $driver ) = @_;

    return $self->{ $plugin }{ $driver }{'meta'}{'-test'};
}

1;
