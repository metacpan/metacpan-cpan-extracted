# Slauth configuration for Apache
# This is used conditionally by Slauth::Config when we're running under
# Apache HTTPD 2 with mod_perl >= 1.99

package Slauth::Config::Apache;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use base "Slauth::Config";
use Exporter 'import';
use Data::Dumper;	# uncomment if Dumper debugging calls get uncommented
BEGIN {
	Slauth::Config::debug && print STDERR __PACKAGE__.": begin\n";
	if ( eval "require mod_perl2" ) {
		Slauth::Config::debug && print STDERR __PACKAGE__.": mod_perl 2 detected\n";
		$Slauth::Config::Apache::MOD_PERL = 2;
		require Apache2::Const;
		import Apache2::Const qw( OR_ALL FLAG TAKE1 );
		require Apache2::CmdParms;
		require Apache2::Module;
		require Apache2::Access;
	} elsif ( eval "require mod_perl" ) {
		if ((defined $mod_perl::VERSION) and $mod_perl::VERSION >= 1.99 ) {
			Slauth::Config::debug && print STDERR __PACKAGE__.": mod_perl 1.99 detected\n";
			$Slauth::Config::Apache::MOD_PERL = 1.99;
			require Apache2;
			require Apache::Const;
			import Apache::Const qw( OR_ALL FLAG TAKE1 );
			require Apache::CmdParms;
			require Apache::Module;
		} else {
			die "Slauth::Config: mod_perl 1 not supported\n";
		}
	} else {
		die "Slauth::Config: mod_perl not installed\n";
	}
}

sub debug { &Slauth::Config::debug; }

# establish Apache configuration directives
our @directives = (
	{
		name => 'Slauth',
		func => __PACKAGE__.'::Cfg_SlauthEnable',
		req_override => OR_ALL,
		args_how => FLAG,
		errmsg => 'Slauth [On|Off]',
	},
	{
		name => 'SlauthConfig',
		func => __PACKAGE__.'::Cfg_SlauthConfigFile',
		req_override => OR_ALL,
		args_how => TAKE1,
		errmsg => 'SlauthConfig "/path/to/config/file"',
	},
	{
		name => 'SlauthSSLRequired',
		func => __PACKAGE__.'::Cfg_SlauthSSLRequired',
		req_override => OR_ALL,
		args_how => FLAG,
		errmsg => 'SlauthSSLRequired [On|Off]',
	},
); 

# for compatibility across mod_perl 1.99.x and 2.x releases...
if ( $Slauth::Config::Apache::MOD_PERL >= 2 ) {
	eval 'Apache2::Module::add("'.__PACKAGE__.'", \@directives)';
} else {
	eval 'Apache::Module::add("'.__PACKAGE__.'", \@directives)';
}

# initialize a Slauth::Config variable
# note: Slauth::Config has a separate initialize() function
# which will be used for objects blessed into its class
sub initialize
{
	my $self = shift;
        my $r = shift;

	debug and print STDERR "debug: Slauth::Config::Apache::initialize: entry\n";

	# get Slauth configuration from previous Apache handlers if available
	if ( $r->pnotes("slauth-config")) {
		# we've already done the configuration work - don't do it again
		debug and print STDERR "debug: Slauth::Config::Apache: retaining config from previous handler\n";
		my $config = $r->pnotes("slauth-config");
		$self->{config} = $config->{config};
		$self->{dir_cfg} = $config->{dir_cfg};
		$self->{realm} = $config->{realm};
	} else {
		# get Apache per-directory configuration wherever we are
		if ( $Slauth::Config::Apache::MOD_PERL >= 2 ) {
			$self->{dir_cfg} = Apache2::Module::get_config(
				__PACKAGE__, $r->server(),
				$r->per_dir_config());
		} else {
			$self->{dir_cfg} = Apache::Module::get_config(
				__PACKAGE__, $r->server(),
				$r->per_dir_config());
		}
		debug and print STDERR "dir_cfg: ".Dumper($self->{dir_cfg})."\n";

		# find the realm or host from the request for later convenience
		# since it's used as an index for some configuration lookups
		if ( $r->auth_name() ) {
			$self->{realm} = $r->auth_name();
		} elsif ( $r->hostname() ) {
			$self->{realm} = $r->hostname();
		}

		# get config file from per-directory configuration
		if ( exists $self->{dir_cfg}{SlauthConfigFile}) {
			my %config;
			debug and print STDERR "debug: Slauth::Config::Apache: reading from ".$self->{dir_cfg}{SlauthConfigFile}." (from Apache config)\n";
			eval $self->gulp( $self->{dir_cfg}{SlauthConfigFile});
			$self->{config} = \%config;
		} elsif ( -f "/etc/slauth/slauth.conf" ) {
			my %config;
			debug and print STDERR "debug: Slauth::Config::Apache: reading from /etc/slauth/slauth.conf (default)\n";
			eval $self->gulp( "/etc/slauth/slauth.conf" );
			$self->{config} = \%config;
		} else {
			debug and print STDERR "debug: Slauth::Config::Apache: empty config\n";
			$self->{config} = {};
			$self->{config}{global} = {};
			$self->{config}{$self->{realm}} = {};
		}
		$self->correct_realm_for_aliases();

		# add "perl_inc" parameter to @INC
		if ( exists $self->{config}{global}{perl_inc}) {
			push @INC, @{$self->{config}{global}{perl_inc}};
		}

		# save this config for later Apache handlers
		$r->pnotes("slauth-config", $self);
	}
}

# test if Slauth is enabled in the current directory (external function)
# attempts to use minimal resources to avoid overhead of loading all configs
sub isEnabled
{
	my ( $r ) = @_;

	debug and print STDERR "debug: Slauth::Config::Apache::isEnabled: entry\n";

	my $dir_cfg;
	debug and print STDERR "debug: Slauth::Config::Apache::isEnabled: mod_perl rev = ".$Slauth::Config::Apache::MOD_PERL."\n";
	if ( $Slauth::Config::Apache::MOD_PERL >= 2 ) {
		$dir_cfg = Apache2::Module::get_config( __PACKAGE__,
			$r->server(), $r->per_dir_config());
	} else {
		$dir_cfg = Apache::Module::get_config( __PACKAGE__,
			$r->server(), $r->per_dir_config());
	}
	debug and print STDERR "debug: Slauth::Config::Apache::isEnabled: ".
		((defined $dir_cfg) ? $dir_cfg->{enable} : "undef" )."\n";
	if ( exists $dir_cfg->{enable}) {
		return $dir_cfg->{enable};
	}

	# default is to disable Slauth
	return 0;
}

#
# Apache HTTPD server configuration callbacks
#

sub SERVER_CREATE { return create( @_ ); }

sub DIR_CREATE { return create( @_ ); }

sub create
{
	my($class, $parms) = @_;
	return bless {
		name => __PACKAGE__,
	}, $class;
}

sub SERVER_MERGE { return merge( @_ ); }

sub DIR_MERGE { return merge( @_ ); }

sub merge
{
	my($base, $add) = @_;
	my %mrg = ();
	my $key;
	foreach $key ( keys %$base, keys %$add ) {
		next if exists $mrg{$key};

		# override
		if ( exists $add->{$key}) {
			$mrg{$key} = $add->{$key};
		} elsif ( exists $base->{$key} ) {
			$mrg{$key} = $base->{$key};
		}
	}
	return bless \%mrg, ref($base);
}

# callback handler for Apache "Slauth" directive
# enables Slauth in the current directory
# Slauth will not operate without it, and require authentication if it is on
sub Cfg_SlauthEnable
{
	my( $cfg_self, $parms, $arg ) = @_;
	$cfg_self->{enable} = $arg;
}

# callback handler for Apache "SlauthConfig" directive
# sets Slauth configuration file and reads from it
sub Cfg_SlauthConfigFile
{
	my( $cfg_self, $parms, $arg ) = @_;
	$cfg_self->{SlauthConfigFile} = $arg;
}

# callback handler for Apache "SlauthSSLRequired" directive
# sets flag indicating whether SSL access is required
sub Cfg_SlauthSSLRequired
{
	my( $cfg_self, $parms, $arg ) = @_;
	$cfg_self->{ssl_required} = $arg;
}

#
# functions that override parent class
#

# get configuration attribute - try Apache Config first, fall back to parent
sub get
{
        my ( $self, $key ) = @_;
	my ( $res ); 

	# check if the key exists in the module's Apache configuration
	if ( exists $self->{dir_cfg}{$key}) {
		return $self->{dir_cfg}{$key};
	}

	# if not, use Slauth::Config's get()
	return $self->SUPER::get( $key );
}

1;
