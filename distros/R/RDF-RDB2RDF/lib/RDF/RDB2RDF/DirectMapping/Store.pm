package RDF::RDB2RDF::DirectMapping::Store;

use 5.010;
use strict;
use utf8;

use Carp qw[];
use DBI;
use RDF::Trine;
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use Scalar::Util qw[blessed];
use URI::Escape qw[uri_escape uri_unescape];
use match::simple qw[match];

use namespace::clean;
use base qw[
	RDF::Trine::Store
	RDF::RDB2RDF::DirectMapping::Store::Mixin::SuperGetPattern
];

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

sub new
{
	my $class   = shift;
	my $dbh     = shift;
	my $mapping = shift;
	my %options = ref($_[0]) ? %{ +shift } : @_;
	
	my $schema;
	if (ref $dbh eq 'ARRAY')
	{
		($dbh, $schema) = @$dbh;
	}
	
	my $layout = $mapping->layout($dbh, $schema);
	foreach my $table (keys %$layout)
	{
		unless ($layout->{$table}{keys}
		and grep { $_->{primary} } values %{$layout->{$table}{keys}})
		{
			Carp::croak("Table $table lacks a primary key.");
		}
	}
	
	bless {
		dbh      => $dbh,
		schema   => $schema,
		mapping  => $mapping,
		options  => \%options,
		}, $class;
}

sub _new_with_config
{
	my ($class, $config) = @_;
	$config = +{ %$config }; # shallow clone
	
	my $dbh = DBI->connect(
		(delete($config->{dsn})      // do { Carp::croak "Need dsn!" }),
		(delete($config->{username}) // undef),
		(delete($config->{password}) // undef),
	);
	$dbh = [
		$dbh,
		delete($config->{schema}),
	] if exists $config->{schema};
	my $mapping = RDF::RDB2RDF::DirectMapping->new(
		%$config,
	);
	return $class->new($dbh, $mapping, $config);
}

sub dbh     :lvalue { $_[0]->{dbh} }
sub schema  :lvalue { $_[0]->{schema} }
sub mapping :lvalue { $_[0]->{mapping} }
sub options :lvalue { $_[0]->{options} }

sub get_pattern
{
	my $self = shift;
	my ($pattern, $context) = @_;
	
	my $NULL = RDF::Trine::Iterator::Bindings->new();
	return $NULL if blessed($context) && !$context->is_variable;
	
	if (scalar $pattern->triples > 1)
	{
		my %subjects = map { $_->subject->as_string => $_->subject } $pattern->triples;
		
		# optimise cases where all subjects are the same
		if (scalar keys %subjects==1)
		{
			my $layout = $self->mapping->layout($self->dbh, $self->schema);
			my ($subject) = values %subjects;
			my ($table, $where) = (undef, {});
				
			if ($subject->is_resource)
			{
				my ($s_prefix, $s_table, $s_divider, $s_bit) = $self->split_uri($subject);
				
				if (defined $s_prefix and defined $s_table and $s_divider eq '/' and defined $s_bit)
				{
					$table = $s_table;
					$where = $self->_handle_bit($table, $s_bit);
				}
			}
			else
			{
				foreach my $st ($pattern->triples)
				{
					return $NULL if $st->object->is_literal and $st->object->has_language;
					
					next unless $st->predicate->is_resource;
					my ($p_prefix, $p_table, $p_divider, $p_bit) = $self->split_uri($st->predicate);

					if (defined $p_prefix and defined $p_table and $p_divider eq '#' and defined $p_bit)
					{
						$table = $p_table unless defined $table;
						return $NULL unless $p_table eq $table;
						
						my ($column) =
							grep { $p_bit eq $_->{column} }
							@{$layout->{$table}{columns}};
						return $NULL unless $column;
						
						if ($st->object->is_literal)
						{
							$where->{ $column->{column} } = $st->object->literal_value;
						}
					}
				}
			}
			
			#use Data::Dumper;
			#warn "Can optimise using....\n".Dumper($table,$where);
			
			my $model = RDF::Trine::Model->temporary_model;
			$self->mapping->handle_table([$self->dbh, $self->schema], $model, $table, $where);
			return $model->get_pattern(@_);
		}
	}
	
	return $self->_SUPER_get_pattern(@_);
}

sub get_statements
{
	my ($self, $s, $p, $o, $g) = @_;
	
	$s = undef if blessed($s) && $s->is_variable;
	$p = undef if blessed($p) && $p->is_variable;
	$o = undef if blessed($o) && $o->is_variable;
	$g = undef if blessed($g) && $g->is_variable;

	my $NULL = RDF::Trine::Iterator::Graph->new();
	return $NULL if $g;
	
	my @results;
	my $check = RDF::Trine::Statement->new(
		$s || RDF::Trine::Node::Variable->new('s'),
		$p || RDF::Trine::Node::Variable->new('p'),
		$o || RDF::Trine::Node::Variable->new('o'),
		);
	my $callback = sub {
		return unless $check->subsumes($_[0]);
		push @results, $_[0];
	};	

	my $layout = $self->mapping->layout($self->dbh, $self->schema);
	my ($s_prefix, $s_table, $s_divider, $s_bit) = $self->split_uri($s);
	my ($p_prefix, $p_table, $p_divider, $p_bit) = $self->split_uri($p);
	
	my $table = undef;
	my $where = {};
	my $columns = undef;
	
	if ($self->mapping->rdfs)
	{
		my $special_namespace = '^' . join '|',
			map { quotemeta($_->uri) } ($RDF, $RDFS, $OWL, $XSD);

		my $check_rdfs = undef;

		if (blessed($p) and $p->uri =~ /$special_namespace/)
		{
			my ($o_prefix, $o_table, $o_divider);
			($o_prefix, $o_table, $o_divider) = $self->split_uri($o)
				if blessed($o) && $o->is_resource;
				
			unless ($p->equal($RDF->type) and $o_prefix)
			{
				if ($s_table)
				{
					$check_rdfs = $s_table;
				}
				elsif (!defined $s)
				{
					$check_rdfs = '*';
				}
			}
		}
		elsif (blessed($s) and $s_divider ne '/')
		{
			$check_rdfs = $s_table;
		}
		
		if ($check_rdfs eq '*')
		{
			$self->mapping->handle_table_rdfs([$self->dbh, $self->schema], $callback, $_)
				foreach keys %$layout;
			return RDF::Trine::Iterator::Graph->new(\@results);
		}
		elsif (defined $check_rdfs and defined $layout->{$check_rdfs})
		{
			$self->mapping->handle_table_rdfs([$self->dbh, $self->schema], $callback, $check_rdfs);
			return RDF::Trine::Iterator::Graph->new(\@results);
		}
	}
	
	# All subject URIs will be prefixed
	if (defined $s and !$s_prefix)
	{
		return $NULL;
	}

	if ($p_prefix)
	{
		$table = $p_table;
		return $NULL unless defined $layout->{$table};
			
		# Properties need to be the right type of URI
		return $NULL
			unless $p_divider eq '#';
			
		# TODO: better handling for "ref=".
		if ($p_bit =~ /^ref=/)
		{
			return $NULL if blessed($o) && $o->is_literal;
		}
		else
		{
			# Column needs to exist
			my ($column) =
				grep { $p_bit eq $_->{column} }
				@{$layout->{$table}{columns}};
			return $NULL unless $column;
			$columns = [$column->{column}];
			
			if (blessed($o))
			{
				return $NULL unless $o->is_literal;
				return $NULL if $o->has_language;

				$where->{ $column->{column} } = $o->literal_value;
			}
		}
	}
	elsif (blessed($p) and $p->equal($RDF->type))
	{
		my ($o_prefix, $o_table, $o_divider) = $self->split_uri($o);
		return $NULL unless $o_prefix;
		return $NULL if $o_divider;
		
		$table = $o_table;
		$columns = [];
	}
	elsif (blessed($p) and $p->equal($OWL->sameAs))
	{
		my ($o_prefix, $o_table, $o_divider) = $self->split_uri($o);
		return $NULL unless $o_prefix;
		return $NULL unless $o_divider eq '/';
		return $NULL if defined $s_table && $o_table ne $s_table;
		
		$table = $o_table;
	}

	if ($s_prefix)
	{
		# Individuals and properties will always belong to the same table
		return $NULL
			if defined $table && $s_table ne $table;

		$table ||= $s_table;
		return $NULL unless defined $layout->{$table};

		# Individuals need to be the right type of URI
		return $NULL
			unless $s_divider eq '/';

		# Needs to be some conditions to identify the individual.
		my $conditions = $self->_handle_bit($table, $s_bit);
		return $NULL unless $conditions;

		# Add conditions to $where
		while (my ($k, $v) = each %$conditions)
		{
			# Conflicting conditions
			if (defined $where->{$k} and $where->{$k} ne $v)
			{
				return $NULL;
			}
			$where->{$k} = $v;
		}
	}

	$where = undef unless keys %$where;
	
	if ($table)
	{
		#use Data::Dumper;
		#warn ("Saved Time!\n".Dumper($table , $where));
		$self->mapping->handle_table([$self->dbh, $self->schema], $callback, $table, $where, $columns);
	}
	else
	{
		$self->mapping->process([$self->dbh, $self->schema], $callback);
	}
	
	return RDF::Trine::Iterator::Graph->new(\@results);
}

sub _handle_bit
{
	my ($self, $table, $bit) = @_;
	
	my $layout = $self->mapping->layout($self->dbh, $self->schema);	
	my ($pkey) = grep { $_->{primary} } values %{$layout->{$table}{keys}};
	
	my $regex   =
		join '\;',
		map { sprintf('%s=(.*)', quotemeta(_uri_escape($_))) }
		@{$pkey->{columns}};
	
#	warn "'$bit' =~ /$regex/";
	
	if (my @values = ($bit =~ /^ $regex $/x))
	{
		my $r = {};
		for (my $i=0; exists $values[$i]; $i++)
		{
			$r->{ $pkey->{columns}[$i] } = uri_unescape($values[$i]);
		}
		return $r;
	}
	
	return;
}

sub _uri_escape
{
	my $s = uri_escape(shift);
	$s =~ s/\+/%20/g;
	$s;
}

sub split_uri
{
	my ($self, $uri) = @_;
	return unless $uri;
	$uri = $uri->uri if blessed($uri);
	
	my $prefix = $self->mapping->prefix;
	if ($uri =~ m!^ (\Q$prefix\E)  # prefix
	                ([^#/]+)         # table name
	                (?:              # optionally...
	                  ([#/])         #   URI divider
	                  (.+)           #   other bit
	                )? $!x)
	{
		return ($1, $2, $3, $4);
	}
	
	return;
}

sub get_contexts
{
	return RDF::Trine::Iterator->new();
}

sub count_statements
{
	my $self  = shift;
	my $iter  = $self->get_statements(@_);
	my $count = 0;
	while (my $st = $iter->next)
	{
		$count++;
	}
	return $count;
}

sub add_statement
{
	my ($self, $st, $ctxt, $opt) = @_;
	
	my %merged = (
		%{ $self->options },
		%$opt,
	);	
	local $self->{options} = \%merged;
	
	if ($ctxt or $st->can('context') && $st->context)
	{
		$self->_carp(
			add => $st,
			"this store does not accept quads; treating as a triple",
			);
	}
	
	my $already = $self->get_statements(
		$st->subject,
		$st->predicate,
		$st->object,
	);
	return if $already->next;

	return $self->_croak(
		add => $st,
		"contains blank node",
		) if grep { $_->is_blank } (
			$st->subject,
			$st->predicate,
			$st->object,
		);

	my ($s_prefix, $s_table, $s_divider, $s_bit) = $self->split_uri($st->subject);
	my ($p_prefix, $p_table, $p_divider, $p_bit) = $self->split_uri($st->predicate);

	return $self->_croak(
		add => $st,
		"subject and predicate are not contained within this database according to mapping",
		)
		unless defined $s_prefix
		&&     defined $p_prefix
		&&     $s_prefix eq $p_prefix;
	
	return $self->_croak(
		add => $st,
		"subject and predicate not from matching tables",
		)
		unless defined $s_table
		&&     defined $p_table
		&&     $s_table eq $p_table;
		
	return $self->_croak(
		add => $st,
		"table $s_table is ignored by mapping",
		)
		if match $s_table, $self->mapping->ignore_tables;
	
	return $self->_croak(
		add => $st,
		"subject not a 'slash URI'",
		)
		unless defined $s_divider
		&&     $s_divider eq '/';

	return $self->_croak(
		add => $st,
		"predicate not a 'hash URI'",
		)
		unless defined $p_divider
		&&     $p_divider eq '#';

	if ($st->object->is_literal)
	{
		return $self->_croak(
			add => $st,
			"predicate has non-literal range, but object is literal",
			)
			if defined $p_bit
			&& $p_bit =~ /^ref=/;
		
		return $self->_carp(
			add => $st,
			"literal language ignored",
			)
			if $st->object->has_language;
		
		my $table  = $self->schema ? sprintf('%s.%s', $self->schema, $p_table) : $p_table ;
		my $index  = $self->_handle_bit($s_table, $s_bit);
		my $column = $p_bit;
		my $value  = $st->object->literal_value;
		my $layout = $self->mapping->layout($self->dbh, $self->schema);
		
		return $self->_croak(
			add => $st,
			"table $table has no column $column",
			)
			unless grep { $_->{column} eq $column }
			            @{ $layout->{$table}{columns} };
		
		my $sth = $self->dbh->prepare(sprintf(
			'SELECT CASE WHEN %s IS NULL THEN 1 ELSE 2 END AS x FROM %s WHERE %s',
			$column,
			$table,
			join(q[ AND ] => map { "$_=?" } sort keys %$index)
		));
		$sth->execute(map { $index->{$_} } sort keys %$index);

		if (my($r) = $sth->fetchrow_array)
		{
			if ($r==2
			and defined $self->options->{overwrite}
			and not $self->options->{overwrite})
			{
				return $self->_carp(
					add => $st,
					"will not overwrite existing value",
					);
			}
			
			my $sth = $self->dbh->prepare(sprintf(
				'UPDATE %s SET %s=? WHERE %s',
				$table,
				$column,
				join(q[ AND ] => map { "$_=?" } sort keys %$index)
			));
			$sth->execute($value, map { $index->{$_} } sort keys %$index)
				or $self->_croak(add => $st, "could not UPDATE database");
			return;
		}
		else
		{
			my $sth = $self->dbh->prepare(sprintf(
				'INSERT INTO %s (%s, %s) VALUES (?, %s)',
				$table,
				$column,
				join(q[, ] => sort keys %$index),
				join(q[, ] => map { ;'?' } keys %$index),
			));
			$sth->execute($value, map { $index->{$_} } sort keys %$index)
				or $self->_croak(add => $st, "could not INSERT into database");
			return;
		}
	}
	else
	{
		return $self->_croak(
			add => $st,
			"predicate has literal range, but non-literal value",
			)
			if defined $p_bit
			&& $p_bit !~ /^ref=/;
		
		return $self->_croak(
			add => $st,
			"non-literal objects not implemented yet",
			);
	}
}

sub remove_statement
{
	my ($self, $st, $ctxt, $opt) = @_;
	
	my %merged = (
		%{ $self->options },
		%$opt,
	);	
	local $self->{options} = \%merged;
	
	if ($ctxt or $st->can('context') && $st->context)
	{
		$self->_carp(
			remove => $st,
			"this store does not accept quads; treating as a triple",
			);
	}
	
	my $already = $self->get_statements(
		$st->subject,
		$st->predicate,
		$st->object,
	);
	return unless $already->next;

	my ($s_prefix, $s_table, $s_divider, $s_bit) = $self->split_uri($st->subject);
	my ($p_prefix, $p_table, $p_divider, $p_bit) = $self->split_uri($st->predicate);

	return $self->_croak(
		remove => $st,
		"subject and predicate not from matching tables",
		)
		unless defined $s_table
		&&     defined $p_table
		&&     $s_table eq $p_table;
		
	return $self->_croak(
		remove => $st,
		"table $s_table is ignored by mapping",
		)
		if match $s_table, $self->mapping->ignore_tables;
	
	if ($st->object->is_literal)
	{
		my $table  = $self->schema ? sprintf('%s.%s', $self->schema, $p_table) : $p_table ;
		my $index  = $self->_handle_bit($s_table, $s_bit);
		my $column = $p_bit;
		my $value  = $st->object->literal_value;
		my $layout = $self->mapping->layout($self->dbh, $self->schema);
		
		if (exists $index->{$column})
		{
			return $self->_croak(
				remove => $st,
				"column $column is part of table primary key",
				);
		}
		
		my $sth = $self->dbh->prepare(sprintf(
			'UPDATE %s SET %s=NULL WHERE %s=? AND %s',
			$table,
			$column,
			$column,
			join(q[ AND ] => map { "$_=?" } sort keys %$index)
		));
		$sth->execute($value, map { $index->{$_} } sort keys %$index)
			or $self->_croak(remove => $st, "could not UPDATE database");
		return;
	}
	else
	{
		return $self->_croak(
			remove => $st,
			"non-literal objects not implemented yet",
			);
	}	
}

sub remove_statements
{
	my $self = shift;
	my ($s, $p, $o) = @_;
	
	# catch the special case of 
	# $store->remove_statements($s, undef, undef)
	# and use it to delete an entire row from the table
	if ($s and !$p and !$o and $s->is_resource)
	{
		my ($s_prefix, $s_table, $s_divider, $s_bit) = $self->split_uri($s);
		
		# for error messages
		my $st = sub {
			RDF::Trine::Statement->new(
				$s,
				RDF::Trine::Node::Variable->new('any_predicate'),
				RDF::Trine::Node::Variable->new('any_object'),
			)
		};
		
		return $self->_croak(
			remove => $st,
			"subject not contained within this database according to mapping",
			)
			unless defined $s_prefix;
		
		return $self->_croak(
			remove => $st->(),
			"table $s_table is ignored by mapping",
			)
			if match $s_table, $self->mapping->ignore_tables;
		
		my $table  = $self->schema ? sprintf('%s.%s', $self->schema, $s_table) : $s_table ;
		my $index  = $self->_handle_bit($s_table, $s_bit);
		my $layout = $self->mapping->layout($self->dbh, $self->schema);
		
		my $sth = $self->dbh->prepare(sprintf(
			'DELETE FROM %s WHERE %s',
			$table,
			join(q[ AND ] => map { "$_=?" } sort keys %$index)
		));
		$sth->execute(map { $index->{$_} } sort keys %$index)
			or $self->_croak(remove => $st->(), "could not DELETE FROM database");
		return;
	}
	
	my $iter = $self->get_statements(@_);
	while (my $st = $iter->next)
	{
		$self->remove_statement($st);
	}
}

sub _carp
{
	my ($self, $method, $st, $message) = @_;
	
	if (exists $self->options->{on_carp})
	{
		$self->options->{on_carp}->(@_)
			if ref $self->options->{on_carp} eq 'CODE';
	}
	else
	{
		Carp::carp(sprintf("Warning for %s %s: %s", $method, $st->sse, $message));
	}
}

sub _croak
{
	my ($self, $method, $st, $message) = @_;
	
	if (exists $self->options->{on_croak})
	{
		$self->options->{on_croak}->(@_)
			if ref $self->options->{on_croak} eq 'CODE';
	}
	else
	{
		Carp::croak(sprintf("Cannot %s %s: %s", $method, $st->sse, $message));
	}
}

1;

__END__

=encoding utf8

=head1 NAME

RDF::RDB2RDF::DirectMapping::Store - mapping-fu

=head1 SYNOPSIS

 my $mapper = RDF::RDB2RDF->new('DirectMapping',
   prefix => 'http://example.net/data/');
 my $store  = RDF::RDB2RDF::DirectMapping::Store->new($dbh, $mapper, %options);

=head1 DESCRIPTION

This is pretty experimental. It provides a L<RDF::Trine::Store>
based on a database handle and a  L<RDF::RDB2RDF::DirectMapping>
map.

Some queries are super-optimised; others are somewhat slower.

=head2 A Read-Write Adventure!

As of 0.006, there is very experimental support for C<add_statement>,
C<remove_statement> and C<remove_statements>.

Because data is stored in the database in a relational manner
rather than as triples, some statements cannot be added to the
database because they don't fit within the database's existing
set of relations (i.e. tables). These will croak, but you can
customise the failure (e.g. ignore it) using a callback:

 my %opts = (
   on_croak => sub {
     my ($store, $action, $st, $reason) = @_;
     my $dbh     = $store->dbh;
     my $mapping = $store->mapping;
     # do stuff here
   },
 );
 $store->add_statement($st, $ctxt, \%opts);

The on_croak option can alternatively be passed to the constructor.

Generally speaking, if the C<add_statement> or C<remove_statement>
methods fail, the database has probably been left unchanged. (But
there are no guarantees - the database may have, say, a trigger
set up which fires on SELECT.)

Certain statements will also generate a warning. These warnings
can be silenced by setting an C<on_carp> callback similarly.

Again because of the relational nature of the storage, many
statements will be mutually exclusive. That is, adding one
statement may automatically negate an existing statement (i.e.
cause it to be removed). You may set the C<overwrite> option
to a false-but-defined value to prevent this happening.

 $store->add_statement($st, $ctxt, { overwrite => 0 });

Literal datatypes are essentially ignored when adding a
statement because the mapping uses SQL datatypes to decide on
RDF datatypes. Languages tags for plain literals will
give a warning (which can be handled with C<on_carp>) but
will otherwise be ignored. When removing a statement, the
datatype will not be ignored, because before the statement
is removed, the store checks that the exact statement exists
in the store.

C<remove_statement> fails if it would alter part of the primary
key for a table, but C<add_statement> can alter part of the
primary key.

In many RDF stores, the C<remove_statements> method is a logical
shortcut for calling C<get_statement> and then looping through
the results, removing each one from the store. (Though probably
optimized.)

In this store though, C<remove_statements> may succeed when
individual calls to C<remove_statement> would have succeeded.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF>.

=head1 SEE ALSO

L<RDF::Trine>, L<RDF::RDB2RDF>, L<RDF::RDB2RDF::DirectMapping>, L<RDF::Trine::Store>.

L<http://perlrdf.org/>.

L<http://www.w3.org/TR/2012/WD-rdb-direct-mapping-20120529/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2013 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

