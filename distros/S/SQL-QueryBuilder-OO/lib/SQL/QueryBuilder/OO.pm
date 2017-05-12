package SQL::QueryBuilder::OO;

use 5.010;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.2.6';
##------------------------------------------------------------------------------
package sqlQuery;

use strict;
use warnings;
use overload '""' => '_getInterpolatedQuery';

use Data::Dumper; # vital
use Carp qw(croak cluck);
use Scalar::Util qw(blessed looks_like_number);
use Params::Validate qw(:all);

$sqlQuery::DBI = undef;
%sqlQuery::PARAMS = ();
$sqlQuery::PARAMETER_PLACEHOLDER = '?';

sub setup
	{
		my %params = validate @_, {
			-dbh => {isa => 'DBI::db', default => undef},
			-connect => {type => CODEREF, default => undef}
		};

		if (defined $params{'-dbh'} && defined $params{'-connect'})
			{
				croak('Make up your mind: either use "-dbh" to pass a handle or "-connect" for ad-hoc connecting');
			}

		%sqlQuery::PARAMS = %params;

		return 1
	}

sub dbh
	{
		unless (defined $sqlQuery::DBI) {
			if (defined $sqlQuery::PARAMS{'-dbh'}) {
				$sqlQuery::DBI = $sqlQuery::PARAMS{'-dbh'};
			} elsif (defined $sqlQuery::PARAMS{'-connect'}) {
				$sqlQuery::DBI = eval {$sqlQuery::PARAMS{'-connect'}->()};
				croak 'Setup failed; ad-hoc connector died: '.$@ if $@;
			} else {
				croak 'sqlQuery is not setup, yet.';
			}
		}

		return $sqlQuery::DBI
	}

sub q
	{
		local $Carp::CarpLevel = $Carp::CarpLevel + 2; ## no critic
		return __PACKAGE__->new(@_);
	}

sub exec
	{
		my $sql = shift;
		my $q = __PACKAGE__->new($sql);
		my $rows = $q->execute(@_);
		if (blessed($rows) && $rows->isa('sqlQueryResult')) {
			cluck('Discarded query with results');
			$rows = undef;
		}

		undef $q;
		return $rows
	}

sub foundRows
	{
		my $res = __PACKAGE__->new(q(SELECT FOUND_ROWS()))->execute;
		my $rows = $res->fetchColumn(0);
		$res->freeResource();

		return $rows
	}

sub getLastInsertId
	{
		return $sqlQuery::DBI->last_insert_id(undef, undef, undef, undef);
	}

sub new
	{
		my $class = ref $_[0] ? ref shift : shift;
		my $sql = shift;
		my $self = {-sql => undef, -params => undef, -named => 0};

		unless (blessed($sql)) {
			croak 'Not a scalar argument; query must either be a string or an instance of "sqlSelectAssemble"'
				if !defined $sql || ref $sql || looks_like_number $sql;
		} else {
			croak sprintf 'Parameter is not an instance of "sqlSelectAssemble" (got "%s")', ref $sql
				unless $sql->isa('sqlSelectAssemble');
			$self->{'-params'} = undef
		}

		$self->{'-sql'} = $sql;
		return bless $self, $class
	}

sub debugQuery
	{
		my $self = shift;
		my $sql = "$self->{-sql}";

		$sql =~ s/(?:\r?\n)+$//;
		print "$sql\n";

		if (@_) {
			$self->_populateParameters(@_);
		} elsif (blessed $self->{'-sql'}) {
			$self->_populateParameters($self->{'-sql'}->gatherBoundArgs());
		}

		if (defined $self->{'-params'}) {
			printf "%s\n%s\n%s\n", ('-'x80), Dumper($self->{'-params'}), ('-'x80);
			$self->_interpolateQuery();
			printf "%s\n", $self->{'-interpolated-query'};
		}

		return
	}

sub execute
	{
		my $self = shift;

		if (@_) {
			$self->_populateParameters(@_);
		} elsif (blessed $self->{'-sql'}) {
			$self->_populateParameters($self->{'-sql'}->gatherBoundArgs());
		}

		$self->_interpolateQuery();

		my $res = eval {$self->_query($self->{'-interpolated-query'})};
		$self->{'-params'} = undef;
		croak $@ if $@;

		return $res
	}

sub setParameters
	{
		my $self = shift;
		$self->_populateParameters(@_);
		return $self
	}

sub _getInterpolatedQuery
	{
		my $self = shift;
		$self->_interpolateQuery();
		return $self->{'-interpolated-query'}
	}

sub _populateParameters
	{
		my $self = shift;

		if (defined $self->{'-params'}) {
			local $Carp::CarpLevel = $Carp::CarpLevel + 2; ## no critic
			croak 'Query parameters are already populated'
		}

		if (1 == scalar @_ && 'HASH' eq ref $_[0]) {
			$self->{'-named'} = 1;
			$self->{'-params'} = shift;
			foreach my $p (keys %{$self->{'-params'}}) {
				$self->{'-params'}->{$p} = _convertArgument($self->{'-params'}->{$p});
				croak "Argument '$p' could not be converted"
					unless defined $self->{'-params'}->{$p};
			}
		} else {
			foreach (@_) {
				croak 'Mixed named and positional parameters are unsupported'
					if 'HASH' eq ref $_;
			}

			$self->{'-named'} = 0;
			$self->{'-params'} = [@_];

			foreach my $index (0..$#_) {
				$self->{'-params'}->[$index] = _convertArgument($self->{'-params'}->[$index]);
				croak "Argument at index '$index' could not be converted"
					unless defined $self->{'-params'}->[$index];
			}
		}

		return
	}

sub _interpolateQuery
	{
		my $self = shift;

		if ($self->{'-named'}) {
			$self->_interpolateByName();
		} else {
			$self->_interpolateByIndex();
		}

		return $self->_checkLeftoverParameters();
	}

sub _interpolateByIndex
	{
		my $self = shift;
		my $sql = "$self->{-sql}";
		my $pos = 0;

		while (1) {
			last if $pos >= length($sql) || 0 > ($pos = index $sql, $sqlQuery::PARAMETER_PLACEHOLDER, $pos);

			my $param = eval{$self->_fetchParameter()};
			croak "$@: interpolated so far: $sql" if $@;
			my $value = "$param";

			$sql =
				(0 < $pos ? substr($sql, 0, $pos) : '') .
				$value .
				(substr $sql, $pos + 1);
			$pos += length $value;
		}

		$self->{'-interpolated-query'} = $sql;

		return
	}

sub _interpolateByName
	{
		my $self = shift;
		my $sql = "$self->{-sql}";
		my $pos = 0;

		while(1) {
			last if $pos >= length($sql) || 0 > ($pos = index $sql, q(:), $pos);

			my ($name) = (substr $sql, $pos) =~ m/^:([[:lower:][:upper:]_\d-]+)/;
			my $param = eval{$self->_fetchParameter($name)};
			croak "$@: interpolated so far: $sql" if $@;
			my $value = "$param";

			$sql = (0 < $pos ? substr($sql, 0, $pos) : '') .
				$value .
				(substr $sql, $pos + 1 + length $name);
			$pos += length $value;
		}

		$self->{'-interpolated-query'} = $sql;

		return
	}

sub _fetchParameter
	{
		my $self = shift;
		my $name = shift;

		if (defined $name) {
			if (!exists($self->{'-params'}->{$name})) {
				croak sprintf 'No such query parameter "%s"', $name;
			}
			return $self->{'-params'}->{$name};
		} else {
			unless (ref $self->{'-params'} && @{$self->{'-params'}}) {
				croak 'Too few query parameters provided';
			}
		}

		return shift @{$self->{'-params'}};
	}

sub _checkLeftoverParameters
	{
		my $self = shift;

		if ('ARRAY' eq ref $self->{'-params'} && @{$self->{'-params'}}) {
			croak 'Too many query parameters provided';
		}

		return
	}

sub _query
	{
		my $self = shift;
		my $sql = shift;
		my $dbh = sqlQuery::dbh();
		my $error;

		EXECUTE: {
			if ($sql !~ m/^select/i) {
				local $dbh->{RaiseError} = 1;
				local $dbh->{PrintError} = 0;
				my $rows;
				eval{$dbh->do($sql); 1} or do {
					$error = $@;
					last EXECUTE;
				};
				return $rows;
			}

			$self->{'-sth'} = $dbh->prepare($sql);

			local $self->{'-sth'}->{RaiseError} = 1;
			local $self->{'-sth'}->{PrintError} = 0;
			eval {$self->{'-sth'}->execute; 1} or do {
				$error = $@;
				last EXECUTE;
			};
			return sqlQueryResult->new($self, $self->{'-sth'});
		}

		my $file = __FILE__;

		$self->{'-sth'} = undef;

		$error =~ s/\s+at $file line \d+[.]\r?\n//;
		$error =~ s/\s*at line \d$//;
		$sql =~ s/(?:\r?\n)+$//;
		croak "$error\n\n<<SQL\n$sql\nSQL\n\nCalled";
	}

sub quoteTable
	{
		my $table = shift;

		if (ref $table)
			{
				my ($k,$v);
				($k) = keys %$table;
				($v) = values %$table;
				return sprintf '%s AS %s', sqlQuery::quoteTable($k), sqlQuery::quoteTable($v);
			}

		return '*'
			if '*' eq $table;
		$table = join '.', map {"`$_`"} split /[.]/, $table;
		$table =~ s/`+/`/g;
		return $table
	}

sub quoteWhenTable
	{
		my $table = shift;

		return sqlQuery::quoteTable($table)
			if ref $table || ".$table" =~ m/^(?:[.][[:lower:]_][[:lower:]\d_]*){1,2}$/i;

		if ($table =~ m/^([[:lower:]_][[:lower:]\d_]*)[.][*]$/i) {
			return sqlQuery::quoteTable($1).'.*';
		} else {
			return $table;
		}
	}

sub convertArgument
	{
		my $arg = shift;
		my $value = _convertArgument($arg);

		unless (defined $value) {
			local $Carp::CarpLevel = $Carp::CarpLevel + 1; ## no critic
			croak 'Argument to "sqlCondition::bind()" cannot be converted; consider using an implicit "sqlValue" instance instead'
		}

		return $value
	}

sub _convertArgument
	{
		my $arg = shift;

		unless(ref $arg) {
			return sqlValueNull->new
				unless defined $arg;
			return sqlValueInt->new($arg)
				if $arg =~ m/^-?\d+$/;
			return sqlValueFloat->new($arg)
				if $arg =~ m/^-?\d+[.]\d+$/;
			return sqlValueString->new($arg);
		} elsif ('ARRAY' eq ref $arg) {
			return sqlValueList->new($arg);
		} elsif (blessed $arg) {
			return $arg if $arg->isa('sqlParameter');
			return unless $arg->can('to_string');
			my $value = $arg->to_string();
			return sqlValueNull->new() unless defined $value;
			return $value if blessed $value && $value->isa('sqlParameter');
			return sqlValueString->new($value);
		}

		return
	}
##------------------------------------------------------------------------------
package sqlQueryResult;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

sub new
	{
		my $class = ref $_[0] ? ref shift : shift;
		my $query = shift;
		my $result = shift;

		return bless {-query => $query, -result => $result}, $class;
	}

sub fetchAssoc {goto &fetchRow}
sub fetchRow
	{
		my $self = shift;
		return $self->{'-result'}->fetchrow_hashref
	}

sub fetchArray
	{
		my $self = shift;
		return $self->{'-result'}->fetchrow_array;
	}

sub fetchColumn
	{
		my $self = shift;
		my $column = shift || '0';

		if (looks_like_number $column) {
			my @row = $self->{'-result'}->fetchrow_array;
			croak "No such query result offset $column"
				if $column > $#row;
			return $row[$column];
		} else {
			my $row = $self->fetchRow();
			croak "No such query result column $column"
				unless exists($row->{$column});
			return $row->{$column};
		}
	}

sub fetchAll
	{
		my $self = shift;
		my ($row,@rows);

		push @rows, $row
			while defined($row = $self->fetchAssoc());
		return @rows
	}

sub numRows {goto &getNumRows}
sub getNumRows
	{
		return shift->{'-result'}->rows;
	}

sub freeResource
	{
		my $self = shift;

		croak 'Statement seems unexecuted'
			unless defined $self->{'-result'};
		$self->{'-result'}->finish();
		undef $self->{'-result'};

		return $self;
	}
##------------------------------------------------------------------------------
package sqlQueryBase;

use strict;
use warnings;
##------------------------------------------------------------------------------
sub select
	{
		my @fields;
		my @params;

		if (@_ && 'ARRAY' eq ref $_[-1]) {
			@params = @{pop()}; ## no critic
		}

		unless (@_) {
			@fields = '*';
		} else {
			@fields = (
				(split /,/, (join ',', grep {!ref} @_)),
				grep {ref} @_
			);
		}

		return sqlSelectFrom->new(
			fields => [@fields],
			params => [@params]
		);
	}
##------------------------------------------------------------------------------
package sqlParameter;

use strict;
use warnings;
use overload '""' => 'getSafeQuotedValue';
use Carp qw(croak);

sub new
	{
		my $class = ref $_[0] ? ref shift : shift;
		return bless {-value => shift}, $class;
	}

sub getSafeQuotedValue
	{
		croak 'sqlParameter::getSafeQuotedValue() is abstract; implement it in '.(ref $_[0])
	}
##------------------------------------------------------------------------------
package sqlValueNull;

use strict;
use warnings;
use base 'sqlParameter';

sub getSafeQuotedValue {return 'NULL'}
##------------------------------------------------------------------------------
package sqlValueLiteral;

use strict;
use warnings;
use base 'sqlParameter';

sub getSafeQuotedValue {return shift->{-value}}
##------------------------------------------------------------------------------
package sqlValueString;

use strict;
use warnings;
use base 'sqlParameter';

sub getSafeQuotedValue {
	my $self = shift;
	return sqlQuery::dbh()->quote($self->{-value});
}
##------------------------------------------------------------------------------
package sqlValueInt;

use strict;
use warnings;
use base 'sqlParameter';

sub getSafeQuotedValue {
	return int(shift->{-value})
}
##------------------------------------------------------------------------------
package sqlValueFloat;

use strict;
use warnings;
use base 'sqlParameter';

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{-precision} = $_[1] || 8;
	return $self
}

sub getSafeQuotedValue {
	my $self = shift;
	return sprintf '%.'.$self->{-precision}.'f', $self->{-value}
}
##------------------------------------------------------------------------------
package sqlValueList;

use strict;
use warnings;
use base 'sqlParameter';
use Carp qw(croak);
use Scalar::Util 'blessed';

sub new {
	my $self = shift->SUPER::new(@_);

	unless (@{$self->{-value}}) {
		local $Carp::CarpLevel = $Carp::CarpLevel + 2; ## no critic
		croak 'Empty lists can break SQL syntax.';
	} else {
		$self->{-value} = [map {
			blessed($_) && $_->isa('sqlParameter')
				? $_
				: sqlQuery::convertArgument($_)
		} @{$self->{-value}}];
	}

	return $self
}

sub getSafeQuotedValue {
	return join ',', map {"$_"} @{shift->{-value}};
}
##------------------------------------------------------------------------------
package sqlValueDateTimeBase;

use strict;
use warnings;
use base 'sqlParameter';

use Carp;
use Date::Parse;
use Scalar::Util qw(looks_like_number);

sub new {
	my $self = shift->SUPER::new(@_);

	unless (defined $self->{-value}) {
		$self->{-value} = time;
	} elsif (looks_like_number $self->{-value}) {

	} else {
		$self->{-value} = str2time($self->{-value});
	}

	return $self
}

sub getSafeQuotedValue {
	return sqlQuery::dbh()->quote(shift->format());
}

sub format {
	croak __PACKAGE__.'::format() is "abstract"';
}
##------------------------------------------------------------------------------
package sqlValueDate;

use strict;
use warnings;
use base 'sqlValueDateTimeBase';
use POSIX qw(strftime);

sub format {
	return strftime '%Y-%m-%d', localtime shift->{-value};
}
##------------------------------------------------------------------------------
package sqlValueDateTime;

use strict;
use warnings;
use base 'sqlValueDateTimeBase';
use POSIX qw(strftime);

sub format {
	return strftime '%Y-%m-%d %H:%M:%S', localtime shift->{-value};
}
##------------------------------------------------------------------------------
package sqlSelectAssemble;

use strict;
use warnings;
use Carp qw/confess/;
use overload '""' => 'assemble';

sub new
	{
		my $class = shift;
		my ($prev,$prevClass,%args) = @_;
		my $self = bless {boundArgs => undef, prev => $prev, %args}, $class;

		if ($prevClass) {
			confess sprintf 'Invalid predecessor. Got "%s". Wanted "%s"', ref $self->{prev}, $prevClass
				unless ref $self->{prev} && $self->{prev}->isa($prevClass);
		}

		return $self
	}

sub addBoundArgs
	{
		my $self = shift;
		push @{$self->{boundArgs}}, @_;
		return $self
	}

sub gatherBoundArgs
	{
		my $self = shift;
		my (@args);

		push @args, @{$self->{boundArgs}}
			if defined $self->{boundArgs};
		push @args, $self->gatherConditionArgs();

		if (defined $self->{prev}) {
			push @args, $self->{prev}->gatherBoundArgs();
		}

		return @args
	}

sub gatherConditionArgs {}

sub assemble
	{
		my $self = shift;
		my $assembled = $self->_assemble();

		$assembled = $self->{prev}->assemble() . $assembled
			if defined $self->{prev};

		return $assembled
	}

sub _assemble
	{
		return ''
	}
##------------------------------------------------------------------------------
package sqlSelectFrom;

use strict;
use warnings;
use base 'sqlSelectAssemble';
use Scalar::Util qw(blessed);

sub new
	{
		my $class = ref $_[0] ? ref shift : shift;
		my (%args) = @_;
		my (@fields);

		@fields = @{$args{fields}};

		my $self = bless {
			queryFields => undef,
			tables => undef,
			params => $args{params}
		}, $class;

		$self->{queryFields} = [$self->translateQueryFields(@fields)];
		return $self
	}

sub from
	{
		my $self = shift;
		$self->{tables} = [@_];
		return sqlSelectJoin->new($self);
	}

sub translateQueryFields
	{
		my $self = shift;
		my (@fields) = @_;
		my @columns;

		foreach my $fieldIn (@fields)
			{
				my (@parts);

				unless ('HASH' eq ref $fieldIn) {
					@parts = ($fieldIn, undef);
				} else {
					@parts = %$fieldIn;
				}

				while (@parts) {
					my ($field,$alias) = (splice @parts, 0, 2);

					if (blessed $field && $field->isa('sqlParameter'))
						{
							push @columns, $sqlQuery::PARAMETER_PLACEHOLDER
								unless $alias;
							push @columns, sprintf '%s AS %s',
									$sqlQuery::PARAMETER_PLACEHOLDER,
									sqlQuery::quoteTable($alias)
								if $alias;
							$self->addBoundArgs($field);
							next;
						}

					$field = sqlQuery::quoteWhenTable($field)
						if '*' ne $field && 0 == ~index $field, ' ';

					unless ($alias) {
						push @columns, $field
					} else {
						$alias = sqlQuery::quoteWhenTable($alias)
							unless ~index $alias, ' ';
						push @columns, "\n\t$field AS $alias";
					}
				}
			}

		return @columns
	}

sub _assemble
	{
		my $self = shift;
		my $s = 'SELECT';

		$s .= ' ' . join ',', @{$self->{params}}
			if @{$self->{params}};
		$s .= ' ' . join ',', @{$self->{queryFields}};

		if (defined $self->{tables}) {
			$s .= "\nFROM ";
			my @t;

			foreach my $tableSpec (@{$self->{tables}}) {
				my (@tables);

				if ('HASH' eq ref $tableSpec) {
					@tables = %$tableSpec;
				} else {
					@tables = ($tableSpec,undef);
				}

				while (@tables) {
					my ($table,$alias) = (splice @tables, 0, 2);

					push @t, sqlQuery::quoteTable($table)
						unless $alias;
					push @t, sqlQuery::quoteTable($table)." AS `$alias`"
							if $alias;
				}
			}

			$s .= join ',', @t;
		}

		return "$s\n";
	}
##------------------------------------------------------------------------------
package sqlSelectLimit;

use strict;
use base 'sqlSelectAssemble';

sub new
	{
		return sqlSelectAssemble::new(@_, 'sqlSelectOrderBy',
			limit => undef,
			offset => undef);
	}

sub limit
	{
		my $self = shift;

		if (!@_ || (1 == @_ && !defined $_[0]) || (2 == @_ && !defined $_[0] && !defined $_[1])) {
			$self->{limit} = undef;
		} else {
			$self->{limit} = int shift;
			$self->{offset} = int shift if @_;
		}
		return sqlSelectAssemble->new($self);
	}

sub _assemble
	{
		my $self = shift;
		my $s;

		unless (defined $self->{limit}) {
			$s = '';
		} elsif (defined $self->{offset}) {
			$s = "LIMIT $self->{offset},$self->{limit}";
		} else {
			$s = "LIMIT $self->{limit}";
		}

		return $s
	}
##------------------------------------------------------------------------------
package sqlSelectOrderBy;

use strict;
use base 'sqlSelectLimit';

sub new
	{
		return sqlSelectAssemble::new(@_, 'sqlSelectHaving', ordering => undef);
	}

sub orderBy
	{
		my $self = shift;
		$self->{ordering} = [@_];
		return sqlSelectLimit->new($self);
	}

sub _assemble
	{
		my $self = shift;
		my $s;

		unless(defined $self->{ordering}) {
			$s = '';
		} else {
			$s = [];

			foreach my $order (@{$self->{ordering}}) {
				my ($theOrder,$direction) = ($order);
				if ('HASH' eq ref $theOrder) {
					($direction) = values %$theOrder;
					($theOrder) = keys %$theOrder;
				}

				push @$s, sqlQuery::quoteWhenTable($theOrder)
					unless $direction;
				push @$s, sqlQuery::quoteWhenTable($theOrder)." $direction"
						if $direction;
			}

			$s = join ',', @$s;
			$s = "ORDER BY $s\n";
		}

		return $s . $self->SUPER::_assemble();
	}
##------------------------------------------------------------------------------
package sqlSelectHaving;

use strict;
use base 'sqlSelectOrderBy';
use Carp 'confess';

sub new
	{
		return sqlSelectAssemble::new(@_, 'sqlSelectGroupBy', havingCond => undef);
	}

sub having
	{
		my $self = shift;
		my $condition = shift;

		confess 'Invalid condition'
			unless ref $condition && $condition->isa('sqlCondition');

		$self->{havingCond} = $condition;
		return sqlSelectOrderBy->new($self);
	}

sub gatherConditionArgs
	{
		my $self = shift;
		my @args;

		push @args, $self->{havingCond}->getBoundArgs()
			if defined $self->{havingCond};
		return @args
	}

sub _assemble
	{
		my $self = shift;
		my $s;

		unless (defined $self->{havingCond} && defined($s = $self->{havingCond}->assemble())) {
			$s = '';
		} else {
			$s = "HAVING $s\n";
		}

		return $s . $self->SUPER::_assemble();
	}
##------------------------------------------------------------------------------
package sqlSelectGroupBy;

use strict;
use base 'sqlSelectHaving';
use overload '+' => 'union';

sub union
	{
		my ($lhs,$rhs) = @_;

		return "($lhs) UNION ($rhs)";
	}

sub new
	{
		return sqlSelectAssemble::new(@_, 'sqlSelectWhere', grouping => undef);
	}

sub groupBy
	{
		my $self = shift;
		$self->{grouping} = [@_];
		return sqlSelectHaving->new($self);
	}

sub _assemble
	{
		my $self = shift;
		my $s = '';

		if (defined $self->{grouping})
			{
				$s = join ',', map {sqlQuery::quoteWhenTable($_)} @{$self->{grouping}};
				$s = "GROUP BY $s\n";
			}

		return $s . $self->SUPER::_assemble();
	}
##------------------------------------------------------------------------------
package sqlSelectWhere;

use strict;
use base 'sqlSelectGroupBy';
use Carp 'confess';

sub where
	{
		my $self = shift;
		my $condition = shift;

		confess 'Invalid condition'
			if defined $condition && !(ref $condition && $condition->isa('sqlCondition'));

		$self->{whereCond} = $condition;
		return sqlSelectGroupBy->new($self);
	}

sub gatherConditionArgs
	{
		my $self = shift;
		my @args;

		push @args, $self->{whereCond}->getBoundArgs()
			if defined $self->{whereCond};
		return @args
	}

sub _assemble
	{
		my $self = shift;
		my ($s,$c) = ('');

		if ($self->{whereCond} && defined($c = $self->{whereCond}->assemble()))
			{
				$s = "WHERE $c\n";
			}
		return $s . $self->SUPER::_assemble();
	}
##------------------------------------------------------------------------------
package sqlSelectJoin;

use strict;
use base 'sqlSelectWhere';

use Carp qw(confess);

sub new
	{
		return sqlSelectAssemble::new(@_, 'sqlSelectFrom', joins => []);
	}

sub gatherConditionArgs
	{
		my $self = shift;
		my (@args);

		if ($self->isa('sqlSelectJoin')) {
			foreach my $join (@{$self->{joins}}) {
				my ($type,$table,$condition) = @$join;
				push @args, $condition->getBoundArgs()
					if ref $condition;
			}
		}

		return (@args, $self->SUPER::gatherConditionArgs())
	}

sub innerJoin {return shift->_addJoin('INNER', @_)}
sub rightJoin {return shift->_addJoin('RIGHT', @_)}
sub leftJoin {return shift->_addJoin('LEFT', @_)}

sub _addJoin
	{
		my $self = shift;
		my ($type,$table,$condition) = @_;
		push @{$self->{joins}}, [$type, $table, $condition];

		return $self
	}

sub _assemble
	{
		my $self = shift;
		my $s;

		unless ($self->isa('sqlSelectJoin')) {
			$s = ref $self;
		} else {
			$s = [];

			foreach my $join (@{$self->{joins}}) {
				my ($type, $table, $condition) = @$join;
				$table = sqlQuery::quoteTable($table);
				my $j = "$type JOIN $table ";

				unless (ref $condition) {
					$j .= "USING(`$condition`)";
				} elsif ($condition->isa('sqlCondition')) {
					my $cond = $condition->assemble();
					$j .= "ON($cond)";
				} else {
					confess sprintf 'Cannot use argument "%s" as join condition', $condition;
				}

				push @$s, "$j\n";
			}

			$s = join '', @$s;
		}

		return $s . $self->SUPER::_assemble();
	}
##------------------------------------------------------------------------------
package sqlCondition;

use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use feature 'switch';
use overload
	'""' => 'assemble',
	'+' => 'overloadAdd',
	'!' => 'overloadNot',
	'&' => 'overloadAnd',
	'|' => 'overloadOr';

use constant TYPE_DEFAULT => 1;
use constant TYPE_CONNECT_AND => 2;
use constant TYPE_CONNECT_OR => 3;
use constant TYPE_UNARY_NOT => 4;
use Carp qw(confess cluck);
use Params::Validate qw(:all);
use Scalar::Util qw(blessed);

sub new
	{
		my $class = ref $_[0] ? ref shift : shift;
		my $self = bless{
			parent => undef,
			type => shift,
			_parts => undef,
			_condition => undef,
			_alterForNull => undef,
			_argument => undef,
			_queryArguments => []
		}, $class;

		if (TYPE_UNARY_NOT == $self->{type})
			{
				$self->{_argument} = shift;
				confess 'Invalid argument' unless
					ref $self->{_argument} && $self->{_argument}->isa('sqlCondition');
				$self->{_argument}->setParent($self);
			}

		return $self
	}

sub assemble
	{
		my $self = shift;

		given($self->{type}) {

			when([TYPE_CONNECT_AND, TYPE_CONNECT_OR]) {
				return unless defined $self->{_parts};
				my ($glue) = (TYPE_CONNECT_AND == $self->{type} ? ' AND ' : ' OR ');
				return '('.join($glue, map {$_->assemble()} @{$self->{_parts}}).')';
			}

			when([TYPE_DEFAULT]) {
				return $self->{_condition}
					unless ref $self->{_condition} && $self->{_condition}->isa('sqlCondition');
				return $self->{_condition}->assemble();
			}

			when([TYPE_UNARY_NOT]) {
				my $stmt = $self->{_argument}->assemble();
				return "NOT($stmt)";
			}
		}

		return
	}

sub overloadAdd
	{
		my ($lhs,$rhs,$leftConstant) = @_;

		cluck 'sqlCondition + sqlCondition will modify the left operand'
			if defined $leftConstant;
		return $lhs->add($rhs);
	}

sub getOverloadArgs
	{
		my ($lhs,$rhs,$swap) = @_;

		($lhs,$rhs) = ($rhs,$lhs) if $swap;

		$lhs = sqlCondition::C($lhs) unless ref $lhs;
		$rhs = sqlCondition::C($rhs) unless ref $rhs;

		confess 'Illegal LHS operand' unless blessed($lhs) && $lhs->isa('sqlCondition');
		confess 'Illegal RHS operand' unless blessed($rhs) && $rhs->isa('sqlCondition');

		return ($lhs,$rhs);
	}

sub overloadAnd
	{
		my ($lhs,$rhs) = getOverloadArgs(@_);
		return sqlCondition::AND($lhs, $rhs);
	}

sub overloadNot
	{
		return sqlCondition::NOT($_[0]);
	}

sub overloadOr
	{
		my ($lhs,$rhs) = getOverloadArgs(@_);
		return sqlCondition::OR($lhs, $rhs);
	}

sub add
	{
		my $self = shift;
		$self->{_parts} = [] unless defined $self->{_parts};

		push @{$self->{_parts}}, @_;
		$_->setParent($self) foreach @_;

		return $self
	}

sub addSql
	{
		my $self = shift;
		my $format = shift;

		return $self->add(C(sprintf $format, @_));
	}

sub bind
	{
		my $self = shift;

		if (1 == scalar @_ && !defined $_[0] && defined $self->{_alterForNull}) {
			($self->{_condition}) = (split / /, $self->{_condition}, 2);
			$self->{_condition} .= ' IS '.($self->{_alterForNull} ? '' : 'NOT ').'NULL';
			return $self;
		}

		$self->_bind(sqlQuery::convertArgument($_))
			foreach (@_);
		return $self
	}

sub getBoundArgs
	{
		return @{shift->{_queryArguments}};
	}

sub releaseBoundArgs
	{
		my $self = shift;
		my @args = $self->getBoundArgs();
		$self->{_queryArguments} = [];
		return @args;
	}

sub _OR {goto &OR}
sub OR
	{
		confess 'OR() expects at least 1 parameter.' unless @_;
		return connectedList(TYPE_CONNECT_OR, @_);
	}

sub _AND {goto &AND}
sub AND
	{
		confess 'AND() expects at least 1 parameter.' unless @_;
		return connectedList(TYPE_CONNECT_AND, @_);
	}

sub NOT
	{
		return sqlCondition->new(TYPE_UNARY_NOT, @_);
	}

sub C
	{
		my $cond = sqlCondition->new(TYPE_DEFAULT);

		if (1 == scalar @_) {
			$cond->{_condition} = shift;
		} else {
			$cond->{_condition} = sprintf $_[0], @_[1..$#_];
		}

		return $cond
	}

sub IN
	{
		my $column = shift;
		return C("%s IN($sqlQuery::PARAMETER_PLACEHOLDER)", sqlQuery::quoteWhenTable($column));
	}

sub NOTIN
	{
		my $column = shift;
		return C("%s NOT IN($sqlQuery::PARAMETER_PLACEHOLDER)", sqlQuery::quoteWhenTable($column));
	}

sub LIKE
	{
		my ($column,$pattern) = validate_pos @_,
			{column => {type => SCALAR}},
			{pattern => {type => SCALAR}};

		$pattern =~ s/"/"\"/g;
		$column = sqlQuery::quoteWhenTable($column);
		return C("$column LIKE \"$pattern\"");
	}

sub BETWEEN
	{
		my ($column,$start,$end) = validate_pos @_,
			{column => {type => SCALAR}},
			{start => {isa => 'sqlParameter'}},
			{end => {isa => 'sqlParameter'}};
		$column = sqlQuery::quoteWhenTable($column);

		return C("$column BETWEEN $sqlQuery::PARAMETER_PLACEHOLDER AND $sqlQuery::PARAMETER_PLACEHOLDER")
			->bind($start)->bind($end);
	}

sub ISNULL
	{
		my ($column) = validate_pos @_,
			{column => {type => SCALAR}};
		$column = sqlQuery::quoteWhenTable($column);

		return C("$column IS NULL")
	}

sub ISNOTNULL
	{
		my ($column) = validate_pos @_,
			{column => {type => SCALAR}};
		$column = sqlQuery::quoteWhenTable($column);

		return C("$column IS NOT NULL")
	}

sub EQ
	{
		my $cond = _OP('=', @_);
		$cond->{_alterForNull} = 1;
		return $cond
	}

sub NE
	{
		my $cond = _OP('!=', @_);
		$cond->{_alterForNull} = 0;
		return $cond
	}

sub LT {return _OP('<', @_)}
sub GT {return _OP('>', @_)}
sub LTE {return _OP('<=', @_)}
sub GTE {return _OP('>=', @_)}

sub _OP
	{
		my ($operator, $lhs, $rhs) = @_;
		return C('%s %s %s',
			sqlQuery::quoteWhenTable($lhs),
			$operator,
			3 != scalar @_
				? $sqlQuery::PARAMETER_PLACEHOLDER
				: sqlQuery::quoteWhenTable($rhs));
	}

sub connectedList
	{
		my $type = shift;
		my $cond = sqlCondition->new($type);

		foreach my $a (@_) {
			unless (blessed($a) && $a->isa('sqlCondition')) {
				$cond->insert($a);
				next;
			}

			if ($a->{type} != $type) {
				$cond->insert($a);
				next;
			}

			$cond->_bind($_) foreach $a->releaseBoundArgs();
			$cond->insert(@{$a->{_parts}});
		}

		return $cond
	}

sub insert
	{
		my $self = shift;

		$self->{_parts} = [] unless defined $self->{_parts};
		return $self->add(@_);
	}

sub _bind
	{
		my $self = shift;
		my ($parameter) = validate_pos @_,
			{parameter => {isa => 'sqlParameter'}};

		push @{$self->{_queryArguments}}, $parameter
			unless defined $self->{parent};
		$self->{parent}->up()->_bind($parameter)
				if defined $self->{parent};
		return $self
	}

sub setParent
	{
		my $self = shift;
		my ($parent) = validate_pos @_,
			{parameter => {isa => 'sqlCondition'}};

		$self->{parent} = $parent;
		$self->{parent}->up()->_bind($_)
			foreach @{$self->{_queryArguments}};
		$self->{_queryArguments} = [];
		return $self
	}

sub up
	{
		my $self = shift;

		return $self
			unless defined $self->{parent};
		return $self->{parent}->up();
	}

1;
__END__

=pod

=for stopwords SQL PHP Schieche OO schieche namespace Booleans boolean un unary falsy ad-hoc sqlQuery DBI prolog timestamp ARRAYREFs MySQL's HASHREFs

=head1 NAME

SQL::QueryBuilder::OO - Object oriented SQL query builder

=head1 SYNOPSIS

  use SQL::QueryBuilder::OO;

  # Uses an existing DBI database handle
  sqlQuery::setup(-dbh => $dbh);

  # Database handle is created when necessary via a sub-routine
  sqlQuery::setup(-connect => sub {
      DBI->connect(...);
  });

  # Full syntax
  $sql = sqlQueryBase::select(qw(id title description), {name => 'author'})
      ->from('article')
      ->innerJoin('users', 'userId')
      ->leftJoin({'comments' => 'c'}, sqlCondition::EQ('userId', 'c.from'))
      ->where(sqlCondition::AND(
              sqlCondition::EQ('category')->bind($cat),
              sqlCondition::NE('hidden')->bind(1)))
      ->limit(10,20)
      ->groupBy('title')
      ->orderBy({'timestamp' => 'DESC'});

  $sth = sqlQuery::q($sql)->execute();
  $row = $sth->fetchAssoc();
  $sth->freeResource();

  # Overloaded operators

  $cond = sqlCondition::EQ('a', 'b') & !sqlCondition::IN('c')->bind([1,2,3]);
  print "$cond";
  # -> (`a` = `b` AND NOT(`c` IN(1,2,3)))

=head1 DESCRIPTION

This module provides for an object oriented way to create complex SQL queries
while maintaining code readability. It supports conditions construction and
bound query parameters. While the module is named C<SQL::QueryBuilder::OO>, this
name is actually not used when constructing queries. The two main packages to
build queries are C<sqlQueryBase> and C<sqlCondition>. The package to execute
them is C<sqlQuery>.

The project is actually a port of PHP classes to construct queries used in one
of my proprietary projects (which may explain the excessive use of the scope
resolution operator (C<::>) in the module's syntax).

=head2 Setting the module up

Module set-up is I<not> optional; you may not be executing any queries, yet, an
existing (or ad-hoc created) database handle is required for purposes of safely
quoting interpolated values.

If at any point you're getting an "sqlQuery is not setup, yet." error, you
forgot to use any one of the following statements.

=head3 Using an existing database handle

To use an existing DBI database handle, put this in your program's prolog:

  sqlQuery::setup(-dbh => $dbh);

=head3 Creating a database handle when needed

To create a new database handle when it's needed (ad-hoc), supply a subroutine
that will be called I<once>:

  sqlQuery::setup(-connect => sub {
      DBI->connect(...);
  });

=head2 Building queries

The package to provide builder interfaces is called C<sqlQueryBase> and has
these methods:

=head3 SELECT queries

=over 4

=item select(I<COLUMNS...>[, I<OPTIONS>])

Creates a SELECT query object. Columns to select default to C<*> if none are
given. They are otherwise to be specified as a list of expressions that can be
literal column names or HASH references with column aliases.

Column names are quoted where appropriate:

  # Build SELECT * query
  $all = sqlQueryBase::select();

  # Build SELECT ... query
  $sql = sqlQueryBase::select(
       # literal column names
          qw(id title),
       # column alias
          {'u.username' => 'author', timestamp => 'authored'},
       # SELECT specific options
          [qw(SQL_CACHE SQL_CALC_FOUND_ROWS)]);

The references returned from the above statements are blessed into an internal
package. Those internal packages will not be documented here, since they may be
subject to change. Their methods, however, are those of a valid SQL SELECT
statement. When constructing queries you'll B<have to maintain the order> of
SQL syntax. This means, that the following will be treated as an error
I<by Perl itself>:

  $sql = sqlQueryBase::select()
          ->from('table')
          ->limit(10)
          ->where(...);

  Can't locate object method "where" via package "sqlSelectAssemble" at ...

The correct order would have been:

  $sql = sqlQueryBase::select()
          ->from('table')
          ->where(...)
          ->limit(10);

The following methods are available to construct the query further:

=item from(I<TABLES...>)

This obviously represents the "FROM" part of a select query. It accepts a list
of string literals as table names or table aliases:

  $sql = sqlQueryBase::select()->from('posts', {'user' => 'u'});

=item leftJoin(I<TABLE>, I<CONDITION>)

=item innerJoin(I<TABLE>, I<CONDITION>)

=item rightJoin(I<TABLE>, I<CONDITION>)

These methods extend the "FROM" fragment with a left, inner or right table join.
The table name can either be a string literal or a HASH reference for aliasing
table names.

The condition should either be an C<sqlCondition> object (see L</"Creating conditions">):

  # SELECT * FROM `table_a` LEFT JOIN `table_b` ON(`column_a` = `column_b`)
  $sql = sqlQueryBase::select()
          ->from('table_a')
          ->leftJoin('table_b', sqlCondition::EQ('column_a', 'column_b'));

...or a string literal of a common column name for the USING clause:

  # SELECT * FROM `table_a` LEFT JOIN `table_b` USING(`id`)
  $sql = sqlQueryBase::select()
          ->from('table_a')
          ->leftJoin('table_b', 'id');

=item where(I<CONDITION>)

This represents the "WHERE" part of a SELECT query. It will accept B<one> object
of the C<sqlCondition> package (see L</"Creating conditions">).

=item groupBy(I<COLUMNS...>)

This represents the "GROUP BY" statement of a SELECT query.

=item having(I<CONDITION>)

This represents the "HAVING" part of a SELECT query. It will accept B<one> object
of the C<sqlCondition> package (see L</"Creating conditions">).

=item orderBy(I<COLUMNS...>)

This represents the "ORDER BY" statement of a SELECT query. Columns are expected
to be string literals or HASH references (B<one> member only) with ordering
directions:

  $sql = sqlQueryBase::select()
          ->from('table')
          ->orderBy('id', {timestamp => 'DESC'}, 'title');

=item limit(I<COUNT>[, I<OFFSET>])

This represents the "LIMIT" fragment of a SELECT query. It deviates from the
standard SQL expression, as the limit count B<is always> the first argument to
this method, regardless of a given offset. The first or both parameters may be
C<undef> to skip the LIMIT clause.

=back

=head3 Creating conditions

Conditions can be used as a parameter for C<leftJoin>, C<having>, C<innerJoin>,
C<rightJoin> or C<where>. They are constructed with the C<sqlCondition> package,
whose methods are not exported due to their generic names. Instead, the
"namespace" has to be mentioned for each conditional:

  $cond = sqlCondition::AND(
          sqlCondition::EQ('id')->bind(1337),
          sqlCondition::BETWEEN('stamp', "2013-01-06", "2014-03-31"));

Those are all operators:

=head4 Booleans

To logically connect conditions, the following to methods are available:

=over 4

=item AND(I<CONDITIONS...>)

Connect one or more conditions with a boolean AND.

=item OR(I<CONDITIONS...>)

Connect one or more conditions with a boolean OR.

=item NOT(I<CONDITION>)

Negate a condition with an unary NOT.

=back

=head4 Relational operators

All relational operators expect a mandatory column name as their first argument
and a second optional ride-hand-side column name.

If the optional second parameter is left out, the conditional can be bound (see
L</"Binding parameters">).

=over 4

=item EQ(I<COLUMN>[, I<RHS-COLUMN>])

B<Eq>ual to operator (C<=>).

=item NE(I<COLUMN>[, I<RHS-COLUMN>])

B<N>ot B<e>qual to operator (C<!=>).

=item LT(I<COLUMN>[, I<RHS-COLUMN>])

B<L>ess B<t>han operator (C<E<lt>>).

=item GT(I<COLUMN>[, I<RHS-COLUMN>])

B<G>reater B<t>han operator (C<E<gt>>).

=item LTE(I<COLUMN>[, I<RHS-COLUMN>])

B<L>ess B<t>han or B<e>qual to operator (C<E<lt>=>).

=item GTE(I<COLUMN>[, I<RHS-COLUMN>])

B<G>reater B<t>han or B<e>qual to operator (C<E<gt>=>).

=back

=head4 SQL specific operators

=over 4

=item BETWEEN(I<COLUMN>, I<START>, I<END>)

Creates an "x BETWEEN start AND end" conditional.

=item IN(I<COLUMN>)

Creates an "x IN(...)" conditional.

B<Note> that, if bound, this method B<will> croak if it encounters an empty
list. I<This behavior is subject to change in future versions: the statement
will be reduced to a "falsy" statement and a warning will be issued.>

=item ISNULL(I<COLUMN>)

Creates an "x IS NULL" conditional.

=item ISNOTNULL(I<COLUMN>)

Creates an "x IS NOT NULL" conditional.

=item LIKE(I<COLUMN>, I<PATTERN>)

Creates an "x LIKE pattern" conditional.

B<Note> that the pattern is passed unmodified. Beware of the LIKE pitfalls
concerning the characters C<%> and C<_>.

=item NOTIN(I<COLUMN>)

Creates an "x NOT IN(...)" conditional.

Convenience for C<sqlCondition::NOT(sqlCondition::IN('x')->bind([1,2,3]))>.
Please refer to C<IN> for caveats.

=back

=head3 Binding parameters

An SQL conditional can be bound against a parameter via its C<bind()> method:

  $cond = sqlCondition::AND(
          sqlCondition::EQ('id')->bind(1337),
          sqlCondition::NOT(
             sqlCondition::IN('category')->bind([1,2,3,4])));

  print $cond;                        # "`id` = ? AND NOT(`category` IN(?))"
  @args = $cond->gatherBoundArgs();   # (sqlValueInt(1337),sqlValueList([1,2,3,4]))

A special case are conditionals bound against C<undef> (which is the equivalent
to SQL C<NULL>):

  $cat = undef;
  $cond = sqlCondition::OR(
          sqlCondition::EQ('author')->bind(undef),
          sqlCondition::NE('category')->bind($cat));

  print $cond;                        # `author` IS NULL OR `category` IS NOT NULL
  @args = $cond->gatherBoundArgs();   # ()

Since C<`author` = NULL> would never be "true", the condition is replaced with
the correct C<`author` IS NULL> statement. (Note that the first conditional
could actually be written C<sqlCondition::ISNULL('author')>. The substitution is
thus useful when binding against variables of unknown content).

=head4 Parameter conversion

Bound parameters are internally converted to a sub-class of C<sqlParameter>.
Since most scalar values are already converted automatically, a user might never
need to employ any of those packages listed below. If more complex queries are
desired, however, they just I<have> to be used.

=over

=item C<sqlValueDate>

=item C<sqlValueDateTime>

To bind a value and use its date or date/time representation, use:

  $cond->bind(new sqlValueDate()); # use current time, return YYYY-MM-DD
  $cond->bind(new sqlValueDateTime()); # use current time, return YYYY-MM-DD HH:MM:SS

  $tm = mktime(...);
  $cond->bind(new sqlValueDate($tm)); # use UNIX timestamp; return YYYY-MM-DD
  $cond->bind(new sqlValueDateTime($tm)); # use UNIX timestamp; return YYYY-MM-DD HH:MM:SS

  $str = "Wed, 6 Jan 82 02:20:00 +0100";
  $cond->bind(new sqlValueDate($str)); # use textual representation; return YYYY-MM-DD
  $cond->bind(new sqlValueDateTime($str)); # use textual representation; return YYYY-MM-DD HH:MM:SS

The latter variants using textual representation use L<Date::Parse> to convert a
string into a UNIX timestamp. Refer to L<Date::Parse> to learn about supported
formats.

=item C<sqlValueFloat>

To bind a value as a floating point number (with optional precision), use:

  $cond->bind(new sqlValueFloat($number, 4)); # Precision of four; eight is the default

B<Scalars I<looking like> floating point numbers are I<automatically> converted
to this package when using C<bind()>.>

=item C<sqlValueInt>

To bind a value as an integer, use:

  $cond->bind(new sqlValueInt($number));

B<Scalars I<looking like> (un)signed integers are I<automatically> converted to
this package when using C<bind()>.>

=item C<sqlValueList>

To create a safe list of values, use:

  sqlCondition::IN('column')->bind(new sqlValueList([1,2,3,4]));

B<Scalars that are ARRAYREFs are I<automatically> converted to this package when
using C<bind()>.> All elements of the list are subject to conversion as well.

=item C<sqlValueLiteral>

To include a complex statement as-is, use:

  sqlCondition::EQ('a')->bind(new sqlValueLiteral('IF(`b` = `c`, 0, 1)'));
  # -> `a` = IF(`b` = `c`, 0, 1)

I<Please> do not abuse this to interpolate values into the query: this would
pose a security risk since these values aren't subject to "escaping".

=item C<sqlValueNull>

To represent MySQL's C<NULL>, use:

  $cond->bind(new sqlValueNull());

B<Scalars evaluating to C<undef> are I<automatically> converted to this package
when using C<bind()>.>

=item C<sqlValueString>

To bind a value as a string, use:

  $cond->bind(new sqlValueString($value));

B<All scalars that aren't C<undef>, integers, or floats are converted to this
package when using C<bind()>.> The value is properly escaped before query
interpolation.

=back

=head4 Named or index-based parameters

The module supports both named or index-based parameters; just not both in a
mix:

  # Index-based parameters
  $query = sqlQueryBase::select()
      ->from('table')
      ->where(sqlCondition::EQ('id')->bind(1337));
  print "$query"; # -> SELECT * FROM `table` WHERE `id` = ?

  # Named parameters
  $query = sqlQueryBase::select()
      ->from('table')
      ->where(sqlCondition::EQ('id', ':value'));
  print "$query"; # -> SELECT * FROM `table` WHERE `id` = :value

Index-based parameters can be bound to the corresponding C<sqlCondition> when
it's created and are later interpolated. Name based parameters make for cleaner
query creation statements but require an additional step prior to executing the
query:

  $query = sqlQueryBase::select()
      ->from('table')
      ->where(sqlCondition::EQ('id', ':value'));
  $res = sqlQuery->new($query)
      ->setParameters({value => 1337}) # assign name-value pairs here
      ->execute();

=head3 Conditions with overloaded operators

To regain a little readability, the I<binary> operators C<&> and C<|> and the
unary C<!> have been overloaded to substitute for C<sqlCondition::AND>,
C<sqlCondition::OR> and C<sqlCondition::NOT> respectively.

This:

  $cond = sqlCondition::AND(
          sqlCondition::EQ('a', 'b'),
          sqlCondition::OR(
              sqlCondition::NOT(sqlCondition::LIKE('d', "%PATTERN%")),
              sqlCondition::C('UNIX_TIMESTAMP(`column`) >= DATE_SUB(NOW(), INTERVAL 7 DAY)')));

is the same as this:

  $cond = sqlCondition::EQ('a', 'b')
        & (!sqlCondition::LIKE('d', "%PATTERN%")
        | 'UNIX_TIMESTAMP(`column`) >= DATE_SUB(NOW(), INTERVAL 7 DAY)');

=head2 Executing queries

The package to execute queries with is C<sqlQuery>. Depending on its usage, it
returns an C<sqlQueryResult> package instance:

  $query = sqlQuery->new($sql);
  $result = $query->execute();
  $row = $result->fetchAssoc();
  $result->freeResource();

=head3 Fetching results

A query result of the C<sqlQueryResult> package has these methods:

=over

=item C<fetchAll()>

Fetch all rows, return a list of HASHREFs.

=item C<fetchArray()>

Fetch one row, return the values as a list.

=item C<fetchAssoc()>

Fetch one row, return it as a C<HASHREF>.

=item C<fetchColumn($name)>

Fetch one row, return its named column C<$name> or index-based column (from
zero).

=item C<fetchRow()> I<(alias)>

Fetch one row, return it as a C<HASHREF>.

=back

=head3 Other methods

The following are other methods of C<sqlQueryResult> unrelated to fetching data:

=over

=item C<freeResource()>

Finishes an executed statement, freeing its resources.

=item C<getNumRows()>

=item C<numRows()>

Return number of rows in a C<SELECT> query.

=back

=head1 EXAMPLES

=head2 Execute a single statement

=head3 Index-based parameters

  sqlQuery::exec('UPDATE `foo` SET `bar` = ?', 'splort'); # returns number of affected rows

=head3 Named parameters

  sqlQuery::exec('UPDATE `foo` SET `bar` = :bar', {
      bar => 'splort'
  }); # returns number of affected rows

=head1 TODO

=over

=item *

Implement support for UPDATE, INSERT, REPLACE and DELETE statements.

=item *

Implement support for UNION.

=back

=head1 DEPENDENCIES

=over

=item *

L<Params::Validate>

= item *

L<Date::Parse>

=back

=head1 AUTHOR

Oliver Schieche E<lt>schiecheo@cpan.orgE<gt>

http://perfect-co.de/

$Id: OO.pm 55 2016-03-03 07:02:51Z schieche $

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2015 Oliver Schieche.

This software is a free library. You can modify and/or distribute it under the
same terms as Perl itself.

=cut
