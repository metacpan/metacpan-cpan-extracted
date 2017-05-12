#
# This file is part of POE-Component-SimpleDBI
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::SimpleDBI::SubProcess;
$POE::Component::SimpleDBI::SubProcess::VERSION = '1.31';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Backend of POE::Component::SimpleDBI

# Use Error.pm's try/catch semantics
use Error 0.15 qw( :try );

# We pass in data to POE::Filter::Reference
use POE::Filter::Reference;

# We run the actual DB connection here
use DBI 1.30;

# Our Filter object
my $filter = POE::Filter::Reference->new();

# Our DBI handle
my $DB;

# Save the connect struct for future use
my $CONN;

# Sysread error hits
my $sysreaderr = 0;

# Shut up Perl::Critic!
## no critic ( ProhibitAccessOfPrivateData )

# This is the subroutine that will get executed upon the fork() call by our parent
sub main {
	# Autoflush to avoid weirdness
	$|++;

	# set binmode, thanks RT #43442
	binmode( STDIN );
	binmode( STDOUT );

	# Okay, now we listen for commands from our parent :)
	while ( sysread( STDIN, my $buffer = '', 1024 ) ) {
		# Feed the line into the filter
		my $data = $filter->get( [ $buffer ] );

		# INPUT STRUCTURE IS:
		# $d->{'ACTION'}	= SCALAR	->	WHAT WE SHOULD DO
		# $d->{'SQL'}		= SCALAR	->	THE ACTUAL SQL
		# $d->{'SQL'}		= ARRAY		->	THE ACTUAL SQL ( in case of ATOMIC )
		# $d->{'PLACEHOLDERS'}	= ARRAY		->	PLACEHOLDERS WE WILL USE
		# $d->{'PREPARE_CACHED'}= BOOLEAN	->	USE CACHED QUERIES?
		# $d->{'ID'}		= SCALAR	->	THE QUERY ID ( FOR PARENT TO KEEP TRACK OF WHAT IS WHAT )

		# $d->{'DSN'}		= SCALAR	->	DSN for CONNECT
		# $d->{'USERNAME'}	= SCALAR	->	USERNAME for CONNECT
		# $d->{'PASSWORD'}	= SCALAR	->	PASSWORD for CONNECT

		# Process each data structure
		foreach my $input ( @$data ) {
			output( process_request( $input ) );
			return if $input->{'ACTION'} eq 'EXIT';
		}
	}

	# Arrived here due to error in sysread/etc
	output( Make_Error( 'SYSREAD', $! ) );

	# If we got more than 5 sysread errors, abort!
	if ( ++$sysreaderr == 5 ) {
		if ( defined $DB ) { $DB->disconnect() }
		return;
	} else {
		goto &main;
	}

	return;
}

sub process_request {
	my $input = shift;

	# Now, we do the actual work depending on what kind of query it was
	if ( $input->{'ACTION'} eq 'CONNECT' ) {
		# Connect!
		return (DB_CONNECT($input, 0))[1];
	} elsif ( $input->{'ACTION'} eq 'DISCONNECT' ) {
		# Disconnect!
		return DB_DISCONNECT( $input );
	} elsif ( $input->{'ACTION'} eq 'DO' ) {
		# Fire off the SQL and return success/failure + rows affected
		return DB_DO( $input );
	} elsif ( $input->{'ACTION'} eq 'SINGLE' ) {
		# Return a single result
		return DB_SINGLE( $input );
	} elsif ( $input->{'ACTION'} eq 'MULTIPLE' ) {
		# Get many results, then return them all at the same time
		return DB_MULTIPLE( $input );
	} elsif ( $input->{'ACTION'} eq 'QUOTE' ) {
		return DB_QUOTE( $input );
	} elsif ( $input->{'ACTION'} eq 'ATOMIC' ) {
		return DB_ATOMIC( $input );
	} elsif ( $input->{'ACTION'} eq 'EXIT' ) {
		# Cleanly disconnect from the DB
		if ( defined $DB ) {
			$DB->disconnect();
			undef $DB;
		}

		# EXIT!
		return;
	}

	# Unrecognized action!
	return( Make_Error( $input->{'ID'}, 'Unknown action sent from parent' ) );
}

# Connects to the DB
sub DB_CONNECT {
	# Get the input structure
	my $data = shift;

	# Are we reconnecting?
	my $reconn = shift;

	# Our output structure
	my $output;

	# Are we already connected?
	if ( defined $DB and $DB->ping() ) {
		# Output success
		$output = {
			'ID'	=>	$data->{'ID'},
		};
	} else {
		# Actually make the connection :)
		try {
			$DB = DBI->connect(
				# The DSN we just set up
				$data->{'DSN'},

				# Username
				$data->{'USERNAME'},

				# Password
				$data->{'PASSWORD'},

				# We set some configuration stuff here
				{
					# We do not want users seeing 'spam' on the commandline...
					'PrintError'	=>	0,
					'PrintWarn'	=>	0,

					# Automatically raise errors so we can catch them with try/catch
					'RaiseError'	=>	1,

					# Disable the DBI tracing
					'TraceLevel'	=>	0,

					# AutoCommit our stuff?
					'AutoCommit'	=>	$data->{'AUTO_COMMIT'},
				}
			);

			# Check for undefined-ness
			if ( ! defined $DB ) {
				die "Error Connecting: $DBI::errstr";
			} else {
				# Did we request a custom cache module?
				if ( defined $data->{'CACHEDKIDS'} ) {
					eval "require $data->{'CACHEDKIDS'}->[0]";
					die "Unable to load custom caching module: $@" if $@;

					# code lifted from DBI's POD, thanks!
					my $cache;
					tie %$cache, @{ $data->{'CACHEDKIDS'} };
					$DB->{'CachedKids'} = $cache;
				}

				# Output success
				$output = {
					'ID'	=>	$data->{'ID'},
				};

				# Save this!
				$CONN = $data;
			}
		} catch Error with {
			# Get the error
			my $e = shift;

			# Declare it!
			$output = Make_Error( $data->{'ID'}, $e );
		};
	}

	# All done!
	if ( ! defined $reconn ) {
		return (1, $output);
	} else {
		# Reconnect attempt, was it successful?
		if ( ! exists $output->{'ERROR'} ) {
			return (1, $output);
		}
	}

	return (0, $output);
}

# Disconnects from the DB
sub DB_DISCONNECT {
	# Get the input structure
	my $data = shift;

	# Our output structure
	my $output;

	# Are we already disconnected?
	if ( ! defined $DB ) {
		# Output success
		$output = {
			'ID'	=>	$data->{'ID'},
		};
	} else {
		# Disconnect from the DB
		try {
			$DB->disconnect();
			undef $DB;

			# Output success
			$output = {
				'ID'	=>	$data->{'ID'},
			};
		} catch Error with {
			# Get the error
			my $e = shift;

			# Declare it!
			$output = Make_Error( $data->{'ID'}, $e );
		};
	}

	# All done!
	return $output;
}

# This subroutine does a DB QUOTE
sub DB_QUOTE {
	# Get the input structure
	my $data = shift;

	# The result
	my( $quoted, $output );

	# Check if we are connected
	if ( ! defined $DB or ! $DB->ping() ) {
		# Automatically try to reconnect
		if ( ! ( DB_CONNECT( $CONN, 'RECONNECT' ) )[0] ) {
			return Make_Error( 'GONE', 'Lost connection to the database server.' );
		}
	}

	# Quote it!
	try {
		$quoted = $DB->quote( $data->{'SQL'} );
	} catch Error with {
		# Get the error
		my $e = shift;

		$output = Make_Error( $data->{'ID'}, $e );
	};

	# Check for errors
	if ( ! defined $output ) {
		# Make output include the results
		$output = {};
		$output->{'DATA'} = $quoted;
		$output->{'ID'} = $data->{'ID'};
	}

	# All done!
	return $output;
}

# This subroutine runs a 'SELECT' style query on the db
sub DB_MULTIPLE {
	# Get the input structure
	my $data = shift;

	# Variables we use
	my( $output, $sth );
	my $result = [];

	# Check if we are connected
	if ( ! defined $DB or ! $DB->ping() ) {
		# Automatically try to reconnect
		if ( ! ( DB_CONNECT( $CONN, 'RECONNECT' ) )[0] ) {
			return( Make_Error( 'GONE', 'Lost connection to the database server.' ) );
		}
	}

	# Catch any errors :)
	try {
		# Make a new statement handler and prepare the query
		if ( $data->{'PREPARE_CACHED'} ) {
			$sth = $DB->prepare_cached( $data->{'SQL'} );
		} else {
			$sth = $DB->prepare( $data->{'SQL'} );
		}

		# Check for undef'ness
		if ( ! defined $sth ) {
			die "Did not get sth: $DBI::errstr";
		} else {
			# Execute the query
			try {
				# Put placeholders?
				if ( exists $data->{'PLACEHOLDERS'} and defined $data->{'PLACEHOLDERS'} ) {
					$sth->execute( @{ $data->{'PLACEHOLDERS'} } );
				} else {
					$sth->execute();
				}
			} catch Error with {
				die $sth->errstr if $sth->errstr;
				die "NON DBI ERROR : $@";
			};
		}

		# The result hash
		my $newdata;

		# Bind the columns
		try {
			$sth->bind_columns( \( @$newdata{ @{ $sth->{'NAME_lc'} } } ) );
		} catch Error with {
			die $sth->errstr if $sth->errstr;
			die "NON DBI ERROR : $@";
		};

		# Actually do the query!
		try {
			while ( $sth->fetch() ) {
				# Copy the data, and push it into the array
				push( @{ $result }, { %{ $newdata } } );
			}
		} catch Error with {
			die $sth->errstr if $sth->errstr;
			die "NON DBI ERROR : $@";
		};

		# Check for any errors that might have terminated the loop early
		if ( $sth->err() ) {
			# Premature termination!
			die $sth->errstr;
		}
	} catch Error with {
		# Get the error
		my $e = shift;

		$output = Make_Error( $data->{'ID'}, $e );
	};

	# Check if we got any errors
	if ( ! defined $output ) {
		# Make output include the results
		$output = {};
		$output->{'DATA'} = $result;
		$output->{'ID'} = $data->{'ID'};
	}

	# Finally, we clean up this statement handle
	if ( defined $sth ) {
		$sth->finish();

		# Make sure the object is gone, thanks Sjors!
		undef $sth;
	}

	# Return the data structure
	return $output;
}

# This subroutine runs a 'SELECT ... LIMIT 1' style query on the db
sub DB_SINGLE {
	# Get the input structure
	my $data = shift;

	# Variables we use
	my( $output, $sth, $result );

	# Check if we are connected
	if ( ! defined $DB or ! $DB->ping() ) {
		# Automatically try to reconnect
		if ( ! ( DB_CONNECT( $CONN, 'RECONNECT' ) )[0] ) {
			return Make_Error( 'GONE', 'Lost connection to the database server.' );
		}
	}

	# Catch any errors :)
	try {
		# Make a new statement handler and prepare the query
		if ( $data->{'PREPARE_CACHED'} ) {
			$sth = $DB->prepare_cached( $data->{'SQL'} );
		} else {
			$sth = $DB->prepare( $data->{'SQL'} );
		}

		# Check for undef'ness
		if ( ! defined $sth ) {
			die "Did not get sth: $DBI::errstr";
		} else {
			# Execute the query
			try {
				# Put placeholders?
				if ( exists $data->{'PLACEHOLDERS'} and defined $data->{'PLACEHOLDERS'} ) {
					$sth->execute( @{ $data->{'PLACEHOLDERS'} } );
				} else {
					$sth->execute();
				}
			} catch Error with {
				die $sth->errstr if $sth->errstr;
				die "NON DBI ERROR : $@";
			};
		}

		# Actually do the query!
		try {
			$result = $sth->fetchrow_hashref();
		} catch Error with {
			die $sth->errstr if $sth->errstr;
			die "NON DBI ERROR : $@";
		};
	} catch Error with {
		# Get the error
		my $e = shift;

		$output = Make_Error( $data->{'ID'}, $e );
	};

	# Check if we got any errors
	if ( ! defined $output ) {
		# Make output include the results
		$output = {};
		$output->{'DATA'} = $result;
		$output->{'ID'} = $data->{'ID'};
	}

	# Finally, we clean up this statement handle
	if ( defined $sth ) {
		$sth->finish();

		# Make sure the object is gone, thanks Sjors!
		undef $sth;
	}

	# Return the data structure
	return $output;
}

# This subroutine runs a 'DO' style query on the db
sub DB_DO {
	# Get the input structure
	my $data = shift;

	# Variables we use
	my( $output, $sth, $rows_affected, $last_id );

	# Check if we are connected
	if ( ! defined $DB or ! $DB->ping() ) {
		# Automatically try to reconnect
		if ( ! ( DB_CONNECT( $CONN, 'RECONNECT' ) )[0] ) {
			return Make_Error( 'GONE', 'Lost connection to the database server.' );
		}
	}

	# Catch any errors :)
	try {
		# Make a new statement handler and prepare the query
		if ( $data->{'PREPARE_CACHED'} ) {
			$sth = $DB->prepare_cached( $data->{'SQL'} );
		} else {
			$sth = $DB->prepare( $data->{'SQL'} );
		}

		# Check for undef'ness
		if ( ! defined $sth ) {
			die "Did not get sth: $DBI::errstr";
		} else {
			# Execute the query
			try {
				# Put placeholders?
				if ( exists $data->{'PLACEHOLDERS'} and defined $data->{'PLACEHOLDERS'} ) {
					$rows_affected = $sth->execute( @{ $data->{'PLACEHOLDERS'} } );
				} else {
					$rows_affected = $sth->execute();
				}

				# Should we even attempt this?
				if ( $data->{'INSERT_ID'} ) {
					try {
						# Get the last insert id ( make this portable! )
						$last_id = $DB->last_insert_id( undef, undef, undef, undef );
					} catch Error with {
						# Ignore this error!
					};
				}
			} catch Error with {
				# If something other than DBI fails, errstr won't be set.
				# You can get this if, for example, we need a module that hasn't been loaded.
				die $sth->errstr if $sth->errstr;
				die "NON DBI ERROR : $@";
			};
		}
	} catch Error with {
		# Get the error
		my $e = shift;

		$output = Make_Error( $data->{'ID'}, $e );
	};

	# If rows_affected is not undef, that means we were successful
	if ( defined $rows_affected && ! defined $output ) {
		# Make the data structure
		$output = {};
		$output->{'DATA'} = $rows_affected;
		$output->{'ID'} = $data->{'ID'};
		$output->{'INSERTID'} = $last_id;
	} elsif ( ! defined $rows_affected && ! defined $output ) {
		# Internal error...
		die 'Internal Error in DB_DO';
	}

	# Finally, we clean up this statement handle
	if ( defined $sth ) {
		$sth->finish();

		# Make sure the object is gone, thanks Sjors!
		undef $sth;
	}

	# Return the data structure
	return $output;
}

# This subroutine runs a 'DO' style query on the db in a transaction
sub DB_ATOMIC {
	# Get the input structure
	my $data = shift;

	# Variables we use
	my( $output, $sth );

	# Check if we are connected
	if ( ! defined $DB or ! $DB->ping() ) {
		# Automatically try to reconnect
		if ( ! ( DB_CONNECT( $CONN, 'RECONNECT' ) )[0] ) {
			return Make_Error( 'GONE', 'Lost connection to the database server.' );
		}
	}

	# Catch any errors :)
	try {
		# start the transaction
		$DB->begin_work if $DB->{'AutoCommit'};

		# process each query
		for my $idx ( 0 .. $#{ $data->{'SQL'} } ) {
			if ( $data->{'PREPARE_CACHED'} ) {
				$sth = $DB->prepare_cached( $data->{'SQL'}->[ $idx ] );
			} else {
				$sth = $DB->prepare( $data->{'SQL'}->[ $idx ] );
			}

			# Check for undef'ness
			if ( ! defined $sth ) {
				die "Did not get sth: $DBI::errstr";
			} else {
				# actually execute it!
				try {
					if ( exists $data->{'PLACEHOLDERS'} and defined $data->{'PLACEHOLDERS'} and defined $data->{'PLACEHOLDERS'}->[ $idx ] ) {
						$sth->execute( @{ $data->{'PLACEHOLDERS'}->[ $idx ] } );
					} else {
						$sth->execute;
					}
				} catch Error with {
					die $sth->errstr;
				};

				# Finally, we clean up this statement handle
				$sth->finish();

				# Make sure the object is gone, thanks Sjors!
				undef $sth;
			}
		}

		# done with transaction!
		$DB->commit;
	} catch Error with {
		# Get the error
		my $e = shift;

		# rollback the changes!
		try {
			$DB->rollback;
		} catch Error with {
			# Get the error
			my $error = shift;

			$output = Make_Error( $data->{'ID'}, 'ROLLBACK_FAILURE: ' . $error . ' on query error: ' . $e );
		};

		# did we rollback fine?
		if ( ! defined $output ) {
			$output = Make_Error( $data->{'ID'}, 'COMMIT_FAILURE: ' . $e );
		}
	};

	# Finally, we clean up this statement handle
	if ( defined $sth ) {
		$sth->finish();

		# Make sure the object is gone, thanks Sjors!
		undef $sth;
	}

	# If we got no output, we did it!
	if ( ! defined $output ) {
		# Make the data structure
		$output = {};
		$output->{'DATA'} = 'SUCCESS';
		$output->{'ID'} = $data->{'ID'};
	}

	# Return the data structure
	return $output;
}

# This subroutine makes a generic error structure
sub Make_Error {
	# Make the structure
	my $data = {};
	$data->{'ID'} = shift;

	# Get the error, and stringify it in case of Error::Simple objects
	my $error = shift;

	if ( ref $error and ref( $error ) eq 'Error::Simple' ) {
		$data->{'ERROR'} = $error->text;
	} else {
		$data->{'ERROR'} = $error;
	}

	# All done!
	return $data;
}

# This subroutine makes a generic DEBUG structure
sub Make_DEBUG {
	# Make the structure
	my $data = {};
	$data->{'ID'} = 'DEBUG';

	# Get the data, and shove it in the hash
	my @debug = @_;
	$data->{'RESULT'} = \@debug;

	# All done!
	return $data;
}

# Prints any output to STDOUT
sub output {
	# Get the data
	my $data = shift;

	# Freeze it!
	my $output = $filter->put( [ $data ] );

	# Print it!
	print STDOUT @$output;
	return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse DBI

=for Pod::Coverage *EVERYTHING*

=head1 NAME

POE::Component::SimpleDBI::SubProcess - Backend of POE::Component::SimpleDBI

=head1 VERSION

  This document describes v1.31 of POE::Component::SimpleDBI::SubProcess - released November 05, 2014 as part of POE-Component-SimpleDBI.

=head1 DESCRIPTION

This module is responsible for implementing the guts of POE::Component::SimpleDBI.
Namely, the fork/exec and the connection to the DBI.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::SimpleDBI|POE::Component::SimpleDBI>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
