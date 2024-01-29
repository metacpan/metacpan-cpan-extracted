# (c) Jan Gehring <jan.gehring@gmail.com>
# (c) Zane C. Bowers-Hadley

package Rex::CMDB::YAMLwithRoles;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use base qw(Rex::CMDB::Base);

use Rex::Commands -no => [qw/get/];
use Rex::Logger;
use YAML::XS;
use Data::Dumper;
use Hash::Merge qw/merge/;

require Rex::Commands::File;

sub new {
	my $that  = shift;
	my $proto = ref($that) || $that;
	my $self  = {@_};

	$self->{merger} = Hash::Merge->new();

	if ( !defined $self->{merge_behavior} ) {
		$self->{merger}->specify_behavior(
			{
				SCALAR => {
					SCALAR => sub { $_[0] },
					ARRAY  => sub { $_[0] },
					HASH   => sub { $_[0] },
				},
				ARRAY => {
					SCALAR => sub { $_[0] },
					ARRAY  => sub { $_[0] },
					HASH   => sub { $_[0] },
				},
				HASH => {
					SCALAR => sub { $_[0] },
					ARRAY  => sub { $_[0] },
					HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
				},
			},
			'REX_DEFAULT',
		);    # first found value always wins

		$self->{merger}->set_behavior('REX_DEFAULT');
	} else {
		if ( ref $self->{merge_behavior} eq 'HASH' ) {
			$self->{merger}->specify_behavior( $self->{merge_behavior}, 'USER_DEFINED' );
			$self->{merger}->set_behavior('USER_DEFINED');
		} else {
			$self->{merger}->set_behavior( $self->{merge_behavior} );
		}
	}

	bless( $self, $proto );

	# turn roles off by default
	if ( !defined( $self->{use_roles} ) ) {
		$self->{use_roles} = 0;
	}

	# set the default role path ro 'cmdb/roles'
	if ( !defined( $self->{roles_path} ) ) {
		$self->{roles_path} = File::Spec->join( $self->{path}, 'roles' );
	}

	# if parsing failure should be fatal
	# default true
	if ( !defined( $self->{parse_error_fatal} ) ) {
		$self->{parse_error_fatal} = 1;
	}

	# die if the role does not exist
	# default true
	if ( !defined( $self->{missing_role_fatal} ) ) {
		$self->{missing_role_fatal} = 1;
	}

	# default to false, config overwrites role settings
	if ( !defined( $self->{roles_merge_after} ) ) {
		$self->{roles_merge_after} = 0;
	}

	return $self;
} ## end sub new

sub get {
	my ( $self, $item, $server ) = @_;

	$server = $self->__get_hostname_for($server);

	my $result = {};

	# keep this out here so generated when the files are loaded
	# keep it around later for role processing
	my %template_vars;

	if ( $self->__cache->valid( $self->__cache_key() ) ) {
		$result = $self->__cache->get( $self->__cache_key() );
	} else {

		my @files = $self->_get_cmdb_files( $item, $server );

		Rex::Logger::debug( Dumper( \@files ) );

		# configuration variables
		my $config_values = Rex::Config->get_all;
		for my $key ( keys %{$config_values} ) {
			if ( !exists $template_vars{$key} ) {
				$template_vars{$key} = $config_values->{$key};
			}
		}
		$template_vars{environment} = Rex::Commands::environment();

		for my $file (@files) {
			Rex::Logger::debug("CMDB - Opening $file");
			if ( -f $file ) {

				my $content = eval { local ( @ARGV, $/ ) = ($file); <>; };
				my $t       = Rex::Config->get_template_function();
				$content .= "\n";    # for safety
				$content = $t->( $content, \%template_vars );

				my $ref;
				my $parse_error;
				eval { $ref = Load($content); };
				if ($@) {
					$parse_error = $@;
				}

				# only merge it if we have a actual result
				if ( !defined($parse_error) ) {
					$result = $self->{merger}->merge( $result, $ref );
				} else {
					my $error = 'Failed to parse YAML config file "' . $file . '" with error... ' . $parse_error;
					if ( $self->{parse_error_fatal} ) {
						die($error);
					} else {
						warn($error);
					}
				}
			} ## end if ( -f $file )
		} ## end for my $file (@files)
	} ## end else [ if ( $self->__cache->valid( $self->__cache_key...))]

	# if use_roles is true, process the roles variablesif set
	# the item has roles and that the roles is a array
	if (   $self->{use_roles}
		&& ( defined( $result->{roles} ) )
		&& ( ref( $result->{roles} ) eq 'ARRAY' ) )
	{
		Rex::Logger::debug("CMDB - Starting role processing");

		# load each role
		foreach my $role ( @{ $result->{roles} } ) {
			Rex::Logger::debug( "CMDB - Processing role '" . $role . "'" );
			my $role_file = File::Spec->join( $self->{roles_path}, $role . '.yaml' );

			# if the file exists, load it
			if ( -f $role_file ) {

				my $content = eval { local ( @ARGV, $/ ) = ($role_file); <>; };
				my $t       = Rex::Config->get_template_function();
				$content .= "\n";    # for safety
				$content = $t->( $content, \%template_vars );

				my $ref;
				my $parse_error;
				eval { $ref = Load($content); };
				if ($@) {
					$parse_error = $@;
				}

				# only merge it if we have a actual result
				# undef causes the merge feature to wipe it all out
				# that and it did error... so we need to handle the error
				if ( !defined($parse_error) ) {

					# don't let host variables override the role if
					# roles_merge_after is true
					if ( $self->{roles_merge_after} ) {
						$result = $self->{merger}->merge( $ref, $result );
					} else {
						$result = $self->{merger}->merge( $result, $ref );
					}
				} else {
					my $error = 'Failed to parse YAML role file "' . $role_file . '" with error... ' . $parse_error;
					if ( $self->{parse_error_fatal} ) {
						die($error);
					} else {
						warn($error);
					}
				}
			} else {
				my $error = "The role '" . $role . "' is specified by the file '" . $role_file . "' does not eixst";
				if ( $self->{missing_role_fatal} ) {
					die($error);
				} else {
					warn($error);
				}
			}
		} ## end foreach my $role ( @{ $result->{roles} } )
	} ## end if ( $self->{use_roles} && ( defined( $result...)))

	if ( defined $item ) {
		return $result->{$item};
	}
	return $result;
} ## end sub get

sub _get_cmdb_files {
	my ( $self, $item, $server ) = @_;

	$server = $self->__get_hostname_for($server);

	my @files;

	if ( !ref $self->{path} ) {
		my $env          = Rex::Commands::environment();
		my $server_file  = "$server.yaml";
		my $default_file = 'default.yaml';
		@files = (
			File::Spec->join( $self->{path}, $env, $server_file ),
			File::Spec->join( $self->{path}, $env, $default_file ),
			File::Spec->join( $self->{path}, $server_file ),
			File::Spec->join( $self->{path}, $default_file ),
		);
	} elsif ( ref $self->{path} eq "CODE" ) {
		@files = $self->{path}->( $self, $item, $server );
	} elsif ( ref $self->{path} eq "ARRAY" ) {
		@files = @{ $self->{path} };
	}

	my $os = Rex::Hardware::Host->get_operating_system();

	@files = map { $self->_parse_path( $_, { hostname => $server, operatingsystem => $os, } ) } @files;

	return @files;
} ## end sub _get_cmdb_files

1;

__END__

=head1 NAME

Rex::CMDB::YAMLwithroles - YAML-based CMDB provider for Rex with support for roles

=head1 DESCRIPTION

This module collects and merges data from a set of YAML files to provide configuration
management database for Rex.

=head1 SYNOPSIS

    use Rex::CMDB;
    
    set cmdb => {
        type           => 'YAMLwithRoles',
        path           => [ 'cmdb/{hostname}.yaml', 'cmdb/default.yaml', ],
        merge_behavior => 'LEFT_PRECEDENT',
    };
    
    task 'prepare', 'server1', sub {
        my $all_information          = get cmdb;
        my $specific_item            = get cmdb('item');
        my $specific_item_for_server = get cmdb( 'item', 'server' );
    };

=head1 CONFIGURATION AND ENVIRONMENT

=head2 path

The path used to look for CMDB files. It supports various use cases depending on the
type of data passed to it.

=over 4

=item * Scalar

    set cmdb => {
        type => 'YAMLwithRoles',
        path => 'path/to/cmdb',
     };

If a scalar is used, it tries to look up a few files under the given path:

    path/to/cmdb/{environment}/{hostname}.yaml
    path/to/cmdb/{environment}/default.yaml
    path/to/cmdb/{hostname}.yaml
    path/to/cmdb/default.yaml

=item * Array reference

    set cmdb => {
        type => 'YAMLwithRoles',
        path => [ 'cmdb/{hostname}.yaml', 'cmdb/default.yaml', ],
    };

If an array reference is used, it tries to look up the mentioned files in the given
order.

=item * Code reference

    set cmdb => {
        type => 'YAMLwithRoles',
        path => sub {
            my ( $provider, $item, $server ) = @_;
            my @files = ( "$server.yaml", "$item.yaml" );
            return @files;
        },
    };

If a code reference is passed, it should return a list of files that would be looked
up in the same order. The code reference gets the CMDB provider instance, the item,
and the server as parameters.

=back

When the L<0.51 feature flag|Rex#0.51> or later is used, the default value of the
C<path> option is:

    [qw(
        cmdb/{operatingsystem}/{hostname}.yaml
        cmdb/{operatingsystem}/default.yaml
        cmdb/{environment}/{hostname}.yaml
        cmdb/{environment}/default.yaml
        cmdb/{hostname}.yaml
        cmdb/default.yaml
    )]

The path specification supports macros enclosed within curly braces, which are
dynamically expanded during runtime. By default, the valid macros are L<Rex::Hardware>
variables, C<{server}> for the server name of the current connection, and C<{environment}>
for the current environment.

Please note that the default environment is, well, C<default>.

You can define additional CMDB paths via the C<-O> command line option by using a
semicolon-separated list of C<cmdb_path=$path> key-value pairs:

 rex -O 'cmdb_path=cmdb/{domain}.ymal;cmdb_path=cmdb/{domain}/{hostname}.yaml;' taskname

Those additional paths will be prepended to the current list of CMDB paths (so the last one
specified will get on top, and thus checked first).

=head2 merge_behavior

This CMDB provider looks up the specified files in order, and returns the requested data. If
multiple files specify the same data for a given item, then the first instance of the data
will be returned by default.

Rex uses L<Hash::Merge> internally to merge the data found on different levels of the CMDB
hierarchy. Any merge strategy supported by that module can be specified to override the
default one. For example one of the built-in strategies:

    set cmdb => {
        type           => 'YAMLwithRoles',
        path           => 'cmdb',
        merge_behavior => 'LEFT_PRECEDENT',
    };

Or even custom ones:

    set cmdb => {
        type           => 'YAMLwithRoles',
        path           => 'cmdb',
        merge_behavior => {
            SCALAR => sub {},
            ARRAY  => sub {},
            HASH   => sub {},
    };

For the full list of options, please see the documentation of Hash::Merge.

=head2 use_roles

Specifies if roles should be used or not.

This value is a Perl boolean and defaults to '0'.

=head2 roles_path

The path to look for roles under.

By default it is 'cmdb/roles'.

=head2 parse_error_fatal

If it should die or warn upon YAML parsing error.

This is a Perl boolean and the default is '1', to die.

=head2 missing_role_fatal

If a specified role not being able to be found is fatal.

This is a Perl boolean and the default is '1', to die.

=head2 roles_merge_after

If it should merge the roles into the config instead of the default
of merging the config into the roles.

This is a Perl boolean and the default is '0', meaning the config
will over write anything in the roles with the default merge_behavior
settings.

=head1 ROLES

NOTE: Currently only compatible with scalar value for paths.

If use_roles has been set to true, when loading a config file, it will check for
value 'roles' and if that value is a array, it will then go through and look foreach
of those roles under the roles_path.

So lets say we have the config below.

    foo: "bar"
    ping: "no"
    roles:
      - 'test'

It will then load look under the roles_path for the file 'test.yaml', which with
the default settings would be 'cmdb/roles/test.yaml'.

Lets say we have the the role file set as below.

    ping: "yes"
      ping_test:
        misses: 3

This means with the value for ping will be 'no' as the default of 'yes' is being
overriden by the config value.

Somethings to keep in mind when using this.

1: Don't define a value you intend to use in a role in any of the config files that
will me merged unless you want it to always override anything a role may import. So
with like the example above, you would want to avoid putting ping='no' in the default
yaml file and only set it if you want to override that role in like the yaml config
for that host.

2: Roles may not include roles. While it won't error or the like, they also won't
be reeled in.

=cut
