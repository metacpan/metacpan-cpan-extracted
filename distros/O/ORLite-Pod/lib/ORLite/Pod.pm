package ORLite::Pod;

=pod

=head1 NAME

ORLite::Pod - Documentation generator for ORLite

=head1 SYNOPSIS

  my $generator = ORLite::Pod->new(
      from   => 'My::Project::DB',
      to     => 'My-Project/lib',
      author => 'Adam Kennedy',
      email  => 'adamk@cpan.org',
  );
  
  $generator->run;

=head1 DESCRIPTION

The biggest downside of L<ORLite> is that because it can generate you
an entire ORM in one line of code, you can have a large an extensive
API without anywhere for documentation for the API to exist.

The result is quick efficient creation of APIs that nobody can
understand or use :)

B<ORLite::Pod> was created to fix this problem by allowing you to keep
your slimline Perl module as is, but generating a tree of .pod files
alongside the regular modules containing the documentation for the API.

B<ORLite::Pod> connects directly to a loaded ORLite instance,
interrogating it to find the database it connects to, and discovering
which tables have or don't have classes generated for them.

TO BE COMPLETED

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp                    ();
use File::Spec       3.2701 ();
use File::Path         2.07 ();
use File::Basename        0 ();
use Params::Util       1.00 ();
use Class::Inspector   1.23 ();
use ORLite             1.23 ();
use Template           2.20 ();

our $VERSION = '0.11';

my $year = (localtime(time))[5] + 1900;





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Normalise flags
	unless ( defined $self->trace ) {
		$self->{trace} = 1;
	}
	$self->{trace} = !! $self->{trace};

	# Check params
	unless (
		Params::Util::_CLASS($self->from)
		and
		$self->from->can('orlite')
	) {
		die("Did not provide a 'from' ORLite root class to generate from");
	}
	my $to = $self->to;
	unless ( $self->to ) {
		die("Did not provide a 'to' lib directory to write into");
	}
	unless ( -d $self->to ) {
		die("The 'to' lib directory '$to' does not exist");
	}
	unless ( -w $self->to ) {
		die("No permission to write to directory '$to'");
	}
	unless ( defined $self->author ) {
		$self->{author} = '';
	}
	unless ( defined $self->email ) {
		$self->{email} = '';
	}
	unless ( $self->year ) {
		$self->{year} = $year;
	}

	# Create the copyright year
	if ( $self->{year} == $year ) {
		$self->{copyyear} = $self->{year};
	} else {
		$self->{copyyear} = "$self->{year} - $year";
	}

	# Create the Template Toolkit context
	$self->{template} = Template->new( {
		PRE_CHOMP => 1,
	} );

	return $self;
}

sub from {
	$_[0]->{from};
}

sub dist {
	my $dist = $_[0]->from;
	$dist =~ s/::/-/g;
	return $dist;
}

sub to {
	$_[0]->{to};
}

sub author {
	$_[0]->{author};
}

sub author_pod {
	my $self = shift;
	if ( $self->author and $self->email ) {
		return $self->author . ' E<lt>' . $self->email . 'E<gt>';
	} elsif ( $self->author ) {
		return $self->author;
	} else {
		return '';
	}
}

sub email {
	$_[0]->{email};
}

sub year {
	$_[0]->{year};
}

sub template {
	$_[0]->{template};
}





#####################################################################
# POD Generation

sub run {
	my $self = shift;
	my $pkg  = $self->from;

	# Capture the raw schema information
	$self->trace("Analyzing " . $pkg->dsn . "...\n");
	my $dbh    = $pkg->dbh;
	my $tables = $dbh->selectall_arrayref(
		'select * from sqlite_master where type = ?',
		{ Slice => {} }, 'table',
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
		$table->{pk}     = List::Util::first { $_->{pk} } @columns;
		$table->{pk}     = $table->{pk}->{name} if $table->{pk};

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

	# Generate the root module .pod file
	$self->write_db( $tables );

	# Generate the table .pod files
	foreach my $table ( @$tables ) {
		# Beautify the create fragment
		$table->{create} = $self->beautify(
			$table->{sql}->{create}
		);

		# Skip tables we aren't modelling
		next unless $table->{class}->can('select');

		# Generate the table-specific file
		$self->write_table( $tables, $table );
	}

	return 1;
}

sub beautify {
	my $sql  = $_[1];
	my $copy = $sql;

	# Normalise and trim whitespace
	$copy =~ s/\s+/ /sg;
	$copy =~ s/\(\s+/(/sg;
	$copy =~ s/\s+\)/)/sg;
	$copy =~ s/\s*,\s*/,/sg;
	$copy =~ s/^\s+//s;
	$copy =~ s/\s+$//s;

	# Find the outermost braces
	unless ( $copy =~ /^(.+?\()(.+)(\).*)\z/ ) {
		# Give up
		return $sql;
	}
	my $create  = $1;
	my $colspec = $2;
	my $suffix  = $3;

	# Split the columns
	my @columns = split /(?<=,)/, $colspec;

	# Reassemble the pieces
	return join '', (
		"$create\n",
		( map { "    $_\n" } @columns ),
		"$suffix\n",
	);
}





#####################################################################
# Generation of Base Documentation

sub write {
	my $self  = shift;
	my $file  = shift;
	my $input = shift;
	my $hash  = shift;

	# Strip the leading pipes off the template
	$input =~ s/^\|//gm;

	# Process the template
	my $template = $self->template;
	my $output   = '';
	my $rv       = $template->process(\$input, $hash, \$output);
	unless ( $rv ) {
		die $template->error;
	}

	# Write the file
	local *FILE;
	open( FILE, '>', $file ) or die "open: $!";
	print FILE $output;
	close FILE;

	return 1;	
}

sub trace {
	my $self = shift;
	if ( $self->{trace} ) {
		print @_;
	}
	return 1;
}

sub write_db {
	my $self    = shift;
	my $tables  = shift;
	my $pkg     = $self->from;
	my $methods = Class::Inspector->methods($pkg);

	# Determine the file we're going to be writing to
	my $file = File::Spec->catfile(
		$self->to,
		 split( /::/, $pkg )
	) . '.pod';

	# Generate and write the file
	$self->trace("Generating $file...\n");
	$self->write( $file, template_db(), {
		self       => $self,
		pkg        => $pkg,
		tables     => $tables,
		orlite2pod => $ORLite::Pod::VERSION,
		method     => {
			map { $_ => 1 } @$methods,
		},
	} );
}





#####################################################################
# Generation of Table-Specific Documentation

sub write_table {
	my $self    = shift;
	my $tables  = shift;
	my $table   = shift;
	my $root    = $self->from;
	my $pkg     = $table->{class};
	my $methods = Class::Inspector->methods($pkg);

	# Determine the file we're going to be writing to
	my $file = File::Spec->catfile(
		$self->to,
		 split( /::/, $pkg )
	) . '.pod';

	# Create the parent directory if needed
	my $dir = File::Basename::dirname($file);
	unless ( -d $dir ) {
		File::Path::make_path( $dir, { verbose => 0 } );
	}

	# Generate and write the file
	$self->trace("Generating $file...\n");
	$self->write( $file, template_table(), {
		self   => $self,
		pkg    => $pkg,
		root   => $root,
		tables => $tables,
		table  => $table,
		method => {
			map { $_ => 1 } @$methods,
		},
	} );
}





#####################################################################
# Root Template

sub template_db { <<'END_TT' }
|=head1 NAME
|
|[%+ pkg %] - An ORLite-based ORM Database API
|
|=head1 DESCRIPTION
|
|TO BE COMPLETED
|
|=head1 METHODS
|
[% IF method.dsn %]
|=head2 dsn
|
|  my $string = [%+ pkg %]->dsn;
|
|The C<dsn> accessor returns the L<DBI> connection string used to connect
|to the SQLite database as a string.
|
[% END %]
[% IF method.dbh %]
|=head2 dbh
|
|  my $handle = [%+ pkg %]->dbh;
|
|To reliably prevent potential L<SQLite> deadlocks resulting from multiple
|connections in a single process, each ORLite package will only ever
|maintain a single connection to the database.
|
|During a transaction, this will be the same (cached) database handle.
|
|Although in most situations you should not need a direct DBI connection
|handle, the C<dbh> method provides a method for getting a direct
|connection in a way that is compatible with connection management in
|L<ORLite>.
|
|Please note that these connections should be short-lived, you should
|never hold onto a connection beyond your immediate scope.
|
|The transaction system in ORLite is specifically designed so that code
|using the database should never have to know whether or not it is in a
|transation.
|
|Because of this, you should B<never> call the -E<gt>disconnect method
|on the database handles yourself, as the handle may be that of a
|currently running transaction.
|
|Further, you should do your own transaction management on a handle
|provided by the <dbh> method.
|
|In cases where there are extreme needs, and you B<absolutely> have to
|violate these connection handling rules, you should create your own
|completely manual DBI-E<gt>connect call to the database, using the connect
|string provided by the C<dsn> method.
|
|The C<dbh> method returns a L<DBI::db> object, or throws an exception on
|error.
|
[% END %]
[% IF method.begin %]
|=head2 begin
|
|  [%+ pkg %]->begin;
|
|The C<begin> method indicates the start of a transaction.
|
|In the same way that ORLite allows only a single connection, likewise
|it allows only a single application-wide transaction.
|
|No indication is given as to whether you are currently in a transaction
|or not, all code should be written neutrally so that it works either way
|or doesn't need to care.
|
|Returns true or throws an exception on error.
|
[% END %]
[% IF method.commit %]
|=head2 commit
|
|  [%+ pkg %]->commit;
|
|The C<commit> method commits the current transaction. If called outside
|of a current transaction, it is accepted and treated as a null operation.
|
|Once the commit has been completed, the database connection falls back
|into auto-commit state. If you wish to immediately start another
|transaction, you will need to issue a separate -E<gt>begin call.
|
|Returns true or throws an exception on error.
|
[% END %]
[% IF method.rollback %]
|=head2 rollback
|
|The C<rollback> method rolls back the current transaction. If called outside
|of a current transaction, it is accepted and treated as a null operation.
|
|Once the rollback has been completed, the database connection falls back
|into auto-commit state. If you wish to immediately start another
|transaction, you will need to issue a separate -E<gt>begin call.
|
|If a transaction exists at END-time as the process exits, it will be
|automatically rolled back.
|
|Returns true or throws an exception on error.
|
|=head2 do
|
|  [%+ pkg %]->do(
|      'insert into table ( foo, bar ) values ( ?, ? )', {},
|      \$foo_value,
|      \$bar_value,
|  );
|
|The C<do> method is a direct wrapper around the equivalent L<DBI> method,
|but applied to the appropriate locally-provided connection or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectall_arrayref %]
|=head2 selectall_arrayref
|
|The C<selectall_arrayref> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectall_hashref %]
|=head2 selectall_hashref
|
|The C<selectall_hashref> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectcol_arrayref %]
|=head2 selectcol_arrayref
|
|The C<selectcol_arrayref> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectrow_array %]
|=head2 selectrow_array
|
|The C<selectrow_array> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectrow_arrayref %]
|=head2 selectrow_arrayref
|
|The C<selectrow_arrayref> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.selectrow_hashref %]
|=head2 selectrow_hashref
|
|The C<selectrow_hashref> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction.
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
[% END %]
[% IF method.prepare %]
|=head2 prepare
|
|The C<prepare> method is a direct wrapper around the equivalent
|L<DBI> method, but applied to the appropriate locally-provided connection
|or transaction
|
|It takes the same parameters and has the same return values and error
|behaviour.
|
|In general though, you should try to avoid the use of your own prepared
|statements if possible, although this is only a recommendation and by
|no means prohibited.
|
[% END %]
[% IF method.pragma %]
|=head2 pragma
|
|  # Get the user_version for the schema
|  my $version = [% pkg %]->pragma('user_version');
|
|The C<pragma> method provides a convenient method for fetching a pragma
|for a database. See the L<SQLite> documentation for more details.
|
[% END %]
|=head1 SUPPORT
|
|B<[%+ pkg %]> is based on L<ORLite>.
|
|Documentation created by L<ORLite::Pod> [% orlite2pod %].
|
|[% IF self.rt %]
|Bugs should be reported via the CPAN bug tracker at
|
|L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=[% self.dist %]>
|
|For other issues, contact the author.
[% ELSE %]
|For general support please see the support section of the main
|project documentation.
[% END %]
|
[% IF self.author_pod %]
|=head1 AUTHOR
|
|[%+ self.author_pod %]
[% END %]
|=head1 COPYRIGHT
|
|Copyright [% self.copyyear %] [%+ self.author %].
|
|This program is free software; you can redistribute
|it and/or modify it under the same terms as Perl itself.
|
|The full text of the license can be found in the
|LICENSE file included with this module.
|
END_TT





#####################################################################
# Table Template

sub template_table { <<'END_TT' }
|=head1 NAME
|
|[%+ pkg %] - [% root %] class for the [% table.name %] table
|
|=head1 DESCRIPTION
|
|TO BE COMPLETED
|
|=head1 METHODS
|
[% IF method.base %]
|=head2 base
|
|  # Returns '[% root %]'
|  my $namespace = [% pkg %]->base;
|
|Normally you will only need to work directly with a table class,
|and only with one ORLite package.
|
|However, if for some reason you need to work with multiple ORLite packages
|at the same time without hardcoding the root namespace all the time, you
|can determine the root namespace from an object or table class with the
|C<base> method.
|
[% END %]
[% IF method.table %]
|=head2 table
|
|  # Returns '[% table.name %]'
|  print [% pkg %]->table;
|
|While you should not need the name of table for any simple operations,
|from time to time you may need it programatically. If you do need it,
|you can use the C<table> method to get the table name.
|
[% END %]
[% IF method.load %]
|=head2 load
|
|  my $object = [% pkg %]->load( $[% table.pk %] );
|
|If your table has single column primary key, a C<load> method will be
|generated in the class. If there is no primary key, the method is not
|created.
|
|The C<load> method provides a shortcut mechanism for fetching a single
|object based on the value of the primary key. However it should only
|be used for cases where your code trusts the record to already exists.
|
|It returns a C<[% pkg %]> object, or throws an exception if the
|object does not exist.
|
[% END %]
[% IF method.select %]
|=head2 select
|
|  # Get all objects in list context
|  my @list = [% pkg %]->select;
|  
|  # Get a subset of objects in scalar context
|  my $array_ref = [% pkg %]->select(
|      'where [% table.pk %] > ? order by [% table.pk %]',
|      1000,
|  );
|
|The C<select> method executes a typical SQL C<SELECT> query on the
|[%+ table.name %] table.
|
|It takes an optional argument of a SQL phrase to be added after the
|C<FROM [% table.name %]> section of the query, followed by variables
|to be bound to the placeholders in the SQL phrase. Any SQL that is
|compatible with SQLite can be used in the parameter.
|
|Returns a list of B<[% pkg %]> objects when called in list context, or a
|reference to an C<ARRAY> of B<[% pkg %]> objects when called in scalar
|context.
|
|Throws an exception on error, typically directly from the L<DBI> layer.
|
[% END %]
[% IF method.iterate %]
|=head2 iterate
|
|  [%+ pkg %]->iterate( sub {
|      print $_->[% table.pk %] . "\n";
|  } );
|
|The C<iterate> method enables the processing of large tables one record at
|a time without loading having to them all into memory in advance.
|
|This plays well to the strength of SQLite, allowing it to do the work of
|loading arbitrarily large stream of records from disk while retaining the
|full power of Perl when processing the records.
|
|The last argument to C<iterate> must be a subroutine reference that will be
|called for each element in the list, with the object provided in the topic
|variable C<$_>.
|
|This makes the C<iterate> code fragment above functionally equivalent to the
|following, except with an O(1) memory cost instead of O(n).
|
|  foreach ( [% pkg %]->select ) {
|      print $_->[% table.pk %] . "\n";
|  }
|
|You can filter the list via SQL in the same way you can with C<select>.
|
|  [%+ pkg %]->iterate(
|      'order by ?', '[% table.pk %]',
|      sub {
|          print $_->[% table.pk %] . "\n";
|      }
|  );
|
|You can also use it in raw form from the root namespace for better control.
|Using this form also allows for the use of arbitrarily complex queries,
|including joins. Instead of being objects, rows are provided as C<ARRAY>
|references when used in this form.
|
|  [%+ root %]->iterate(
|      'select name from [% table.name %] order by [% table.pk %]',
|      sub {
|          print $_->[0] . "\n";
|      }
|  );
|
[% END %]
[% IF method.count %]
|=head2 count
|
|  # How many objects are in the table
|  my $rows = [% pkg %]->count;
|  
|  # How many objects 
|  my $small = [% pkg %]->count(
|      'where [% table.pk %] > ?',
|      1000,
|  );
|
|The C<count> method executes a C<SELECT COUNT(*)> query on the
|[%+ table.name %] table.
|
|It takes an optional argument of a SQL phrase to be added after the
|C<FROM [% table.name %]> section of the query, followed by variables
|to be bound to the placeholders in the SQL phrase. Any SQL that is
|compatible with SQLite can be used in the parameter.
|
|Returns the number of objects that match the condition.
|
|Throws an exception on error, typically directly from the L<DBI> layer.
|
[% END %]
[% IF method.new %]
|=head2 new
|
|  TO BE COMPLETED
|
|The C<new> constructor is used to create a new abstract object that
|is not (yet) written to the database.
|
|Returns a new L<[% pkg %]> object.
|
[% END %]
[% IF method.create %]
|=head2 create
|
|  my $object = [% pkg %]->create(
|[%- FOREACH column IN table.columns %]
|      [%+ column.name %] => 'value',
|[%- END %]
|  );
|
|The C<create> constructor is a one-step combination of C<new> and
|C<insert> that takes the column parameters, creates a new
|L<[% pkg %]> object, inserts the appropriate row into the
|L<[% table.name %]> table, and then returns the object.
|
|If the primary key column C<[% table.pk %]> is not provided to the
|constructor (or it is false) the object returned will have
|C<[% table.pk %]> set to the new unique identifier.
| 
|Returns a new L<[% table.name %]> object, or throws an exception on
|error, typically from the L<DBI> layer.
|
[% END %]
[% IF method.insert %]
|=head2 insert
|
|  $object->insert;
|
|The C<insert> method commits a new object (created with the C<new> method)
|into the database.
|
|If a the primary key column C<[% table.pk %]> is not provided to the
|constructor (or it is false) the object returned will have
|C<[% table.pk %]> set to the new unique identifier.
|
|Returns the object itself as a convenience, or throws an exception
|on error, typically from the L<DBI> layer.
|
[% END %]
[% IF method.delete %]
|=head2 delete
|
|  # Delete a single instantiated object
|  $object->delete;
|  
|  # Delete multiple rows from the [% table.name %] table
|  [%+ pkg %]->delete('where [% table.pk %] > ?', 1000);
|
|The C<delete> method can be used in a class form and an instance form.
|
|When used on an existing B<[% pkg %]> instance, the C<delete> method
|removes that specific instance from the C<[% table.name %]>, leaving
|the object intact for you to deal with post-delete actions as you wish.
|
|When used as a class method, it takes a compulsory argument of a SQL
|phrase to be added after the C<DELETE FROM [% table.name %]> section
|of the query, followed by variables to be bound to the placeholders
|in the SQL phrase. Any SQL that is compatible with SQLite can be used
|in the parameter.
|
|Returns true on success or throws an exception on error, or if you
|attempt to call delete without a SQL condition phrase.
|
[% END %]
[% IF method.truncate %]
|=head2 truncate
|
|  # Delete all records in the [% table.name %] table
|  [%+ pkg %]->truncate;
|
|To prevent the common and extremely dangerous error case where
|deletion is called accidentally without providing a condition,
|the use of the C<delete> method without a specific condition
|is forbidden.
|
|Instead, the distinct method C<truncate> is provided to delete
|all records in a table with specific intent.
|
|Returns true, or throws an exception on error.
|
[% END %]
|=head1 ACCESSORS
|
[% pk = table.pk %]
[% IF method.$pk %]
|=head2 [% pk %]
|
|  if ( $object->[% pk %] ) {
|      print "Object has been inserted\n";
|  } else {
|      print "Object has not been inserted\n";
|  }
|
|Returns true, or throws an exception on error.
|
[% END %]
|REMAINING ACCESSORS TO BE COMPLETED
|
|=head1 SQL
|
|The [% table.name %] table was originally created with the
|following SQL command.
|
|[%+ table.create | indent('  ') -%]
|
|=head1 SUPPORT
|
|[%+ pkg %] is part of the L<[% root %]> API.
|
|See the documentation for L<[% root %]> for more information.
|
[% IF self.author_pod %]
|=head1 AUTHOR
|
|[%+ self.author_pod %]
|
[% END %]
|=head1 COPYRIGHT
|
|Copyright [% self.copyyear %] [%+ self.author %].
|
|This program is free software; you can redistribute
|it and/or modify it under the same terms as Perl itself.
|
|The full text of the license can be found in the
|LICENSE file included with this module.
|
END_TT

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Pod>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
