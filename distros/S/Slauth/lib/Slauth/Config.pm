# Slauth configuration

package Slauth::Config;

use strict;
use Data::Dumper;
#use warnings FATAL => 'all', NONFATAL => 'redefine';

our $debug = $ENV{SLAUTH_DEBUG};
#our $debug = 1;
sub debug { $debug; }

###########################################################################
# No user-servicable parts beyond this point
#
# Instead... use the Apache "SlauthConfig" directive (provided by
# Slauth::Config::Apache) or the SLAUTH_CONFIG environment variable
# to specify a Slauth configuration file.
#

# instantiate a new configuration object
sub new
{
        my $class = shift;
        my $self = {};

	debug and print STDERR "debug: Slauth::Config: new\n";

	# if an Apache request was provided, upgrade the object to
	# Slauth::Config::Apache from the start so it's mod_perl-aware
	debug and print STDERR "Slauth::Config::new: \$_[0] is ".
		((defined $_[0]) ? "" : "not ")." present\n";
	if ( debug and defined $_[0] ) {
		print STDERR "Slauth::Config::new: \$_[0] is ".
			ref( $_[0] )."\n";
		print STDERR "Slauth::Config::new: ".
			"isa('Apache::RequestRec') is ".
				($_[0]->isa('Apache::RequestRec')
					? "true" : "false" )."\n";
		print STDERR "Slauth::Config::new: ".
			"isa('Apache2::RequestRec') is ".
				($_[0]->isa('Apache2::RequestRec')
					? "true" : "false" )."\n";
	}
	if (( defined $_[0] ) and
		( $_[0]->isa('Apache::RequestRec') or
		$_[0]->isa('Apache2::RequestRec')))
	{
		eval "require Slauth::Config::Apache";
		bless $self, "Slauth::Config::Apache";
	} else {
		bless $self, $class;
	}
        $self->initialize(@_);
        return $self;
}

# initialize a Slauth::Config variable
# note: Slauth::Config::Apache has a separate initialize() function
# which will be used for objects blessed into its class
sub initialize
{
	my $self = shift;

	# allow SLAUTH_REALM from environment to set the request realm
	if ( defined $ENV{SLAUTH_REALM}) {
		$self->{realm} = $ENV{SLAUTH_REALM};
	} elsif ( !defined $self->{realm}) {
		$self->{realm} = "localhost";
	}

	# allow SLAUTH_CONFIG from environment to invoke the config file
	if ( defined $ENV{SLAUTH_CONFIG}) {
		my %config;
		debug and print STDERR "debug: Slauth::Config: reading from ".$ENV{SLAUTH_CONFIG}." (from environment)\n";
		eval $self->gulp($ENV{SLAUTH_CONFIG});
		$config{realm} = $self->{realm};
		$self->{config} = \%config;

		# add "perl_inc" parameter to @INC
		if ( defined $self->{config}{global}{perl_inc}) {
			push @INC, @{$self->{config}{global}{perl_inc}};
		}
	} elsif ( -f "/etc/slauth/slauth.conf" ) {
		my %config;
		debug and print STDERR "debug: Slauth::Config: reading from /etc/slauth/slauth.conf (default)\n";
		eval $self->gulp( "/etc/slauth/slauth.conf" );
		$self->{config} = \%config;
	}
	$self->correct_realm_for_aliases();

	# make a blank config if it wasn't already created
	if ( ! defined $self->{config}) {
		debug and print STDERR "debug: Slauth::Config: empty config\n";
		$self->{config} = {};
		$self->{config}{global} = {};
		$self->{config}{$self->{realm}} = {};
	}
}

# look up a config value
sub get
{
	my ( $self, $key ) = @_;
	my ( $res );

	if ( $key eq "config" ) {
		return $self;
	}
	if ( $key eq "realm" ) {
		return $self->{realm};
	}
	$res = $self->get_indirect ( $self->{realm}, $key );
	if ( !defined $res ) {
		$res = $self->get_indirect ( "global", $key );
	}
	return $res;
}

# look up config entry with recursive redirection if necessary
# this function is intended to be called only by get() and itself
# use get() if you want to do any kind of config lookups
sub get_indirect
{
	my ( $self, $conf_ref, $key, $stack ) = @_;

	#debug and print STDERR "get_indirect ( $conf_ref, $key, $stack )\n";

	# check that $conf_ref is not already on stack
	my $i;
	if ( !defined $stack ) {
		# this relieves the initial call from responsibility to
		# allocate the stack - it uses undef instead
		$stack = [];
	}
	for ( $i=0; $i < @$stack; $i++ ) {
		if ( $conf_ref eq $stack->[$i][0]) {
			# prevent infinite loop
			return undef;
		}
	}
	push ( @$stack, [ $conf_ref, $key ]);

	# perform indirection on lookup
	my $c_type = ref $conf_ref;
	if ( ! $c_type ) {
		if ( defined $self->{config}{$conf_ref}) {
			return $self->get_indirect( 
				$self->{config}{$conf_ref},
				$key, $stack );
		} else {
			return undef;
		}
	} elsif ( $c_type eq "HASH" ) {
		if ( $key eq "_conf" ) {
			return $conf_ref;
		} elsif ( $key eq "_realm" ) {
			return $stack->[$#{@$stack}-1][0];
		} elsif ( defined $conf_ref->{$key}) {
			my $i_type = ref $conf_ref->{$key};
			if ( ! $i_type ) {
				# scalar is end value
				return $conf_ref->{$key};
			} elsif ( $i_type eq "ARRAY" ) {
				my $indirect_type = $conf_ref->{$key}[0];
				my $indirect_dest = $conf_ref->{$key}[1];

				if ( $indirect_type eq "config" ) {
					return $self->get_indirect( 
						$self->{config}{$indirect_dest},
						$key, $stack );
				}
			} elsif ( $i_type eq "CODE" ) {
				return &{$conf_ref->{$key}}($stack->[0][0]);
			}
		} else {
			return undef;
		}
	}
}

# gulp read a configuration file into a string
sub gulp
{
	my ( $self, $file ) = @_;

	if ( open ( FILE, $file )) {
		my @text = <FILE>;
		close FILE;
		return join ('', @text );
	}
	return undef;
}

# correct realm for any alias names it may represent
sub correct_realm_for_aliases
{
	my $self = shift;
	my $in_realm = $self->{realm};
	debug and print STDERR "debug: "
		."Slauth::Config::correct_realm_for_aliases: in: "
		.$in_realm."\n";
	debug and print STDERR Dumper($self->{config})."\n";

	my $corrected_realm = $self->get( "_realm" );
	debug and print STDERR "debug: "
		."Slauth::Config::correct_realm_for_aliases: correction: "
		.((defined $corrected_realm)?$corrected_realm:"undef")
		."\n";
	if ( defined $corrected_realm ) {
		debug and print STDERR "debug: "
			."Slauth::Config::correct_realm_for_aliases: "
			."correcting realm from ".$in_realm
			." to ".$corrected_realm."\n";
		$self->{realm} = $corrected_realm;
		$self->{config}{realm} = $self->{realm};
	}
	# with the config loaded, resolve any aliases for the realm
	# it's an alias if the realm's name is a string which is the
	# name of another realm
	#if (( exists $self->{config}{$in_realm}) and
	#	( !ref($self->{config}{$in_realm}))
	#	and ( exists $self->{config}{$self->{config}{$in_realm}}))
	#{
	#	debug and print STDERR "debug: "
	#		."Slauth::Config::correct_realm_for_aliases: "
	#		."correcting realm from ".$in_realm
	#		." to ".$self->{config}{$in_realm}."\n";
	#	$self->{realm} = $self->{config}{$in_realm};
	#	$self->{config}{realm} = $self->{realm};
	#}
	debug and print STDERR "debug: "
		."Slauth::Config::correct_realm_for_aliases: out: "
		.$self->{realm}."\n";
}

1;
