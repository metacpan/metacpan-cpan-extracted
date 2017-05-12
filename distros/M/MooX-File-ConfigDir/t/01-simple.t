#!perl

use strict;
use warnings FATAL => "all";

eval {
    require local::lib;
    #local::lib->import();
};

package #
  My;

use Moo;

with "MooX::File::ConfigDir";

1;

package #
  main;

use Test::More;

my @supported_functions = (
                            qw(config_dirs system_cfg_dir desktop_cfg_dir),
                            qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
                            qw(local_cfg_dir here_cfg_dir singleapp_cfg_dir),
			    qw(xdg_config_dirs xdg_config_home user_cfg_dir),
                          );

my $mxfcd = My->new();

foreach my $fn (@supported_functions)
{
    my @dirs = @{ $mxfcd->$fn };
    note( "$fn: " . join( ",", @dirs ) );
    if ( $fn =~ m/(?:xdg_)?config_dirs/ or $fn =~ m/(?:machine|desktop)_cfg_dir/ )
    {
        ok( scalar @dirs >= 1, "config_dirs" ) or diag( join( ",", @dirs ) );    # we expect at least system_cfg_dir
    }
    elsif ( $fn =~ m/(?:local|user)_cfg_dir/ || $fn eq "xdg_config_home" )
    {
        ok( scalar @dirs <= 1, $fn ) or diag( join( ",", @dirs ) );    # probably we do not have local::lib or File::HomeDir
    }
    elsif( $^O eq "MSWin32" and $fn eq "local_cfg_dir" )
    {
        ok( scalar @dirs == 0, $fn ) or diag( join( ",", @dirs ) );
    }
    else
    {
        ok( scalar @dirs == 1, $fn ) or diag( join( ",", @dirs ) );
    }
}

done_testing();
