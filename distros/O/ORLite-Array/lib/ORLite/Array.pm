package ORLite::Array;

# See POD at end of file for documentation

use 5.006;
use strict;
use Carp              ();
use File::Spec   0.80 ();
use File::Temp   0.20 ();
use File::Path   2.04 ();
use File::Basename  0 ();
use Params::Util 0.33 ();
use DBI         1.607 ();
use DBD::SQLite  1.25 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

BEGIN {
    unless ( defined $INC{'ORLite.pm'} ) {
        $INC{'ORLite.pm'} = __FILE__;
        @ORLite::ISA = __PACKAGE__;
        $ORLite::VERSION = '1.28';
    }
}

# Support for the 'prune' option
my @PRUNE = ();
END {
       foreach ( @PRUNE ) {
               next unless -e $_;
               require File::Remove;
               File::Remove::remove($_);
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
	my %params;
	if ( defined Params::Util::_STRING($_[1]) ) {
		# Support the short form "use ORLite 'db.sqlite'"
		%params = (
			file     => $_[1],
			readonly => undef, # Automatic
			package  => undef, # Automatic
			tables   => 1,
		);
	} elsif ( Params::Util::_HASHLIKE($_[1]) ) {
		%params = %{ $_[1] };
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}
	unless ( defined $params{create} ) {
		$params{create} = 0;
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
	unless ( defined $params{tables} ) {
		$params{tables} = 1;
	}
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}
	unless ( Params::Util::_CLASS($params{package}) ) {
		Carp::croak("Missing or invalid package class");
	}

	# Connect to the database
	my $file     = File::Spec->rel2abs($params{file});
	my $created  = ! -f $params{file};
	if ( $created ) {
		# Create the parent directory
		my $dir = File::Basename::dirname($file);
		unless ( -d $dir ) {
			my @dirs = File::Path::mkpath( $dir, { verbose => 0 } );
            $class->prune(@dirs) if $params{prune};
		}
        $class->prune($file) if $params{prune};
	}
	my $pkg      = $params{package};
	my $readonly = $params{readonly};
	my $dsn      = "dbi:SQLite:$file";
	my $dbh      = DBI->connect($dsn);

	# Schema creation support
	if ( $created and Params::Util::_CODELIKE($params{create}) ) {
		$params{create}->( $dbh );
	}

	# Check the schema version before generating
	my $version  = $dbh->selectrow_arrayref('pragma user_version')->[0];
	if ( exists $params{user_version} and $version != $params{user_version} ) {
		die "Schema user_version mismatch (got $version, wanted $params{user_version})";
	}

	# Generate the support package code
	my $code = <<"END_PERL";
package $pkg;

use strict;
use Carp ();
use DBI  ();

my \$DBH = undef;

sub orlite { '$VERSION' }

sub sqlite { '$file' }

sub dsn { '$dsn' }

sub dbh {
	\$DBH or
	\$_[0]->connect or
	Carp::croak("connect: \$DBI::errstr");
}

sub connect {
	DBI->connect(\$_[0]->dsn);
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
	\$_[0]->selectrow_arrayref("pragma \$_[1]")->[0];
}

sub iterate {
	my \$class = shift;
	my \$call  = pop;
	my \$sth   = \$class->prepare( shift );
	\$sth->execute( \@_ );
	while ( \$_ = \$sth->fetchrow_arrayref ) {
		\$call->() or last;
	}
	\$sth->finish;
}

END_PERL

	# Add transaction support if not readonly
	$code .= <<"END_PERL" unless $readonly;
sub begin {
	\$DBH or
	\$DBH = \$_[0]->connect or
	Carp::croak("connect: \$DBI::errstr");
	\$DBH->begin_work;
}

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

	# Optionally generate the table classes
	if ( $params{tables} ) {
		# Capture the raw schema information
		my $tables = $dbh->selectall_arrayref(
			'select * from sqlite_master where name not like ? and type = ?',
			{ Slice => {} }, 'sqlite_%', 'table',
		);
		foreach my $table ( @$tables ) {
			$table->{columns} = $dbh->selectall_arrayref(
				"pragma table_info('$table->{name}')",
			 	{ Slice => {} },
			);
		}

		# Generate the main additional table level metadata
		my %tindex = map { $_->{name} => $_ } @$tables;
		foreach my $table ( @$tables ) {
			my @columns      = @{ $table->{columns} };
			my @names        = map { $_->{name} } @columns;
			$table->{cindex} = map { $_->{name} => $_ } @columns;

			# Discover the primary key
			@{$table->{pk}}  = map($_->{name}, grep { $_->{pk} } @columns);

			# What will be the class for this table
			$table->{class}  = ucfirst lc $table->{name};
			$table->{class}  =~ s/_([a-z])/uc($1)/ge;
			$table->{class}  = "${pkg}::$table->{class}";

			# Generate various SQL fragments
			my $sql = $table->{sql} = { create => $table->{sql} };
			$sql->{cols}     = join ', ', map { '"' . $_ . '"' } @names;
			$sql->{vals}     = join ', ', ('?') x scalar @columns;
			$sql->{select}   = "select $table->{sql}->{cols} from $table->{name}";
			$sql->{count}    = "select count(*) from $table->{name}";
			$sql->{insert}   = join ' ',
				"insert into $table->{name}" .
				"( $table->{sql}->{cols} )"  .
				" values ( $table->{sql}->{vals} )";
		}

		# Generate the foreign key metadata
		foreach my $table ( @$tables ) {
			# Locate the foreign keys
			my %fk     = ();
			my @fk_sql = $table->{sql}->{create} =~ /[(,]\s*(.+?REFERENCES.+?)\s*[,)]/g;

			# Extract the details
			foreach ( @fk_sql ) {
				unless ( /^(\w+).+?REFERENCES\s+(\w+)\s*\(\s*(\w+)/ ) {
					die "Invalid foreign key $_";
				}
				$fk{"$1"} = [ "$2", $tindex{"$2"}, "$3" ];
			}
			foreach ( @{ $table->{columns} } ) {
				$_->{fk} = $fk{$_->{name}};
			}
		}

		# Generate the per-table code
		foreach my $table ( @$tables ) {
			# Generate the accessors
			my $sql     = $table->{sql};
			my @columns = @{ $table->{columns} };
			my @names   = map { $_->{name} } @columns;

            my $i;
            my %mapping = map { $_ => $i++ } @names;

			# Generate the elements in all packages
			$code .= <<"END_PERL";
package $table->{class};

sub base { '$pkg' }

sub table { '$table->{name}' }

sub select {
	my \$class = shift;
	my \$sql   = '$sql->{select} ';
	   \$sql  .= shift if \@_;
	my \$rows  = $pkg->selectall_arrayref( \$sql, {}, \@_ );
	bless( \$_, '$table->{class}' ) foreach \@\$rows;
	wantarray ? \@\$rows : \$rows;
}

sub count {
	my \$class = shift;
	my \$sql   = '$sql->{count} ';
	   \$sql  .= shift if \@_;
	$pkg->selectrow_array( \$sql, {}, \@_ );
}

sub iterate {
	my \$class = shift;
	my \$call  = pop;
	my \$sql   = '$sql->{select} ';
	   \$sql  .= shift if \@_;
	my \$sth   = $pkg->prepare( \$sql );
	\$sth->execute( \@_ );
	while ( \$_ = \$sth->fetchrow_arrayref ) {
        \$_ = [ \@{ \$_ } ];
		bless( \$_, '$table->{class}' );
		\$call->() or last;
	}
	\$sth->finish;
}

END_PERL

			# Generate the elements for tables with primary keys
			if ( defined $table->{pk} and ! $readonly ) {
				my $nattr = join "\n", map { "\t\t\$attr{$_}," } @names;
                my $pk_index = $mapping{ $table->{pk}->[0] };
				my $fill_pk = scalar @{$table->{pk}} == 1 
					    ? "\t\$self->[$pk_index] = \$dbh->func('last_insert_rowid') unless \$self->[$pk_index];"
					    : q{};
				my $where_pk      = join(' and ', map("$_ = ?", @{$table->{pk}}));
				my $where_pk_attr = join("\n", map("\t\t\$self->[$mapping{$_}],", @{$table->{pk}}));				
				$code .= <<"END_PERL";

sub new {
	my \$class = shift;
	my \%attr  = \@_;
	bless [
$nattr
	], \$class;
}

sub create {
	shift->new(\@_)->insert;
}

sub insert {
	my \$self = shift;
	my \$dbh  = $pkg->dbh;
	\$dbh->do('$sql->{insert}', {},
        \@\$self
	);
$fill_pk	
	return \$self;
}

sub delete {
	my \$self = shift;
	return $pkg->do(
		'delete from $table->{name} where $where_pk',
		{}, 
$where_pk_attr		
	) if ref \$self;
	Carp::croak("Must use truncate to delete all rows") unless \@_;
	return $pkg->do(
		'delete from $table->{name} ' . shift,
		{}, \@_,
	);
}

sub truncate {
	$pkg->do( 'delete from $table->{name}', {} );
}

END_PERL

			}

		# Generate the accessors
		$code .= join "\n\n", map { $_->{fk} ? <<"END_DIRECT" : <<"END_ACCESSOR" } @columns;
sub $_->{name} {
	($_->{fk}->[1]->{class}\->select('where $_->{fk}->[1]->{pk}->[0] = ?', \$_[0]->[$mapping{$_->{name}}]))[0];
}
END_DIRECT
sub $_->{name} : lvalue {
	\$_[0]->[$mapping{$_->{name}}];
}
END_ACCESSOR

		}
	}
	$dbh->disconnect;

	# Add any custom code to the end
	if ( defined $params{append} ) {
		$code .= "\npackage $pkg;\n" if $params{tables};
		$code .= "\n$params{append}";
	}

	# Load the code
	if ( $DEBUG ) {
		dval("$code\n\n1;\n");
	} else {
		eval("$code\n\n1;\n");
		die $@ if $@;
	}

	return 1;
}

sub dval {
	# Write the code to the temp file
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print($_[0]);
	close $fh;
	require $filename;
	unlink $filename;

	# Print the debugging output
	my @trace = map {
		s/\s*[{;]$//;
		s/^s/  s/;
		s/^p/\np/;
		"$_\n"
	} grep {
		/^(?:package|sub)\b/
	} split /\n/, $_[0];
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

ORLite::Array - Array based objects for ORLite

=head1 SYNOPSIS

  # Used like the regular ORLite:
  package Foo;

  # Simplest possible usage. See documentation for ORlite for advanced usage.

  use ORLite::Array 'data/sqlite.db';

  my @awesome = Foo::Person->select(
     'where first_name = ?',
     'Adam',
  );

  # Or used with extensions:
  package Foo;

  use ORLite::Array ();
  use ORLite::Mirror 'http://myserver/path/mydb.sqlite';


=head1 DESCRIPTION

ORLite is a light weight ORM specifically designed for used with SQLite
databases. By changing ORLite's hash based objects to using array based
objects we can cut away some time spend in DBI slicing the objects.

For some sample examples this has show the average time spend in the select()
method going from 350 µs/call to 160 µs/call.

=head1 ACCESSORS

B<THIS FEATURE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

Encapsulation isn't a goal. With ORLite you were able to access the individual
keys of the hash. This isn't an usable posibility with array based objects. As
an alternative ORLite::Array marks accessors for non foreign key fields as
lvalue methods. This makes it possible to update attributes this way:

  my $person = Foo::Person->select(
      'where id = ?', 42
  );
  $person->age++;
  $person->weigth += 10;

B<THIS FEATURE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

=head1 TODO

- Support for updating foreign key fields

=head1 COMPATIBILITY

This code is compatible with ORLite version 1.28

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Array>

For other issues, contact the author.

=head1 AUTHOR

Peter Makholm E<lt>peter@makholm.netE<gt>

=head1 SEE ALSO

L<ORLite>

=head1 COPYRIGHT

Copyright 2008 - 2009 Adam Kennedy.
                 2009 Peter Makholm

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
