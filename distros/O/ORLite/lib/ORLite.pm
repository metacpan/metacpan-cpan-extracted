package ORLite;

# See POD at end of file for documentation

use 5.006;
use strict;
use Carp              ();
use File::Spec   0.80 ();
use File::Path   2.08 ();
use File::Basename    ();
use Params::Util 1.00 ();
use DBI         1.607 ();
use DBD::SQLite  1.27 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.98';
}

# Support for the 'prune' option
my @PRUNE = ();
END {
	foreach ( reverse @PRUNE ) {
		next unless -e $_;
		require File::Remove;
		File::Remove::remove( \1, $_ );
	}
}





#####################################################################
# Code Generation

sub import {
	my $class = ref($_[0]) || $_[0];

	# Check for debug mode
	my $DEBUG = 0;
	if ( defined Params::Util::_STRING($_[-1]) and $_[-1] eq '-DEBUG' ) {
		$DEBUG = 1;
		pop @_;
	}

	# Check params and apply defaults
	my %params = (
		# Simple defaults here, complex defaults later
		package    => scalar(caller),
		create     => 0,
		cleanup    => '',
		array      => 0,
		xsaccessor => 0,
		shim       => 0,
		tables     => 1,
		views      => 0,
		unicode    => 0,
	);
	if ( defined Params::Util::_STRING($_[1]) ) {
		# Support the short form "use ORLite 'db.sqlite'"
		$params{file} = $_[1];
	} elsif ( Params::Util::_HASHLIKE($_[1]) ) {
		%params = ( %params, %{$_[1]} );
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}
	unless (
		defined Params::Util::_STRING($params{file})
		and (
			$params{create}
			or
			-f $params{file}
		)
	) {
		Carp::croak("Missing or invalid file param");
	}
	unless ( defined $params{readonly} ) {
		$params{readonly} = $params{create} ? 0 : ! -w $params{file};
	}
	unless ( Params::Util::_CLASS($params{package}) ) {
		Carp::croak("Missing or invalid package class");
	}

	# Check caching params
	my $cached = undef;
	my $pkg    = $params{package};
	if ( defined $params{cache} ) {
		# Caching is illogical or invalid in some situations
		if ( $params{prune} ) {
			Carp::croak("Cannot set a 'cache' directory while 'prune' enabled");
		}
		unless ( $params{user_version} ) {
			Carp::croak("Cannot set a 'cache' directory without 'user_version'");
		}

		# To make the caching work, the version be defined before ORLite is called.
		no strict 'refs';
		unless ( ${"$pkg\::VERSION"} ) {
			Carp::croak("Cannot set a 'cache' directory without a package \$VERSION");
		}

		# Build the cache file from the super path using an inlined Class::ISA
		my @queue = ( $class );
		my %seen  = ( $pkg => 1 );
		my @parts = ( $pkg => ${"$pkg\::VERSION"} );
		while ( @queue ) {
			my $c = Params::Util::_STRING(shift @queue) or next;
			push @parts, $c => ${"$c\::VERSION"};
			unshift @queue, grep { not $seen{$c}++ } @{"$c\::ISA"};
		}
		$cached = join '-', @parts, user_version => $params{user_version};
		$cached =~ s/[:.-]+/-/g;
		$cached = File::Spec->rel2abs(
			File::Spec->catfile( $params{cache}, "$cached.pm" )
		);
	}

	# Create the parent directory if needed
	my $file    = File::Spec->rel2abs($params{file});
	my $created = ! -f $params{file};
	if ( $created ) {
		my $dir = File::Basename::dirname($file);
		unless ( -d $dir ) {
			my @dirs = File::Path::mkpath( $dir, { verbose => 0 } );
			$class->prune(@dirs) if $params{prune};
		}
		$class->prune($file) if $params{prune};
	}

	# Connect to the database
	my $dsn = "dbi:SQLite:$file";
	my $dbh = DBI->connect( $dsn, undef, undef, {
		PrintError => 0,
		RaiseError => 1,
		ReadOnly   => $params{create} ? 0 : 1,
		$params{unicode} ? ( sqlite_unicode => 1 ) : ( ),
	} );

	# Schema custom creation support
	if ( $created and Params::Util::_CODELIKE($params{create}) ) {
		$params{create}->($dbh);
	}

	# Check the schema version before generating
	my $user_version = $dbh->selectrow_arrayref('pragma user_version')->[0];
	if ( exists $params{user_version} and $user_version != $params{user_version} ) {
		Carp::croak("Schema user_version mismatch (got $user_version, wanted $params{user_version})");
	}

	# If caching and the cached version exists, load and shortcut.
	# Don't try to catch exceptions, just let them blow up.
	if ( $cached and -f $cached ) {
		$dbh->disconnect;
		require $cached;
		return 1;
	}

	# Prepare to generate code
	my $cleanup    = $params{cleanup};
	my $readonly   = $params{readonly} ? "\n\t\tReadOnly => 1," : '';
	my $unicode    = $params{unicode} ? "\n\t\tsqlite_unicode => 1," : '';
	my $version    = $unicode ? '5.008005' : '5.006';

	# Generate the support package code
	my $code = <<"END_PERL";
package $pkg;

use $version;
use strict;
use Carp              ();
use DBI         1.607 ();
use DBD::SQLite  1.27 ();

my \$DBH = undef;

sub orlite { '$VERSION' }

sub sqlite { '$file' }

sub dsn { '$dsn' }

sub dbh {
	\$DBH or \$_[0]->connect;
}

sub connect {
	DBI->connect( \$_[0]->dsn, undef, undef, {
		PrintError => 0,
		RaiseError => 1,$readonly$unicode
	} );
}

sub connected {
	defined \$DBH;
}

sub prepare {
	shift->dbh->prepare(\@_);
}

sub do {
	shift->dbh->do(\@_);
}

sub selectall_arrayref {
	shift->dbh->selectall_arrayref(\@_);
}

sub selectall_hashref {
	shift->dbh->selectall_hashref(\@_);
}

sub selectcol_arrayref {
	shift->dbh->selectcol_arrayref(\@_);
}

sub selectrow_array {
	shift->dbh->selectrow_array(\@_);
}

sub selectrow_arrayref {
	shift->dbh->selectrow_arrayref(\@_);
}

sub selectrow_hashref {
	shift->dbh->selectrow_hashref(\@_);
}

sub pragma {
	\$_[0]->do("pragma \$_[1] = \$_[2]") if \@_ > 2;
	\$_[0]->selectrow_arrayref("pragma \$_[1]")->[0] if defined wantarray;
}

sub iterate {
	my \$class = shift;
	my \$call  = pop;
	my \$sth   = \$class->prepare(shift);
	\$sth->execute(\@_);
	while ( \$_ = \$sth->fetchrow_arrayref ) {
		\$call->() or return 1;;
	}
}

sub begin {
	\$DBH or
	\$DBH = \$_[0]->connect;
	\$DBH->begin_work;
}

sub rollback {
	\$DBH or return 1;
	\$DBH->rollback;
	\$DBH->disconnect;
	undef \$DBH;
	return 1;
}

sub rollback_begin {
	if ( \$DBH ) {
		\$DBH->rollback;
		\$DBH->begin_work;
	} else {
		\$_[0]->begin;
	}
	return 1;
}

END_PERL

	# If you are a read-write database, we even allow you
	# to commit your transactions.
	$code .= <<"END_PERL" unless $readonly;
sub commit {
	\$DBH or return 1;
	\$DBH->commit;
	\$DBH->disconnect;
	undef \$DBH;
	return 1;
}

sub commit_begin {
	if ( \$DBH ) {
		\$DBH->commit;
		\$DBH->begin_work;
	} else {
		\$_[0]->begin;
	}
	return 1;
}

END_PERL

	# Cleanup and shutdown operations
	if ( $cleanup ) {
		$code .= <<"END_PERL";
END {
	if ( \$DBH ) {
		\$DBH->rollback;
		\$DBH->do('$cleanup');
		\$DBH->disconnect;
		undef \$DBH;
	} else {
		$pkg->do('$cleanup');
	}
}

END_PERL
	} else {
		$code .= <<"END_PERL";
END {
	$pkg->rollback if \$DBH;
}

END_PERL
	}

	# Optionally generate the table classes
	my $tables = undef;
	if ( $params{tables} ) {
		# Capture the raw schema table information
		$tables = $dbh->selectall_arrayref(
			'select * from sqlite_master where name not like ? and type in ( ?, ? )',
			{ Slice => {} }, 'sqlite_%', 'table', 'view',
		);

		# Capture the raw schema information and do first-pass work
		foreach my $t ( @$tables ) {
			# Convenience pre-quoted form of the table name
			$t->{qname} = $dbh->quote_identifier(undef, undef, $t->{name});

			# What will be the class for this table
			$t->{class} = $t->{name};
			if ( $t->{class} ne lc $t->{class} ) {
				$t->{class} =~ s/([a-z])([A-Z])/${1}_${2}/g;
				$t->{class} =~ s/_+/_/g;
			}
			$t->{class} = ucfirst lc $t->{class};
			$t->{class} =~ s/_([a-z])/uc($1)/ge;
			$t->{class} = "${pkg}::$t->{class}";

			# Load the structural column list
			my $columns = $t->{columns} = $dbh->selectall_arrayref(
				"pragma table_info('$t->{name}')",
			 	{ Slice => {} },
			);

			# The list of columns we will select, which can
			# be different to the general list.
			my $select = $t->{select} = [ @$columns ];

			# Track array vs hash implementation on a per-table
			# basis so that we can force views to always be done
			# array-wise (to compensate for some weird SQLite
			# column quoting differences between tables and views
			$t->{array} = $params{array};
			if ( $t->{type} eq 'view' ) {
				$t->{array} = 1;
			}

			# Track usage of rowid on a per-table basis because
			# views don't always support rowid.
			$t->{rowid} = $t->{type} eq 'table';

			foreach my $c ( @$select ) {
				# Convenience escaping for the column names
				$c->{qname} = $dbh->quote_identifier($c->{name});

				# Affinity detection
				if ( $c->{type} =~ /INT/i ) {
					$c->{affinity} = 'INTEGER';
				} elsif ( $c->{type} =~ /(?:CHAR|CLOB|TEXT)/i ) {
					$c->{affinity} = 'TEXT';
				} elsif ( $c->{type} =~ /BLOB/i or not $c->{type} ) {
					$c->{affinity} = 'BLOB';

					# Unicode currently breaks BLOB columns
					if ( $unicode ) {
						die "BLOB column $t->{name}.$c->{name} is not supported in unicode database";
					}
				} elsif ( $c->{type} =~ /(?:REAL|FLOA|DOUB)/i ) {
					$c->{affinity} = 'REAL';
				} else {
					$c->{affinity} = 'NUMERIC';
				}
			}

			# Analyze the primary keys structure
			$t->{pk}  = [ grep { $_->{pk} } @$columns ];
			$t->{pkn} = scalar @{$t->{pk}};
			if ( $t->{pkn} == 1 ) {
				$t->{pk1} = $t->{pk}->[0];
				if ( $t->{pk1}->{affinity} eq 'INTEGER' ) {
					$t->{pki} = $t->{pk1};
				}
			}
			if ( $t->{pki} ) {
				$t->{rowid} &&= $t->{pki};
				if ( $t->{pki}->{name} eq $t->{name} . '_id' ) {
					$t->{id} = $t->{pki};
				}

			} elsif ( $t->{rowid} ) {
				# Add rowid to the query
				$t->{rowid} = {
					cid        => -1,
					name       => 'rowid',
					qname      => '"rowid"',
					type       => 'integer',
					affinity   => 'INTEGER',
					notnull    => 1,
					dflt_value => undef,
					pk         => 0,
				};
				push @$select, $t->{rowid};
			}

			# Do we allow object creation?
			$t->{create} = $t->{pkn};
			$t->{create} = 1 if $t->{rowid};
			$t->{create} = 0 if $readonly;

			# Generate the object keys for the columns
			if ( $t->{array} ) {
				foreach my $i ( 0 .. $#$select ) {
					$select->[$i]->{xs}  = $i;
					$select->[$i]->{key} = "[$i]";
				}
			} else {
				foreach my $c ( @$select ) {
					$c->{xs}  = "'$c->{name}'";
					$c->{key} = "{$c->{name}}";
				}
			}

			# Generate the main SQL fragments
			$t->{sql_scols}  = join ', ', map { $_->{qname} } @$select;
			$t->{sql_icols}  = join ', ', map { $_->{qname} } @$columns;
			$t->{sql_ivals}  = join ', ', ( '?' ) x scalar @$columns;
			$t->{sql_select} = "select $t->{sql_scols} from $t->{qname}";
			$t->{sql_insert} =
				"insert into $t->{qname} " .
				"( $t->{sql_icols} ) " .
				"values ( $t->{sql_ivals} )";
			$t->{sql_where} = join ' and ',
				map { "$_->{qname} = ?" } @{$t->{pk}};

			# Generate the new Perl fragments
			$t->{pl_new} = join "\n", map {
				$t->{array}
					? "\t\t\$attr{$_->{name}},"
					: "\t\t$_->{name} => \$attr{$_->{name}},"
			} @$columns;

			$t->{pl_insert} = join "\n", map {
				"\t\t\$self->$_->{key},"
			} @$columns;

			$t->{pl_fill} = '';
			if ( $t->{pki} ) {
				$t->{pl_fill} =
					"\t\$self->$t->{pki}->{key} " .
					"= \$dbh->func('last_insert_rowid') " .
					"unless \$self->$t->{pki}->{key};";
			} elsif ( $t->{rowid} ) {
				$t->{pl_fill} =
					"\t\$self->$t->{rowid}->{key} " .
					"= \$dbh->func('last_insert_rowid');";
			}
		}

		# Generate the foreign key metadata
		my %tindex = map { $_->{name} => $_ } @$tables;
		foreach my $t ( @$tables ) {
			# Locate the foreign keys
			my %fk     = ();
			my @fk_sql = $t->{sql} =~ /[(,]\s*(.+?REFERENCES.+?)\s*[,)]/g;

			# Extract the details
			foreach ( @fk_sql ) {
				unless ( /^(\w+).+?REFERENCES\s+(\w+)\s*\(\s*(\w+)/ ) {
					die "Invalid foreign key $_";
				}
				$fk{"$1"} = [ "$2", $tindex{"$2"}, "$3" ];
			}
			foreach ( @{$t->{columns}} ) {
				$_->{fk} = $fk{$_->{name}};
			}

			# One final code fragment we need the fk for
			$t->{pl_accessor} = join "\n",
				map { "\t\t$_->{name} => $_->{xs}," }
				grep { ! $_->{fk} } @{$t->{columns}};
		}

		# Generate the per-table code
		foreach my $t ( @$tables ) {
			my @select  = @{$t->{select}};
			my @columns = @{$t->{columns}};
			my $slice   = $t->{array}
				? '{}'
				: '{ Slice => {} }';

			# Generate the package header
			if ( $params{shim} ) {
				# Generate a shim-wrapper class
				$code .= <<"END_PERL";
package $t->{class};

\@$t->{class}::ISA = '$t->{class}::Shim';

package $t->{class}::Shim;

END_PERL
			} else {
				# Plain vanilla package header
				$code .= <<"END_PERL";
package $t->{class};

END_PERL
			}

			# Generate the common elements for all classes
			$code .= <<"END_PERL";
sub base { '$pkg' }

sub table { '$t->{name}' }

sub table_info {
	$pkg->selectall_arrayref(
		"pragma table_info('$t->{name}')",
		{ Slice => {} },
	);
}

sub select {
	my \$class = shift;
	my \$sql   = '$t->{sql_select} ';
	   \$sql  .= shift if \@_;
	my \$rows  = $pkg->selectall_arrayref( \$sql, $slice, \@_ );
	bless \$_, '$t->{class}' foreach \@\$rows;
	wantarray ? \@\$rows : \$rows;
}

sub count {
	my \$class = shift;
	my \$sql   = 'select count(*) from $t->{qname} ';
	   \$sql  .= shift if \@_;
	$pkg->selectrow_array( \$sql, {}, \@_ );
}

END_PERL

			# Handle different versions, because arrayref acts funny
			if ( $t->{array} ) {
				$code .= <<"END_PERL";
sub iterate {
	my \$class = shift;
	my \$call  = pop;
	my \$sql   = '$t->{sql_select} ';
	   \$sql  .= shift if \@_;
	my \$sth   = $pkg->prepare(\$sql);
	\$sth->execute(\@_);
	while ( \$_ = \$sth->fetchrow_arrayref ) {
		\$_ = bless [ \@\$_ ], '$t->{class}';
		\$call->() or last;
	}
	\$sth->finish;
}

END_PERL
			} else {
				$code .= <<"END_PERL";
sub iterate {
	my \$class = shift;
	my \$call  = pop;
	my \$sql   = '$t->{sql_select} ';
	   \$sql  .= shift if \@_;
	my \$sth   = $pkg->prepare(\$sql);
	\$sth->execute(\@_);
	while ( \$_ = \$sth->fetchrow_hashref ) {
		bless \$_, '$t->{class}';
		\$call->() or last;
	}
	\$sth->finish;
}

END_PERL
			}

			# Add the primary key based single object loader
			if ( $t->{pkn} ) {
				if ( $t->{array} ) {
					$code .= <<"END_PERL";
sub load {
	my \$class = shift;
	my \@row   = $pkg->selectrow_array(
		'$t->{sql_select} where $t->{sql_where}',
		undef, \@_,
	);
	unless ( \@row ) {
		Carp::croak("$t->{class} row does not exist");
	}
	bless \\\@row, '$t->{class}';
}

END_PERL
				} else {
					$code .= <<"END_PERL";
sub load {
	my \$class = shift;
	my \$row   = $pkg->selectrow_hashref(
		'$t->{sql_select} where $t->{sql_where}',
		undef, \@_,
	);
	unless ( \$row ) {
		Carp::croak("$t->{class} row does not exist");
	}
	bless \$row, '$t->{class}';
}

END_PERL
				}
			}

			# Generate the elements for tables with primary keys
			if ( $t->{create} ) {
				my $l   = $t->{array} ? '['  : '{';
				my $r   = $t->{array} ? ']'  : '}';
				my $set = $t->{array}
					? '$self->set( $_ => $set{$_} ) foreach keys %set;'
					: '$self->{$_} = $set{$_} foreach keys %set;';
				$code .= <<"END_PERL";
sub new {
	my \$class = shift;
	my \%attr  = \@_;
	bless $l
$t->{pl_new}
	$r, \$class;
}

sub create {
	shift->new(\@_)->insert;
}

sub insert {
	my \$self = shift;
	my \$dbh  = $pkg->dbh;
	\$dbh->do(
		'$t->{sql_insert}',
		{},
$t->{pl_insert}
	);
$t->{pl_fill}
	return \$self;
}

sub update {
	my \$self = shift;
	my \%set  = \@_;
	my \$rows = $pkg->do(
		'update $t->{qname} set ' .
		join( ', ', map { "\\"\$_\\" = ?" } keys \%set ) .
		' where "rowid" = ?',
		{},
		values \%set,
		\$self->rowid,
	);
	unless ( \$rows == 1 ) {
		Carp::croak("Expected to update 1 row, actually updated \$rows");
	}
	$set
	return 1;
}

sub delete {
	return $pkg->do(
		'delete from $t->{qname} where "rowid" = ?', {},
		shift->rowid,
	) if ref \$_[0];
	Carp::croak("Static $pkg->delete has been deprecated");
}

sub delete_where {
	shift; $pkg->do('delete from $t->{qname} where ' . shift, {}, \@_);
}

sub truncate {
	$pkg->do('delete from $t->{qname}');
}

END_PERL
			}

			if ( $t->{create} and $t->{array} ) {
				# Add an additional set method to avoid having
				# the user have to enter manual positions.
				$code .= <<"END_PERL";
sub set {
	my \$self = shift;
	my \$i    = {
$t->{pl_accessor}
	}->{\$_[0]};
	Carp::croak("Bad name '\$_[0]'") unless defined \$i;
	\$self->[\$i] = \$_[1];
}

END_PERL
			}

			# Generate the boring accessors
			if ( $params{xsaccessor} ) {
				my $type    = $t->{create} ? 'accessors' : 'getters';
				my $xsclass = $t->{array}
					? 'Class::XSAccessor::Array'
					: 'Class::XSAccessor';
				my $id = $t->{id}
					? "\t\t$t->{id}->{name} => $t->{id}->{xs},\n"
					: '';
				my $rowid = ($t->{id} and $t->{rowid})
					? "\t\t$t->{rowid}->{name} => $t->{rowid}->{xs},\n"
					: '';

				$code .= <<"END_PERL";
use $xsclass 1.05 {
	getters => {
${rowid}${id}$t->{pl_accessor}
	},
};

END_PERL
			} else {
				if ( $t->{pki} and $t->{rowid} ) {
					$code .= <<"END_PERL";
sub rowid {
	\$_[0]->$t->{rowid}->{key};
}

END_PERL
				}

				if ( $t->{id} ) {
					$code .= <<"END_PERL";
sub id {
	\$_[0]->$t->{id}->{key};
}

END_PERL
				}

				$code .= join "\n\n", map { <<"END_PERL" } grep { ! $_->{fk} } @select;
sub $_->{name} {
	\$_[0]->$_->{key};
}
END_PERL
			}

			# Generate the foreign key accessors
			$code .= join "\n\n", map { <<"END_PERL" } grep { $_->{fk} } @columns;
sub $_->{name} {
	($_->{fk}->[1]->{class}\->select('where \"$_->{fk}->[1]->{pk}->[0]->{name}\" = ?', \$_[0]->$_->{key}))[0];
}
END_PERL
		}
	}

	# We are finished with the database
	$dbh->disconnect;

	# Start the post-table content again
	$code .= "\npackage $pkg;\n" if $params{tables};

	# Append any custom code for the user
	$code .= "\n$params{append}" if defined $params{append};

	# Load the overload classes for each of the tables
	if ( $tables ) {
		$code .= join( "\n",
			"local \$@ = undef;",
			map {
				"eval { require $_->{class} };"
			} @$tables
		);
	}

	# End the class normally
	$code .= "\n\n1;\n";

	# Save to the cache location if caching is enabled
	if ( $cached ) {
		my $dir = File::Basename::dirname($cached);
		unless ( -d $dir ) {
			File::Path::mkpath( $dir, { verbose => 0 } );
		}

		# Save a copy of the code to the file
		local *FILE;
		open( FILE, ">$cached" ) or Carp::croak("open($cached): $!");
		print FILE $code;
		close FILE;
	}

	# Compile the code
	local $@;
	if ( $^P and $^V >= 5.008009 ) {
		local $^P = $^P | 0x800;
		eval($code);
		die $@ if $@;
	} elsif ( $DEBUG ) {
		dval($code);
	} else {
		eval($code);
		die $@ if $@;
	}

	return 1;
}

sub dval {
	# Write the code to the temp file
	require File::Temp;
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print($_[0]);
	close $fh;
	require $filename;
	unlink $filename;

	# Print the debugging output
	# my @trace = map {
		# s/\s*[{;]$//;
		# s/^s/  s/;
		# s/^p/\np/;
		# "$_\n"
	# } grep {
		# /^(?:package|sub)\b/
	# } split /\n/, $_[0];
	# print STDERR @trace, "\nCode saved as $filename\n\n";

	return 1;
}

sub prune {
	my $class = shift;
	push @PRUNE, map { File::Spec->rel2abs($_) } @_;
}

1;

__END__

=pod

=head1 NAME

ORLite - Extremely light weight SQLite-specific ORM

=head1 SYNOPSIS

  package Foo;
  
  # Simplest possible usage
  
  use strict;
  use ORLite 'data/sqlite.db';
  
  my @awesome = Foo::Person->select(
     'where first_name = ?',
     'Adam',
  );
  
  package Bar;
  
  # All available options enabled or specified.
  # Some options shown are mutually exclusive,
  # this code would not actually run.
  
  use ORLite {
      package      => 'My::ORM',
      file         => 'data/sqlite.db',
      user_version => 12,
      readonly     => 1,
      create       => sub {
          my $dbh = shift;
          $dbh->do('CREATE TABLE foo ( bar TEXT NOT NULL )');
      },
      tables       => [ 'table1', 'table2' ],
      cleanup      => 'VACUUM',
      prune        => 1,
  };

=head1 DESCRIPTION

L<SQLite> is a light single file SQL database that provides an
excellent platform for embedded storage of structured data.

However, while it is superficially similar to a regular server-side SQL
database, SQLite has some significant attributes that make using it like
a traditional database difficult.

For example, SQLite is extremely fast to connect to compared to server
databases (1000 connections per second is not unknown) and is
particularly bad at concurrency, as it can only lock transactions at
a database-wide level.

This role as a superfast internal data store can clash with the roles and
designs of traditional object-relational modules like L<Class::DBI> or
L<DBIx::Class>.

What this situation would seem to need is an object-relation system that is
designed specifically for SQLite and is aligned with its idiosyncracies.

ORLite is an object-relation system specifically tailored for SQLite that
follows many of the same principles as the ::Tiny series of modules and
has a design and feature set that aligns directly to the capabilities of
SQLite.

Further documentation will be available at a later time, but the synopsis
gives a pretty good idea of how it works.

=head2 How ORLite Works

ORLite discovers the schema of a SQLite database, and then generates the
code for a complete set of classes that let you work with the objects stored
in that database.

In the simplest form, your target root package "uses" ORLite, which will do
the schema discovery and code generation at compile-time.

When called, ORLite generates two types of packages.

Firstly, it builds database connectivity, transaction support, and other
purely database level functionality into your root namespace.

Secondly, it will create one sub-package underneath the namespace of the root
module for each table or view it finds in the database.

Once the basic table support has been generated, it will also try to load an
"overlay" module of the same name. Thus, by created a Foo::TableName module on
disk containing "extra" code, you can extend the original and add additional
functionality to it.

=head1 OPTIONS

ORLite takes a set of options for the class construction at compile time
as a HASH parameter to the "use" line.

As a convenience, you can pass just the name of an existing SQLite file
to load, and ORLite will apply defaults to all other options.

  # The following are equivalent
  
  use ORLite $filename;
  
  use ORLite {
      file => $filename,
  };

The behaviour of each of the options is as follows:

=head2 package

The optional C<package> parameter is used to provide the Perl root namespace
to generate the code for. This class does not need to exist as a module on
disk, nor does it need to have anything loaded or in the namespace.

By default, the package used is the package that is calling ORLite's import
method (typically via the C<use ORLite { ... }> line).

=head2 file

The compulsory C<file> parameter (the only compulsory parameter) provides
the path to the SQLite file to use for the ORM class tree.

If the file already exists, it must be a valid SQLite file match that
supported by the version of L<DBD::SQLite> that is installed on your
system.

L<ORLite> will throw an exception if the file does not exist, B<unless>
you also provide the C<create> option to signal that L<ORLite> should
create a new SQLite file on demand.

If the C<create> option is provided, the path provided must be creatable.
When creating the database, L<ORLite> will also create any missing
directories as needed.

=head2 user_version

When working with ORLite, the biggest risk to the stability of your code
is often the reliability of the SQLite schema structure over time.

When the database schema changes the code generated by ORLite will also
change. This can easily result in an unexpected change in the API of your
class tree, breaking the code that sits on top of those generated APIs.

To resolve this, L<ORLite> supports a feature called schema version-locking.

Via the C<user_version> SQLite pragma, you can set a revision for your
database schema, increasing the number each time to make a non-trivial
chance to your schema.

  SQLite> PRAGMA user_version = 7

When creating your L<ORLite> package, you should specificy this schema
version number via the C<user_version> option.

  use ORLite {
      file         => $filename,
      user_version => 7,
  };

When connecting to the SQLite database, the C<user_version> you provide
will be checked against the version in the schema. If the versions do
not match, then the schema has unexpectedly changed, and the code that
is generated by L<ORLite> would be different to the expected API.

Rather than risk potentially destructive errors caused by the changing
code, L<ORLite> will simply refuse to run and throw an exception.

Thus, using the C<user_version> feature allows you to write code against
a SQLite database with high-certainty that it will continue to work. Or
at the very least, that should the SQLite schema change in the future your
code fill fail quickly and safely instead of running away and causing
unknown behaviour.

By default, the C<user_version> option is false and the value of
the SQLite C<PRAGMA user_version> will B<not> be checked.

=head2 readonly

To conserve memory and reduce complexity, L<ORLite> will generate the API
differently based on the writability of the SQLite database.

Features like transaction support and methods that result in C<INSERT>,
C<UPDATE> and C<DELETE> queries will only be added if they can actually
be run, resulting in an immediate "no such method" exception at the Perl
level instead of letting the application do more work only to hit an
inevitable SQLite error.

By default, the C<readonly> option is based on the filesystem permissions
of the SQLite database (which matches SQLite's own writability behaviour).

However the C<readonly> option can be explicitly provided if you wish.
Generally you would do this if you are working with a read-write database,
but you only plan to read from it.

Forcing C<readonly> to true will halve the size of the code that is
generated to produce your ORM, reducing the size of any auto-generated
API documentation using L<ORLite::Pod> by a similar amount.

It also ensures that this process will only take shared read locks on the
database (preventing the chance of creating a dead-lock on the SQLite
database).

=head2 create

The C<create> option is used to expand L<ORLite> beyond just consuming
other people's databases to produce and operating on databases user the
direct control of your code.

The C<create> option supports two alternative forms.

If C<create> is set to a simple true value, an empty SQLite file will be
created if the location provided in the C<file> option does not exist.

If C<create> is set to a C<CODE> reference, this function will be executed
on the new database B<before> L<ORLite> attempts to scan the schema.

The C<CODE> reference will be passed a plain L<DBI> connection handle,
which you should operate on normally. Note that because C<create> is fired
before the code generation phase, none of the functionality produced by
the generated classes is available during the execution of the C<create>
code.

The use of C<create> option is incompatible with the C<readonly> option.

=head2 tables

The C<tables> option should be a reference to an array containing a list
of table names. For large or complex SQLite databases where you only need
to make use of a fraction of the schema limiting the set of tables
will reduce both the startup time needed to scan the structure of the
SQLite schema, and reduce the memory cost of the class tree.

If the C<tables> option is not provided, L<ORLite> will attempt to produce
a class for every table in the main schema that is not prefixed with 
with C<sqlite_>.

=head2 cache

  use ORLite {
      file         => 'dbi:SQLite:sqlite.db',
      user_version => 2,
      cache        => 'cache/directory',
  };

The C<cache> option is used to reduce the time needed to scan the SQLite
database table structures and generate the code for them, by saving the
generated code to a cache directory and loading from that file instead
of generating it each time from scratch.

=head2 cleanup

When working with embedded SQLite databases containing rapidly changing
state data, it is important for database performance and general health
to make sure you VACUUM or ANALYZE the database regularly.

The C<cleanup> option should be a single literal SQL statement.

If provided, this statement will be automatically run on the database
during C<END>-time, after the last transaction has been completed.

This will typically either by a full C<'VACUUM ANALYZE'> or the more
simple C<'VACUUM'>.

=head2 prune

In some situation, such as during test scripts, an application will only
need the created SQLite database temporarily. In these situations, the
C<prune> option can be provided to instruct L<ORLite> to delete the
SQLite database when the program ends.

If any directories were made in order to create the SQLite file, these
directories will be cleaned up and removed as well.

If C<prune> is enabled, you should generally not use C<cleanup> as any
cleanup operation will be made pointless when C<prune> deletes the file.

By default, the C<prune> option is set to false.

=head2 shim

In some situtations you may wish to make extensive changes to the behaviour
of the classes and methods generated by ORLite. Under normal circumstances
all code is generated into the table class directly, which can make
overriding method difficult.

The C<shim> option will make ORLite generate all of it's methods into a
seperate C<Foo::TableName::Shim> class, and leave the main table class
C<Foo::TableName> as a transparent subclass of the shim.

This allows you to alter the behaviour of a table class without having
to do nasty tricks with symbol tables in order to alter or replace methods.

  package My::Person;
  
  # Write a log message when we create a new object
  sub create {
      my $class = shift;
      my $self  = SUPER::create(@_);
      my $name  = $self->name;
      print LOG "Created new person '$name'\n";
      return $self;
  }

The C<shim> option is global. It will alter the structure of all table
classes at once. However, unless you are making alterations to a class
the impact of this different class structure should be zero.

=head2 unicode

You can use this option to tell L<ORLite> that your database uses unicode.

At the moment, it just enables the C<sqlite_unicode> option while
connecting to your database. There'll be more in the future.

=head1 ROOT PACKAGE METHODS

All ORLite root packages receive an identical set of methods for
controlling connections to the database, transactions, and the issueing
of queries of various types to the database.

The example root package Foo::Bar is used in any examples.

All methods are static, ORLite does not allow the creation of a Foo::Bar
object (although you may wish to add this capability yourself).

=head2 dsn

  my $string = Foo::Bar->dsn;

The C<dsn> accessor returns the dbi connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = Foo::Bar->dbh;

To reliably prevent potential SQLite deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with ORLite's connection
management.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond the immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 connect

  my $dbh = Foo::Bar->connect;

The C<connect> method is provided for the (extremely rare) situation in
which you need a raw connection to the database, evading the normal tracking
and management provided of the ORM.

The use of raw connections in this manner is strongly discouraged, as you
can create fatal deadlocks in SQLite if either the core ORM or the raw
connection uses a transaction at any time.

To summarise, do not use this method unless you B<REALLY> know what you are
doing.

B<YOU HAVE BEEN WARNED!>

=head2 connected

  my $active = Foo::Bar->connected;

The C<connected> method provides introspection of the connection status
of the library. It returns true if there is any connection or transaction
open to the database, or false otherwise.

=head2 begin

  Foo::Bar->begin;

The C<begin> method indicates the start of a transaction.

In the same way that ORLite allows only a single connection, likewise
it allows only a single application-wide transaction.

No indication is given as to whether you are currently in a transaction
or not, all code should be written neutrally so that it works either way
or doesn't need to care.

Returns true or throws an exception on error.

While transaction support is always built for every L<ORLite>-generated
class tree, if the database is opened C<readonly> the C<commit> method
will not exist at all in the API, and your only way of ending the
transaction (and the resulting persistent connection) will be C<rollback>.

=head2 commit

  Foo::Bar->commit;

The C<commit> method commits the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the commit has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

Returns true or throws an exception on error.

=head2 commit_begin

  Foo::Bar->begin;
  
  # Code for the first transaction...
  
  Foo::Bar->commit_begin;
  
  # Code for the last transaction...
  
  Foo::Bar->commit;

By default, L<ORLite>-generated code uses opportunistic connections.

Every <select> you call results in a fresh L<DBI> C<connect>, and a
C<disconnect> occurs after query processing and before the data is
returned. Connections are B<only> held open indefinitely during a
transaction, with an immediate C<disconnect> after your C<commit>.

This makes ORLite very easy to use in an ad-hoc manner, but can have
performance implications.

While SQLite itself can handle 1000 connections per second, the repeated
destruction and repopulation of SQLite's data page caches between your
statements (or between transactions) can slow things down dramatically.

The C<commit_begin> method is used to C<commit> the current transaction
and immediately start a new transaction, without disconnecting from the
database.

Its exception behaviour and return value is identical to that of a plain
C<commit> call.

=head2 rollback

The C<rollback> method rolls back the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the rollback has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

If a transaction exists at END-time as the process exits, it will be
automatically rolled back.

Returns true or throws an exception on error.

=head2 rollback_begin

  Foo::Bar->begin;
  
  # Code for the first transaction...
  
  Foo::Bar->rollback_begin;
  
  # Code for the last transaction...
  
  Foo::Bar->commit;

By default, L<ORLite>-generated code uses opportunistic connections.

Every <select> you call results in a fresh L<DBI> C<connect>, and a
C<disconnect> occurs after query processing and before the data is
returned. Connections are B<only> held open indefinitely during a
transaction, with an immediate C<disconnect> after your C<commit>.

This makes ORLite very easy to use in an ad-hoc manner, but can have
performance implications.

While SQLite itself can handle 1000 connections per second, the repeated
destruction and repopulation of SQLite's data page caches between your
statements (or between transactions) can slow things down dramatically.

The C<rollback_begin> method is used to C<rollback> the current transaction
and immediately start a new transaction, without disconnecting from the
database.

Its exception behaviour and return value is identical to that of a plain
C<commit> call.

=head2 do

  Foo::Bar->do(
      'insert into table (foo, bar) values (?, ?)',
      {},
      $foo_value,
      $bar_value,
  );

The C<do> method is a direct wrapper around the equivalent L<DBI> method,
but applied to the appropriate locally-provided connection or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = Foo::Bar->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 TABLE PACKAGE METHODS

When you use ORLite, your database tables will be available as 
objects named in a camel-cased fashion. So, if your model name
is Foo::Bar...

  use ORLite {
      package => 'Foo::Bar',
      file    => 'data/sqlite.db',
  };

... then a table named 'user' would be accessed as C<Foo::Bar::User>,
while a table named 'user_data' would become C<Foo::Bar::UserData>.

=head2 base

  my $namespace = Foo::Bar::User->base; # Returns 'Foo::Bar'

Normally you will only need to work directly with a table class,
and only with one ORLite package.

However, if for some reason you need to work with multiple ORLite packages
at the same time without hardcoding the root namespace all the time, you
can determine the root namespace from an object or table class with the
C<base> method.

=head2 table

  print Foo::Bar::UserData->table; # 'user_data'

While you should not need the name of table for any simple operations,
from time to time you may need it programatically. If you do need it,
you can use the C<table> method to get the table name.

=head2 table_info

  # List the columns in the underlying table
  my $columns = Foo::Bar::User->table_info;
  foreach my $c ( @$columns ) {
     print "Column $c->{name} $c->{type}";
     print " not null" if $c->{notnull};
     print " default $c->{dflt_value}" if defined $c->{dflt_value};
     print " primary key" if $c->{pk};
     print "\n";
  }

The C<table_info> method is a wrapper around the SQLite C<table_info>
pragma, and provides simplified access to the column metadata for the
underlying table should you need it for some advanced function that
needs direct access to the column list.

Returns a reference to an C<ARRAY> containing a list of columns, where
each column is a reference to a C<HASH> with the keys C<cid>, C<dflt_value>,
C<name>, C<notnull>, C<pk> and C<type>.

=head2 new

  my $user = Foo::Bar::User->new(
      name => 'Your Name',
      age  => 23,
  );

The C<new> constructor creates an anonymous object, without reading or
writing it to the database. It also won't do validation of any kind,
since ORLite is designed for use with embedded databases and presumes that
you know what you are doing.

=head2 insert

  my $user = Foo::Bar::User->new(
      name => 'Your Name',
      age  => 23,
  )->insert;

The C<insert> method takes an existing anonymous object and inserts it
into the database, returning the object back as a convenience.

It provides the second half of the slower manual two-phase object
construction process.

If the table has an auto-incrementing primary key (and you have not
provided a value for it yourself) the identifier for the new record
will be fetched back from the database and set in your object.

  my $object = Foo::Bar::User->new( name => 'Foo' )->insert;
  
  print "Created new user with id " . $user->id . "\n";

=head2 create

  my $user = Foo::Bar::User->create(
      name => 'Your Name',
      age  => 23,
  );

While the C<new> + C<insert> methods are useful when you need to do
interesting constructor mechanisms, for most situations you already
have all the attributes ready and just want to create and insert the
record in a single step.

The C<create> method provides this shorthand mechanism and is just
the functional equivalent of the following.

  sub create {
      shift->new(@_)->insert;
  }

It returns the newly created object after it has been inserted.

=head2 load

  my $user = Foo::Bar::User->load( $id );

If your table has single column primary key, a C<load> method will be
generated in the class. If there is no primary key, the method is not
created.

The C<load> method provides a shortcut mechanism for fetching a single
object based on the value of the primary key. However it should only
be used for cases where your code trusts the record to already exists.

It returns a C<Foo::Bar::User> object, or throws an exception if the
object does not exist.

=head2 id

The C<id> accessor is a convenience method that is added to your table
class to increase the readability of your code when ORLite detects certain
patterns of column naming.

For example, take the following definition where convention is that all
primary keys are the table name followed by "_id".

  create table foo_bar (
      foo_bar_id integer not null primary key,
      name string not null,
  )

When ORLite detects the use of this pattern, and as long as the table does
not have an "id" column, the additional C<id> accessor will be added to your
class, making these expressions equivalent both in function and performance.

  my $foo_bar = My::FooBar->create( name => 'Hello' );
  
  # Column name accessor
  $foo_bar->foo_bar_id;
  
  # Convenience id accessor
  $foo_bar->id;

As you can see, the latter involves much less repetition and reads much
more cleanly.

=head2 select

  my @users = Foo::Bar::User->select;
  
  my $users = Foo::Bar::User->select( 'where name = ?', @args );

The C<select> method is used to retrieve objects from the database.

In list context, returns an array with all matching elements.
In scalar context an array reference is returned with that same data.

You can filter the results or order them by passing SQL code to the method.

    my @users = DB::User->select( 'where name = ?', $name );

    my $users = DB::User->select( 'order by name' );

Because C<select> provides only the thinnest of layers around pure SQL
(it merely generates the "SELECT ... FROM table_name") you are free to use
anything you wish in your query, including subselects and function calls.

If called without any arguments, it will return all rows of the table in
the natural sort order of SQLite.

=head2 iterate

  Foo::Bar::User->iterate( sub {
      print $_->name . "\n";
  } );

The C<iterate> method enables the processing of large tables one record at
a time without loading having to them all into memory in advance.

This plays well to the strength of SQLite, allowing it to do the work of
loading arbitrarily large stream of records from disk while retaining the
full power of Perl when processing the records.

The last argument to C<iterate> must be a subroutine reference that will be
called for each element in the list, with the object provided in the topic
variable C<$_>.

This makes the C<iterate> code fragment above functionally equivalent to the
following, except with an O(1) memory cost instead of O(n).

    foreach ( Foo::Bar::User->select ) {
        print $_->name . "\n";
    }

You can filter the list via SQL in the same way you can with C<select>.

  Foo::Bar::User->iterate(
      'order by ?', 'name',
      sub {
          print $_->name . "\n";
      }
  );

You can also use it in raw form from the root namespace for better control.
Using this form also allows for the use of arbitrarily complex queries,
including joins. Instead of being objects, rows are provided as ARRAY
references when used in this form.

  Foo::Bar->iterate(
      'select name from user order by name',
      sub {
          print $_->[0] . "\n";
      }
  );

=head2 count

  my $everyone = Foo::Bar::User->count;
  
  my $young = Foo::Bar::User->count( 'where age <= ?', 13 );

You can count the total number of elements in a table by calling 
the C<count> method with no arguments. You can also narrow your
count by passing sql conditions to the method in the same manner
as with the C<select> method.

=head2 delete

  # Delete a single object from the database
  $user->delete;
  
  # Delete a range of rows from the database
  Foo::Bar::User->delete( 'where age <= ?', 13 );

The C<delete> method will delete the single row representing an object,
based on the primary key or SQLite rowid of that object.

The object that you delete will be left intact and untouched, and you
remain free to do with it whatever you wish.

=head2 delete_where

  # Delete a range of rows from the database
  Foo::Bar::User->delete( 'age <= ?', 13 );

The C<delete_where> static method allows the delete of large numbers of
rows from a database while protecting against accidentally doing a
boundless delete (the C<truncate> method is provided specifically for
this purpose).

It takes the same parameters for deleting as the C<select> method,
with the exception that the "where" keyword is automatically provided
for your and should not be passed in.

This ensures that providing an empty of null condition results in an
invalid SQL query and the deletion will not occur.

Returns the number of rows deleted from the database (which may be zero).

=head2 truncate

  # Clear out all records from the table
  Foo::Bar::User->truncate;

The C<truncate> method takes no parameters and is used for only one
purpose, to completely empty a table of all rows.

Having a separate method from C<delete> not only prevents accidents,
but will also do the deletion via the direct SQLite C<TRUNCATE TABLE>
query. This uses a different deletion mechanism, and is
B<significantly> faster than a plain SQL C<DELETE>.

=head1 TO DO

- Support for intuiting reverse relations from foreign keys

- Document the 'create' and 'table' params

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<ORLite::Mirror>, L<ORLite::Migrate>, L<ORLite::Pod>

=head1 COPYRIGHT

Copyright 2008 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
