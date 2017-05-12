package RDF::RDB2RDF::DirectMapping;

use 5.010;
use strict;
use utf8;

use Carp qw[carp croak];
use Data::UUID;
use DBI;
use MIME::Base64 qw[];
use RDF::Trine qw[iri blank literal statement];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use Scalar::Util qw[refaddr blessed];
use URI::Escape::Optimistic qw[uri_escape_optimistic];
use match::simple qw[match];

use namespace::clean;
use base qw[
	RDF::RDB2RDF
	RDF::RDB2RDF::DatatypeMapper
];

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

sub new
{
	my ($class, %args) = @_;
	
	$args{prefix}        = '' unless defined $args{prefix};
	$args{rdfs}          = 0  unless defined $args{rdfs};
	$args{warn_sql}      = 0  unless defined $args{warn_sql};
	$args{ignore_tables} = [] unless defined $args{ignore_tables};
	$args{unique}        = Data::UUID->new->create_str;
	
	bless \%args, $class;
}

sub prefix        :lvalue { $_[0]->{prefix} }
sub rdfs          :lvalue { $_[0]->{rdfs} }
sub ignore_tables :lvalue { $_[0]->{ignore_tables} }
sub warn_sql      :lvalue { $_[0]->{warn_sql} }

sub _unquote_identifier
{
	my $i = shift;
	return $1 if $i =~ /^\"(.+)\"$/;
	return $i;
}

sub rowmap (&$)
{
	my ($coderef, $iter) = @_;
	
	my @results = ();
	ref($iter) or return @results;
	
	local $_;
	my $i = 0;
	while ($_ = $iter->fetchrow_hashref)
	{
		push @results, $coderef->($coderef, $iter, $_, ++$i);
	}
	
	wantarray ? @results : scalar(@results);
}

sub layout
{
	my ($self, $dbh, $schema) = @_;

	unless ($self->{layout}{refaddr($dbh).'|'.$schema})
	{
		carp sprintf('READ SCHEMA "%s"', $schema||'%') if $self->warn_sql;
		
		my $rv     = {};
		my @tables = rowmap {
			_unquote_identifier($_->{TABLE_NAME})
		} $dbh->table_info(undef, $schema, undef, undef);

		foreach my $table (@tables)
		{
			if ($table =~ /^sqlite_/ and $dbh->get_info(17) =~ /sqlite/i)
			{
				next;
			}
			
			$rv->{$table}{columns} ||= [];
			$rv->{$table}{keys}    ||= {};
			$rv->{$table}{refs}    ||= {};
			
			no warnings;
			$rv->{$table}{columns} = [
				sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} }
				rowmap {
					my $type = ($_->{TYPE_NAME} =~ /^char$/i and defined $_->{COLUMN_SIZE})
						? sprintf('%s(%d)', $_->{TYPE_NAME}, $_->{COLUMN_SIZE})
						: $_->{TYPE_NAME};
					+{
						column   => _unquote_identifier($_->{COLUMN_NAME}),
						type     => $type,
						order    => $_->{ORDINAL_POSITION},
						nullable => $_->{NULLABLE},
					}
				}
				$dbh->column_info(undef, $schema, $table, undef)
			];
			
			my $pkey_name;
			my @pkey_cols = 
				map {
					$pkey_name = _unquote_identifier($_->{PK_NAME});
					_unquote_identifier($_->{COLUMN_NAME});
				}
				sort { $a->{KEY_SEQ} <=> $b->{KEY_SEQ} }
				rowmap {
					+{ %$_ };
				}
				$dbh->primary_key_info(undef, $schema, $table, undef);
			
			$rv->{$table}{keys}{$pkey_name} = {
				name    => $pkey_name,
				columns => \@pkey_cols,
				primary => 1,
			} if @pkey_cols;

			my $sth = $dbh->foreign_key_info(undef, $schema, undef, undef, $schema, $table);
			if ($sth)
			{
				my @r;
				while (my $result = $sth->fetchrow_hashref)
				{
					push @r, $result;
				}
				@r = sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @r;
				foreach my $f (@r)
				{
					push @{ $rv->{$table}{refs}{ $f->{FK_NAME} }{columns} }, _unquote_identifier($f->{FK_COLUMN_NAME});
					push @{ $rv->{$table}{refs}{ $f->{FK_NAME} }{target_columns} }, _unquote_identifier($f->{UK_COLUMN_NAME});
					$rv->{$table}{refs}{ $f->{FK_NAME} }{target_table} = _unquote_identifier($f->{UK_TABLE_NAME});
				}
			}
			
			$sth = $dbh->statistics_info(undef, $schema, $table, 1, 0);
			if ($sth)
			{
				my @r;
				while (my $result = $sth->fetchrow_hashref)
				{
					next if $result->{FILTER_CONDITION};
					next if $result->{NON_UNIQUE};
					next if $rv->{$table}{keys}{ _unquote_identifier($result->{INDEX_NAME}) };
					push @r, $result;
				}
				@r = sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @r;
				foreach my $f (@r)
				{
					push @{ $rv->{$table}{keys}{ $f->{INDEX_NAME} }{columns} }, _unquote_identifier($f->{COLUMN_NAME});
					$rv->{$table}{keys}{ $f->{INDEX_NAME} }{name} = _unquote_identifier($f->{INDEX_NAME});
				}
			}
		}

		$self->{layout}{refaddr($dbh).'|'.$schema} = $rv;
	}

	$self->{layout}{refaddr($dbh).'|'.$schema};
}

sub process
{
	my ($self, $dbh, $model) = @_;
	
	$model = RDF::Trine::Model->temporary_model unless defined $model;
	my $callback = (ref $model eq 'CODE')
		? $model
		: sub{ $model->add_statement(@_) };
	my $schema;
	($dbh, $schema) = ref($dbh) eq 'ARRAY' ? @$dbh : ($dbh, undef);

	my $layout = $self->layout($dbh, $schema);
	foreach my $table (keys %$layout)
	{
		$table =~ s/^"(.+)"$/$1/;
		$self->handle_table([$dbh, $schema], $callback, $table);
	}
	
	return $model;
}

sub handle_table
{
	my ($self, $dbh, $model, $table, $where, $cols) = @_;
	return if match $table, $self->ignore_tables;
	
	$model = RDF::Trine::Model->temporary_model unless defined $model;
	my $callback = (ref $model eq 'CODE')?$model:sub{$model->add_statement(@_)};		
	my $schema;
	($dbh, $schema) = ref($dbh) eq 'ARRAY' ? @$dbh : ($dbh, undef);
	$cols = [$cols] if (defined $cols and !ref $cols and length $cols);
	
	my $layout = $self->layout($dbh, $schema);
	
	if (ref $cols eq 'ARRAY')
	{
		my ($pkey) = grep { $_->{primary} } values %{ $layout->{$table}{keys} };
		my %cols   = map { $_ => 1 } (@{ $pkey->{columns} }, @$cols);
		$cols      = join ',', map { $dbh->quote_identifier($_) } sort keys %cols;
	}
	else
	{
		$cols = '*';
	}

	$self->handle_table_rdfs([$dbh, $schema], $callback, $table)
		if ($cols eq '*' and !defined $where);	

	my $sql = $schema
		? sprintf('SELECT %s FROM %s.%s', $cols, $dbh->quote_identifier($schema), $dbh->quote_identifier($table))
		: sprintf('SELECT %s FROM %s', $cols, $dbh->quote_identifier($table));
	
	my @values;
	if ($where)
	{
		my @w;
		while (my ($k,$v) = each %$where)
		{
			push @w, sprintf('%s = ?', $dbh->quote_identifier($k));
			push @values, $v;
		}
		$sql .= ' WHERE ' . (join ' AND ', @w);
	}

	carp($sql) if $self->warn_sql;
	my $sth = $dbh->prepare($sql);
	$sth->execute(@values);
		
	while (my $row = $sth->fetchrow_hashref)
	{
#		use Data::Dumper;
#		print Dumper($layout, $row, $table);
		my ($pkey_uri) =
			map  { $self->make_key_uri($table, $_->{columns}, $row); }
			sort {
				$b->{primary} <=> $a->{primary}
				or $a->{name} cmp $b->{name}
			}
			values %{ $layout->{$table}{keys} };		
		my $subject = $pkey_uri ? iri($pkey_uri) : blank();
		
		# rdf:type
		$callback->(statement($subject, $RDF->type, iri($self->prefix.$table)));
		
		# owl:sameAs
		if ($cols eq '*')
		{
			$callback->(statement($subject, $OWL->sameAs, $_))
				foreach
				grep { not $subject->equal($_) }
				map { iri $_ } # don't combine with previous step, as make_key_uri can return empty list
				map  { $self->make_key_uri($table, $_->{columns}, $row) }
				values %{ $layout->{$table}{keys} };
		}
		
		# p-o for columns
		foreach my $column (@{ $layout->{$table}{columns} })
		{
			next unless defined $row->{ $column->{column} };
			
			my $predicate = iri($self->prefix.$table.'#'.$column->{column});
			my $object    = $self->datatyped_literal(
				$row->{ $column->{column} },
				$column->{type},
				);
			$callback->(statement($subject, $predicate, $object));
		}
		
		# foreign keys
		foreach my $ref (values %{ $layout->{$table}{refs} })
		{
			my $predicate = iri($self->make_ref_uri($table, $ref));
			my $object    = iri($self->make_ref_dest_uri($table, $ref, $row, [$dbh, $schema]));
			$callback->(statement($subject, $predicate, $object));
		}
	}
}

sub handle_table_rdfs
{
	my ($self, $dbh, $model, $table) = @_;
	return if match $table, $self->ignore_tables;
	
	$model = RDF::Trine::Model->temporary_model unless defined $model;
	my $callback = (ref $model eq 'CODE')?$model:sub{$model->add_statement(@_)};		
	my $schema;
	($dbh, $schema) = ref($dbh) eq 'ARRAY' ? @$dbh : ($dbh, undef);

	my $layout = $self->layout($dbh, $schema);

	if ($self->rdfs)
	{
		$callback->(statement(iri($self->prefix.$table), $RDF->type, $OWL->Class));
		$callback->(statement(iri($self->prefix.$table), $RDFS->label, literal($table)));

		foreach my $column (@{ $layout->{$table}{columns} })
		{
			my $predicate = iri($self->prefix.$table.'#'.$column->{column});
			my $dummy     = $self->datatyped_literal('DUMMY', $column->{type});
			my $datatype  = $dummy->has_datatype ? iri($dummy->literal_datatype) : $RDFS->Literal;
			
			$callback->(statement($predicate, $RDF->type, $OWL->DatatypeProperty));
			$callback->(statement($predicate, $RDFS->label, literal($column->{column})));
			$callback->(statement($predicate, $RDFS->domain, iri($self->prefix.$table)));
			$callback->(statement($predicate, $RDFS->range, $datatype)) if $datatype;
		}
		
		foreach my $ref (values %{ $layout->{$table}{refs} })
		{
			my $predicate = iri($self->make_ref_uri($table, $ref));
			$callback->(statement($predicate, $RDF->type, $OWL->ObjectProperty));
			$callback->(statement($predicate, $RDFS->domain, iri($self->prefix.$table)));
			$callback->(statement($predicate, $RDFS->range, iri($self->prefix.$ref->{target_table})));
		}
	}
}

sub process_turtle
{
	my ($self, @args) = @_;
	return $self->SUPER::process_turtle(@args, base_uri=>$self->prefix);
}

sub make_key_uri
{
	my ($self, $table, $columns, $data) = @_;
	
	return if grep { !defined $data->{$_} } @$columns;
	
	return $self->prefix .
		uri_escape_optimistic($table) . "/" .
		(join ';', map
			{ sprintf('%s=%s', uri_escape_optimistic($_), uri_escape_optimistic($data->{$_})); }
			@$columns);
}

sub make_ref_uri
{
	my ($self, $table, $ref) = @_;
	
	return $self->prefix .
		uri_escape_optimistic($table) . "#ref-" .
		(join ';', map
			{ uri_escape_optimistic($_); }
			@{$ref->{columns}});
}

sub make_ref_dest_uri_OLD
{
	my ($self, $table, $ref, $data) = @_;
	
	my $map;
	for (my $i = 0; exists $ref->{columns}[$i]; $i++)
	{
		$map->{ $ref->{target_columns}[$i] } = $ref->{columns}[$i];
	}
	
	return $self->prefix .
		uri_escape_optimistic($ref->{target_table}) . "/" .
		(join ';', map
			{ sprintf('%s=%s', uri_escape_optimistic($_), uri_escape_optimistic($data->{$map->{$_}})); }
			@{$ref->{target_columns}});
}

sub make_ref_dest_uri
{
	my ($self, $table, $ref, $data, $dbh) = @_;
	
	my $schema;
	($dbh, $schema) = @$dbh if ref $dbh eq 'ARRAY';
	my $layout = $self->layout($dbh, $schema);

	my %cols =
		map { $_ => 1 }
		map { @{ $_->{columns} } }
		values %{ $layout->{ $ref->{target_table} }{keys} };	
	my $cols =
		join q[, ],
		map { $dbh->quote_identifier($_) }
		sort keys %cols;
	my $sql = $schema
		? sprintf('SELECT %s FROM %s.%s', $cols, $dbh->quote_identifier($schema), $dbh->quote_identifier($ref->{target_table}))
		: sprintf('SELECT %s FROM %s', $cols, $dbh->quote_identifier($ref->{target_table}));
	
	my @values;
	my @where;
	foreach my $i (0 .. @{$ref->{target_columns}}-1)
	{
		if (defined $data->{  $ref->{columns}[$i]  })
		{
			push @where, sprintf('%s = ?', $dbh->quote_identifier($ref->{target_columns}[$i]));
			push @values, $data->{  $ref->{columns}[$i]  };
		}
		else
		{
			push @where, sprintf('%s IS NULL', $dbh->quote_identifier($ref->{target_columns}[$i]));
		}
	}
	$sql .= ' WHERE ' . (join ' AND ', @where);

	carp($sql) if $self->warn_sql;
	my $sth = $dbh->prepare($sql);
	$sth->execute(@values);

	if (my $row = $sth->fetchrow_hashref)
	{
		my ($pkey_uri) =
			map  { $self->make_key_uri($ref->{target_table}, $_->{columns}, $row); }
			sort {
				$b->{primary} <=> $a->{primary}
				or $a->{name} cmp $b->{name}
			}
			values %{ $layout->{$ref->{target_table}}{keys} };
		
		return $pkey_uri if $pkey_uri;
	}

	$self->make_ref_dest_uri_OLD($table, $ref, $data);
}

1;

__END__

=encoding utf8

=head1 NAME

RDF::RDB2RDF::DirectMapping - map relational database to RDF directly

=head1 SYNOPSIS

 my $mapper = RDF::RDB2RDF->new('DirectMapping',
   prefix => 'http://example.net/data/');
 print $mapper->process_turtle($dbh);

=head1 DESCRIPTION

This module makes it stupidly easy to dump a relational SQL database as
an RDF graph, but at the cost of flexibility. Other than providing a base
prefix for class, property and instance URIs, all mapping is done automatically,
with very little other configuration at all.

This class offers support for the W3C Direct Mapping, based on the 29 May 2012
working draft.

=head2 Constructor

=over 

=item * C<< RDF::RDB2RDF::DirectMapping->new([prefix => $prefix_uri] [, %opts]) >>

=item * C<< RDF::RDB2RDF->new('DirectMapping' [, prefix => $prefix_uri] [, %opts]) >>

=back

The prefix defaults to the empty string - i.e. relative URIs.

Three extra options are supported: C<rdfs> which controls whether extra Tbox
statements are included in the mapping; C<warn_sql> carps statements to
STDERR whenever the database is queried (useful for debugging);
C<ignore_tables> specifies tables to ignore (L<match::simple> is used, so the
value of ignore_tables can be a string, regexp, coderef, or an arrayref
of all of the above).

=head2 Methods

=over

=item * C<< process($source [, $destination]) >>

Given a database handle, produces RDF data. Can optionally be passed a
destination for triples: either an existing model to add data to, or a
reference to a callback function.

$source can be a DBI database handle, or an arrayref pair of a handle plus
a schema name.

  $destination = sub {
    print $_[0]->as_string . "\n";
  };
  $dbh    = DBI->connect('dbi:Pg:dbname=mytest');
  $schema = 'fred';
  $mapper->process([$dbh, $schema], $destination);

Returns the destination.

=item * C<< process_turtle($dbh, %options) >>

As per C<process>, but returns a string in Turtle format.

Returns a string.

=item * C<< handle_table($source, $destination, $table, [\%where], [\@cols]) >>

As per C<process> but must always be passed an explicit destination (doesn't
return anything useful), and only processes a single table.

If %where is provided, selects only certain rows from the table. Hash keys
are column names, hash values are column values.

If @cols is provided, selects only particular columns. (The primary key columns
will always be selected.)

This method allows you to generate predictable subsets of the mapping output.
It's used fairly extensively by L<RDF::RDB2RDF::DirectMapping::Store>.

=item * C<< handle_table_sql($source, $destination, $table) >>

As per C<handle_table> but only generates the RDFS/OWL schema data. Note that
C<handle_table> already includes this data (unless %where or @cols was passed
to it).

If the C<rdfs> option passed to the constructor was not true, then there will
be no RDFS/OWL schema data generated.

=back

=head1 COMPLIANCE AND COMPATIBILITY

This implementation should be mostly compliant with the Direct Mapping
specification, with the following provisos:

=over

=item * RDF::RDB2RDF::DirectMapping assigns URIs to some nodes that
would be blank nodes per the specification. That is, it Skolemizes.

=back

Other quirks are database-specific:

=over

=item * SQLite does not support foreign key constraints by default;
they need to be explicitly enabled. This can be achieved using:

 $dbh->do('PRAGMA foreign_keys = ON;');

But even once foreign keys are enabled, L<DBD::SQLite> does not report
foreign key constraints, so this module can't generate any triples
based on that information.

=item * DBD::SQLite does not correctly report primary key columns
if the name of the column contains whitespace.

=item * PostgreSQL databases are not usually UTF-8 by default. This
module may not work correctly with non-UTF-8 databases, though using
an ASCII-compatible subset of other encodings (such as ISO-8859-15)
should be fine. If using UTF-8, you may need to do:

 $dbh->{pg_enable_utf8} = 1;

=item * Different databases support different SQL datatypes. This module
attempts to map them to their XSD equivalents, but may not recognise
some exotic ones.

=item * This module has only been extensively tested on SQLite 3.6.23.1
and PostgreSQL 8.4.4. I know of no reason it shouldn't work with other
relational database engines, provided they are supported by DBI, but as
with all things SQL, I wouldn't be surprised if there were one or two
problems. Patches welcome.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF>.

=head1 SEE ALSO

L<RDF::Trine>, L<RDF::RDB2RDF>, L<RDF::RDB2RDF::DirectMapping::Store>.

L<http://www.perlrdf.org/>.

L<http://www.w3.org/TR/2012/WD-rdb-direct-mapping-20120529/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2013 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

