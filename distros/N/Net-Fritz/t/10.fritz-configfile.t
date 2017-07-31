#!perl
use Test::More tests => 18;
use warnings;
use strict;

use Test::TempDir::Tiny;

use File::Basename;
use File::Path qw(make_path);

BEGIN { use_ok('Net::Fritz::ConfigFile') };


### public tests

subtest 'check new()' => sub {
    # given

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile' );

    # then
    is( $config->configfile, undef,           'Net::Fritz::ConfigFile->configfile' );
};

subtest 'check new() with named parameters' => sub {
    # given

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile',
		      [ configfile  => 't/config.file' ]
	);

    # then
    is( $config->configfile, 't/config.file', 'Net::Fritz::ConfigFile->configfile' );
};

subtest 'check new() with single parameter' => sub {
    # given

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ 't/config.file' ] );

    # then
    is( $config->configfile, 't/config.file', 'Net::Fritz::ConfigFile->configfile' );
};

subtest 'configuration() returns configfile content' => sub {
    # given
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ 't/config.file' ]);

    # when
    my $vars = $config->configuration;

    # then
    is_deeply( $vars,
	       {
		   upnp_url => 'UPNP',
		   trdesc_path => 'TRDESC',
		   username => 'USER',
		   password => 'PASS'
	       },
	       'configuration data' );
};

subtest 'empty configfile returns empty configuration' => sub {
    # given
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ 't/empty.file' ]);

    # when
    my $vars = $config->configuration;

    # then
    is_deeply( $vars, {}, 'configuration data' );
};


subtest '~ is expanded to $HOME in configfile name' => sub {
    # given
    ok( exists $ENV{HOME}, '$HOME is set' );

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ '~/config.file' ] );

    # then
    is( $config->configfile, "$ENV{HOME}/config.file", 'Net::Fritz::ConfigFile->configfile' );
};

subtest 'use ~/.fritzrc as default configfile if filename is not set' => sub {
    # given
    # ensure that ~/.fritzrc exists
    $ENV{HOME} = tempdir();
    touch_file("$ENV{HOME}/.fritzrc");

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ 0 ] );

    # then
    is( $config->configfile, "$ENV{HOME}/.fritzrc", 'Net::Fritz::ConfigFile->configfile' );
};

subtest 'missing default configfile returns empty configuration' => sub {
    # given
    # ensure that no default configfiles exist
    $ENV{HOME} = tempdir();
    delete $ENV{XDG_CONFIG_HOME};

    # when
    my $config = new_ok( 'Net::Fritz::ConfigFile', [ 0 ] );

    # then
    is_deeply( $config->configuration, {}, 'configuration data' );
};

subtest 'missing default configfile returns original false configfile value' => sub {
    # given
    # ensure that no default configfiles exist
    $ENV{HOME} = tempdir();
    delete $ENV{XDG_CONFIG_HOME};

    # when
    my $numeric_false = new_ok( 'Net::Fritz::ConfigFile', [ 0  ] );
    my $string_false  = new_ok( 'Net::Fritz::ConfigFile', [ '' ] );

    # then
    is( $numeric_false->configfile, 0,  'configfile (0)'  );
    is( $string_false->configfile,  '', 'configfile ("")' );
};


### internal tests

subtest 'config location #1: $XDG_CONFIG_HOME/fritzrc if both variable and file exist' => sub {
    # given
    $ENV{XDG_CONFIG_HOME} = tempdir();
    create_config_files(1, 0, 0);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{XDG_CONFIG_HOME}/fritzrc", 'configfile' );
};

subtest 'config location #1: $XDG_CONFIG_HOME/fritzrc not if variable is missing' => sub {
    # given
    delete $ENV{XDG_CONFIG_HOME};

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, undef, 'configfile' );
};

subtest 'config location #1: $XDG_CONFIG_HOME/fritzrc not if file is missing' => sub {
    # given
    $ENV{XDG_CONFIG_HOME} = tempdir();

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, undef, 'configfile' );
};

subtest 'config location #2: ~/.config/fritzrc if file exists' => sub {
    # given
    $ENV{HOME} = tempdir();
    create_config_files(0, 1, 0);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{HOME}/.config/fritzrc", 'configfile' );
};

subtest 'config location #3:  ~/.fritzrc if file exists' => sub {
    # given
    $ENV{HOME} = tempdir();
    create_config_files(0, 0, 1);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{HOME}/.fritzrc", 'configfile' );
};

subtest 'prefer config location #1 over #2' => sub {
    # given
    $ENV{HOME} = tempdir();
    $ENV{XDG_CONFIG_HOME} = tempdir();
    create_config_files(1, 1, 0);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{XDG_CONFIG_HOME}/fritzrc", 'configfile' );
};

subtest 'prefer config location #1 over #3' => sub {
    # given
    $ENV{HOME} = tempdir();
    $ENV{XDG_CONFIG_HOME} = tempdir();
    create_config_files(1, 0, 1);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{XDG_CONFIG_HOME}/fritzrc", 'configfile' );
};

subtest 'prefer config location #2 over #3' => sub {
    # given
    $ENV{HOME} = tempdir();
    delete $ENV{XDG_CONFIG_HOME};
    create_config_files(0, 1, 1);

    # when
    my $configfile = Net::Fritz::ConfigFile::_find_default_configfile();

    # then
    is( $configfile, "$ENV{HOME}/.config/fritzrc", 'configfile' );
};


### helper methods

sub create_config_files
{
    my ($xdg_by_env, $xdg_default, $home_default) = @_;

    touch_file( "$ENV{XDG_CONFIG_HOME}/fritzrc" ) if $xdg_by_env;
    touch_file( "$ENV{HOME}/.config/fritzrc")     if $xdg_default;
    touch_file( "$ENV{HOME}/.fritzrc" )           if $home_default;
}

sub touch_file
{
    my $file = shift;

    my $dir = dirname($file);
    make_path $dir unless -d $dir;

    open EMPTYFILE, '>', $file or die $!;
    close EMPTYFILE or die $!;    
}
