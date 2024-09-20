package Shell::Var::Reader::CMDB;

use 5.006;
use strict;
use warnings;
use File::Slurp qw(read_dir write_file read_dir);
use File::Copy;
use String::ShellQuote;

=head1 NAME

Shell::Var::Reader::CMDB - Helper for updating shell_var_reader based CMDBs.

=head1 VERSION

Version 0.5.0

=cut

our $VERSION = '0.5.0';

=head1 SUBROUTINES

=head2 update

Reads through the directory and process all relevant files.

    Shell::Var::Reader::CMDB->update(
                                   dir=>'./foo/',
                                   verbose=>1,
                                   );

The following options are available.

    - dir :: Path to where to create it.
        - Default :: undef.

    - verbose :: If it should be verbose or not.
        - Default :: 1

    - to_process :: An optional array of groups or systems
            to process by path.
        - Default :: undef

If dir undef, it will check the following
directories for the file '.shell_var_reader'.

  ./
  ../
  ../../
  ../../../
  ../../../../

When using to_process, group and systems should not be mixed
as it will result in groups being ignored as systems is more
restrictive.

Lets assume we have the following...

    ./group_a/foo.sh
    ./group_a/bar.sh
    ./group_b/nas.sh

So if we have to_process set to ['group_a'] the following
would be processed...

    ./group_a/foo.sh
    ./group_a/bar.sh

So if we have to_process set to ['group_a/bar.sh'] the following
would be processed...

    ./group_a/bar.sh

So if we have to_process set to ['group_a/bar.sh', 'group_b'] the following
would be processed...

    ./group_a/bar.sh

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
		if ( -f './.shell_var_reader' ) {
			$opts{dir} = './';
		} elsif ( -f '../.shell_var_reader' ) {
			$opts{dir} = '../';
		} elsif ( -f '../../.shell_var_reader' ) {
			$opts{dir} = '../../';
		} elsif ( -f '../../../.shell_var_reader' ) {
			$opts{dir} = '../../../';
		} elsif ( -f '../../../../.shell_var_reader' ) {
			$opts{dir} = '../../../../';
		}
	} else {
		if ( !-d $opts{dir} ) {
			die( '"' . $opts{dir} . '" does not exist or is not a directory' );
		}
	}

	chdir( $opts{dir} );
	$opts{dir} = './';

	my $has_specified_groups  = 0;
	my $has_specified_systems = 0;
	my %specified_groups;
	my %specified_systems;
	if (   defined( $opts{to_process} )
		&& ref( $opts{to_process} ) eq 'ARRAY'
		&& defined( $opts{to_process}[0] )
		&& ( ref( $opts{to_process}[0] ) eq '' || ref( $opts{to_process}[0] ) eq 'SCALAR' ) )
	{
		foreach my $item ( @{ $opts{to_process} } ) {
			$item =~ s/^\.\/+//;
			$item =~ s/\/+$//;
			if ( -d $item ) {
				$specified_groups{$item} = 1;
				$has_specified_groups = 1;
			} elsif ( $item =~ /^[a-zA-Z0-9\.\_\-]+\/+[a-zA-Z0-9\.\_\-]+\.sh$/ ) {
				my $group = $item;
				$group =~ s/\/+.*$//;
				$specified_groups{$group} = 1;

				my $system = $item;
				$system =~ s/^.*\/+//;
				$system =~ s/\.sh$//;
				$specified_systems{$system} = 1;

				$has_specified_groups  = 1;
				$has_specified_systems = 1;
			} ## end elsif ( $item =~ /^[a-zA-Z0-9\.\_\-]+\/+[a-zA-Z0-9\.\_\-]+\.sh$/)
		} ## end foreach my $item ( @{ $opts{to_process} } )
	} ## end if ( defined( $opts{to_process} ) && ref( ...))

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

	#
	my $no_toml='';
	if ( -f $opts{dir} . '/.no_toml' ) {
		$no_toml = '--no_toml';
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
	foreach my $sys_group ( sort(@system_groups) ) {
		my $process_group = 1;
		if ( $has_specified_groups && !$specified_groups{$sys_group} ) {
			$process_group = 0;
		}

		if ($process_group) {
			if ( $opts{verbose} ) {
				print "Processing group $sys_group ... \n";
			}

			my @systems_in_group
				= grep { -f $sys_group . '/' . $_ && $_ =~ /\.sh$/ && $_ !~ /^\_/ } read_dir($sys_group);
			chdir($sys_group);
			foreach my $system ( sort(@systems_in_group) ) {
				my $cmdb_host = $system;
				$cmdb_host =~ s/\.sh$//;

				my $process_system = 1;
				if ( $has_specified_systems && !$specified_systems{$cmdb_host} ) {
					$process_system = 0;
				}

				if ($process_system) {
					if ( $opts{verbose} ) {
						print $cmdb_host. "\n";
					}
					my $command
						= 'shell_var_reader -r '
						. shell_quote($system)
						. ' --tcmdb ../cmdb/ -s -p --cmdb_host '
						. shell_quote($cmdb_host) . ' '
						. $no_toml . ' '
						. $munger_option
						. ' -o multi -d ../';
					print `$command`;

				} else {
					if ( $opts{verbose} ) {
						print 'skipping ' . $cmdb_host . "\n";
					}
				}
			} ## end foreach my $system ( sort(@systems_in_group) )
			if ( $opts{verbose} ) {
				print "\n\n";
			}
			chdir('..');
		} else {
			if ( $opts{verbose} ) {
				print "Skipping group $sys_group ... \n\n\n";
			}
		}
	} ## end foreach my $sys_group ( sort(@system_groups) )
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

TOML will be skipped if .no_toml exists in the base directory.

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
