package Shell::Var::Reader::CMDB;

use 5.006;
use strict;
use warnings;
use File::ShareDir ":ALL";
use File::Slurp qw(read_dir write_file read_dir);
use File::Copy;
use String::ShellQuote;

=head1 NAME

Shell::Var::Reader::CMDB - Helper for creating and updating shell_var_reader based CMDB.

=head1 VERSION

Version 0.1.2

=cut

our $VERSION = '0.1.2';

=head1 SUBROUTINES

=head2 init

Initiates a directory tree for creating a CMDB using shell_var_reader.
with some very minor example stuff.

    Shell::Var::Reader::CMDB->init(
                                   dir=>'./foo/',
                                   exists_okay=>1,
                                   verbose=>1,
                                   init_group_slug=>'example',
                                   );

At the minimum 'dir' must be specified.

    - dir :: Path to where to create it.
        - Default :: undef.

    - exists_okay :: If the directory already existing is okay.
        - Default :: 1

    - verbose :: If it should be verbose or not.
        - Default :: 1

    - init_group_slug :: Name of the example group dir.
        - Default :: example

=cut

sub init {
	my ( $empty, %opts ) = @_;

	# set the defaults
	my $defaults = {
		exists_okay     => 1,
		verbose         => 1,
		init_group_slug => 'example',
	};
	my @default_keys = keys( %{$defaults} );
	foreach my $check_key (@default_keys) {
		if ( !defined( $opts{$check_key} ) ) {
			$opts{$check_key} = $defaults->{$check_key};
		}
	}

	# handle checking if the dir already exists and deciding what to do if it already does
	if ( !defined( $opts{dir} ) ) {
		die('$opts{dir} is undef');
	} else {
		if ( -e $opts{dir} && !$opts{exists_okay} ) {
			die( '"' . $opts{dir} . '" already exists' );
		} elsif ( -e $opts{dir} && !-d $opts{dir} ) {
			die( '"' . $opts{dir} . '" already exists and is not a directory' );
		}
	}

	# create the base dir if needed
	if ( !-d $opts{dir} ) {
		if ( $opts{verbose} ) {
			print 'creating dir "' . $opts{dir} . '"' . "\n";
		}
		mkdir( $opts{dir} ) || die( 'dir "' . $opts{dir} . '" could not be created' );
		if ( $opts{verbose} ) {
			print 'dir "' . $opts{dir} . '" created' . "\n";
		}
	} else {
		if ( $opts{verbose} ) {
			print 'dir "' . $opts{dir} . '" already exists' . "\n";
		}
	}

	# create the additional dirs
	my @additional_dirs = ( 'json_confs', 'shell_confs', 'toml_confs', 'yaml_confs', 'cmdb', 'cmdb/roles' );
	# create initial slug group dir if needed
	if ( $opts{init_group_slug} ne '' ) {
		push( @additional_dirs, $opts{init_group_slug} );
	}
	foreach my $additional_dir (@additional_dirs) {
		$additional_dir = $opts{dir} . '/' . $additional_dir;
		if ( !-d $additional_dir ) {
			if ( $opts{verbose} ) {
				print 'creating dir "' . $additional_dir . '"' . "\n";
			}
			mkdir($additional_dir) || die( 'dir "' . $additional_dir . '/" could not be created' );
			if ( $opts{verbose} ) {
				print 'dir "' . $additional_dir . '" created' . "\n";
			}
		} else {
			if ( $opts{verbose} ) {
				print 'dir "' . $additional_dir . '" already exists' . "\n";
			}
		}
	} ## end foreach my $additional_dir (@additional_dirs)

	# copy the share files into place
	my @share_files = ( 'README.md', 'starting_include.sh', 'ending_include.sh' );
	my $share_dir   = dist_dir('Shell-Var-Reader');
	foreach my $share_file (@share_files) {
		my $destination = $opts{dir} . '/' . $share_file;
		my $source      = $share_dir . '/' . $share_file;
		if ( !-e $destination ) {
			if ( $opts{verbose} ) {
				print 'copying "' . $source . '" to "' . $destination . '"' . "\n";
			}
			copy( $source, $destination ) || die( 'Failed to copy "' . $source . '" to "' . $destination . '"' );
			if ( $opts{verbose} ) {
				print 'copied "' . $source . '" to "' . $destination . '"' . "\n";
			}
		} else {
			if ( $opts{verbose} ) {
				print 'file "' . $destination . '" already exists' . "\n";
			}
		}
	} ## end foreach my $share_file (@share_files)

	# copy the example system into place
	if ( $opts{init_group_slug} ne '' ) {
		my $destination = $opts{dir} . '/' . $opts{init_group_slug} . '/example.foo.bar.sh';
		my $source      = $share_dir . '/example_host.sh';
		if ( !-e $destination ) {
			if ( $opts{verbose} ) {
				print 'copying "' . $source . '" to "' . $destination . '"' . "\n";
			}
			copy( $source, $destination ) || die( 'Failed to copy "' . $source . '" to "' . $destination . '"' );
			if ( $opts{verbose} ) {
				print 'copied "' . $source . '" to "' . $destination . '"' . "\n";
			}
		} else {
			if ( $opts{verbose} ) {
				print 'file "' . $destination . '" already exists' . "\n";
			}
		}
	} ## end if ( $opts{init_group_slug} ne '' )

	# touch files that should be empty but exist by default
	my @empty_files = ( '.shell_var_reader', 'cmdb/default.toml', 'munger.pl' );
	foreach my $file (@empty_files) {
		$file = $opts{dir} . '/' . $file;
		if ( !-e $file ) {
			if ( $opts{verbose} ) {
				print 'creating file "' . $file . '"' . "\n";
			}
			write_file( $file, '' );
			if ( $opts{verbose} ) {
				print 'created file "' . $file . '"' . "\n";
			}
		} else {
			if ( $opts{verbose} ) {
				print 'file "' . $file . '" already exists' . "\n";
			}
		}
	} ## end foreach my $file (@empty_files)

	# sets the example group config
	my $group_file = $opts{dir} . '/' . $opts{init_group_slug} . '/_group_conf.sh';
	if ( !-e $group_file ) {
		if ( $opts{verbose} ) {
			print 'file creating "' . $group_file . '"' . "\n";
		}
		write_file(
			$group_file, '#!/bin/sh
. ../starting_include.sh

SYSTEM_GROUP=' . $opts{init_group_slug} . '

# put group specific options below
'
		);
		if ( $opts{verbose} ) {
			print 'file created "' . $group_file . '"' . "\n";
		}
	} else {
		if ( $opts{verbose} ) {
			print 'file "' . $group_file . '" already exists' . "\n";
		}
	}

	return 1;
} ## end sub init

=head2 update

Reads through the directory and process all relevant files.

    Shell::Var::Reader::CMDB->update(
                                   dir=>'./foo/',
                                   verbose=>1,
                                   );

At the minimum 'dir' must be specified.

    - dir :: Path to where to create it.
        - Default :: undef.

    - verbose :: If it should be verbose or not.
        - Default :: 1

=cut

sub update {
	my ( $empty, %opts ) = @_;

	# set the defaults
	my $defaults = {
		exists_okay => 1,
		verbose     => 1,
	};
	my @default_keys = keys( %{$defaults} );
	foreach my $check_key (@default_keys) {
		if ( !defined( $opts{$check_key} ) ) {
			$opts{$check_key} = $defaults->{$check_key};
		}
	}

	# handle checking if the dir already exists and deciding what to do if it already does
	if ( !defined( $opts{dir} ) ) {
		die('$opts{dir} is undef');
	} else {
		if ( !-d $opts{dir} ) {
			die( '"' . $opts{dir} . '" does not exist or is not a directory' );
		}
	}

	# make sure this file exists, ortherwise likely not a directory this should be operating on
	if ( !-f $opts{dir} . '/.shell_var_reader' ) {
		die(      'Does not appear to be a directory for cmdb_shell_var_reader ... "'
				. $opts{dir}
				. '/.shell_var_reader" does not exist or is not a file' );
	}

	# figure out if it should use the munger or not
	my $munger_option = '';
	if ( -f $opts{dir} . '/munger.pl' ) {
		$munger_option = '-m ../munger.pl';
	}

	# get a list of directories to process and start work on it
	chdir( $opts{dir} );
	my @system_groups = grep {
			   -d $_
			&& !-f "$_/.not_a_system_group"
			&& $_ !~ /^\./
			&& $_ ne 'json_confs'
			&& $_ ne 'shell_confs'
			&& $_ ne 'toml_confs'
			&& $_ ne 'yaml_confs'
			&& $_ ne 'cmdb'
	} read_dir( $opts{dir} );
	foreach my $sys_group (@system_groups) {
		if ( $opts{verbose} ) {
			print "Processing group $sys_group ... \n";
		}

		my @systems_in_group = grep { -f $sys_group . '/' . $_ && $_ =~ /\.sh$/ && $_ !~ /^\_/ } read_dir($sys_group);
		chdir($sys_group);
		foreach my $system (@systems_in_group) {
			my $cmdb_host = $system;
			$cmdb_host =~ s/\.sh$//;

			if ( $opts{verbose} ) {
				print $cmdb_host. "\n";
			}
			my $command
				= 'shell_var_reader -r '
				. shell_quote($system)
				. ' --tcmdb ../cmdb/ -s -p --cmdb_host '
				. shell_quote($cmdb_host) . ' '
				. $munger_option
				. ' -o json > ../json_confs/'
				. shell_quote($cmdb_host) . '.json';
			print `$command`;

			$command
				= 'shell_var_reader -r '
				. shell_quote($system)
				. ' --tcmdb ../cmdb/ -s -p --cmdb_host '
				. shell_quote($cmdb_host) . ' '
				. $munger_option
				. ' -o yaml > ../yaml_confs/'
				. shell_quote($cmdb_host) . '.yaml';
			print `$command`;

			$command
				= 'shell_var_reader -r '
				. shell_quote($system)
				. ' --tcmdb ../cmdb/ -s -p --cmdb_host '
				. shell_quote($cmdb_host) . ' '
				. $munger_option
				. ' -o toml > ../toml_confs/'
				. shell_quote($cmdb_host) . '.toml';
			print `$command`;

			$command
				= 'shell_var_reader -r '
				. shell_quote($system)
				. ' --tcmdb ../cmdb/ -s -p --cmdb_host '
				. shell_quote($cmdb_host) . ' '
				. $munger_option
				. ' -o shell > ../shell_confs/'
				. shell_quote($cmdb_host) . '.sh';
			print `$command`;
		} ## end foreach my $system (@systems_in_group)
		if ( $opts{verbose} ) {
			print "\n\n";
		}
		chdir('..');
	} ## end foreach my $sys_group (@system_groups)
} ## end sub update

=head1 LAYOUT & WORKFLOW

Specifically named files.

    - .shell_var_reader :: Marks the base directory as being for a shell_var_reader CMDB.

Specifically named directories.

    - cmdb :: The TOML CMDB directory.
    - json_confs :: Generated JSON confs.
    - shell_confs :: Generated shell confs.
    - toml_confs :: Generated TOML confs.
    - yaml_confs :: Generated YAML confs.

Other directories that that don't start with a '.' or contiain a file named '.not_a_system_group'
will be processed as system groups.

These directories will be searched for files directly below them for files ending in '.sh' and not
starting with either a '_' or a '.'. The name used for a system is the name of the file minus the ending
'.sh', so 'foo.bar.sh' would generate a config for a system named 'foo.bar'.

When it finds a file to use as a system config, it will point shell_var_reader at it with TOML CMDB enabled
and with the name of that system set the hostname to use with the TOML CMDB. That name will also be saved as
the variable 'SYSTEM_NAME', provided that variable is not defined already. If a 'munger.pl' exists, that file
is used as the munger file. shell_var_reader will be ran four times, once to generate each config type.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shell-var-reader at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shell-Var-Reader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Shell::Var::Reader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Shell-Var-Reader>

=item * Search CPAN

L<https://metacpan.org/release/Shell-Var-Reader>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Shell::Var::Reader
