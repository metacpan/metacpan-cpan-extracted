package Rose::DBx::Object::Builder;
use strict;
use warnings;
no warnings 'recursion';
use Exporter 'import';

use base qw(Rose::Object);
our @EXPORT = qw(config parse build show);
our @EXPORT_OK = qw(config parse build show);

use Lingua::EN::Inflect 'PL';
use Regexp::Common;
use DBI;

our $VERSION = 0.09;
# 12.9

sub config {
	my $self = shift;
	unless ($self && defined $self->{CONFIG}) {
		$self->{CONFIG} = {
			db => {
				name => undef, 
				type => 'mysql', 
				host => '127.0.0.1', 
				port => undef, 
				username => 'root', 
				password => 'root', 
				tables_are_singular => undef,
				table_prefix => '',
				options => {RaiseError => 0, PrintError => 0, AutoCommit => 1}},
			format => {
				expression => sub {
					my $expression = lc(shift);
					$expression =~ s/\s*,?\s*\band\b\s*,?\s*/, /g;
					$expression =~ s/\b(a|an|the)\b//g;
					$expression =~ s/\.//g;
					return $expression;
				},
				table => sub {
					my $table = shift;
					$table =~ s/^\s+|\s+$//g;					
					$table =~ s/\s+/_/g;
					return $table;
				},
				column => sub {
					my $column = shift;
					$column =~ s/^\s+|\s+$//g;
					$column =~ s/\s+/_/g;
					return $column;
				},
			},
			table => {
				mysql => 'CREATE TABLE [% table_name %] ([% columns %]) TYPE=INNODB;',
				Pg => 'CREATE TABLE [% table_name %] ([% columns %]);',
				SQLite => 'CREATE TABLE [% table_name %] ([% columns %]);',
			},
			primary_key => {
				name => 'id',
				type => {
					mysql => 'INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY',
					Pg => 'SERIAL PRIMARY KEY',
					SQLite => 'INTEGER NOT NULL PRIMARY KEY',
				}
			},
			foreign_key => {
				suffix => '_id',
				type => {
					mysql => 'INTEGER',
					Pg => 'INTEGER',
					SQLite => 'INTEGER',
				},
				singular => 1,
				clause => 'FOREIGN KEY ([% foreign_key %]) REFERENCES [% reference_table %] ([% reference_primary_key %]) ON UPDATE CASCADE ON DELETE CASCADE',
			},
			add_clause => 'ALTER TABLE [% table_name %] ADD [% clause %];',
			map_table => '[% table_name %]_[% foreign_table_name %]_map',
			columns => {
				name => 'VARCHAR(255)',
				unique => 'VARCHAR(255) UNIQUE',
				required => 'VARCHAR(255) NOT NULL',
				text => 'TEXT',
				integer => 'INTEGER',
				number => 'NUMERIC',
				date => 'DATE',
				time => 'TIME',
				timestamp => 'TIMESTAMP',
				money => 'DECIMAL(13,2)',
				boolean => 'BOOLEAN',
			}
		};
		
		$self->{CONFIG}->{columns}->{title} = $self->{CONFIG}->{columns}->{name};
		$self->{CONFIG}->{columns}->{description} = $self->{CONFIG}->{columns}->{text};
		$self->{CONFIG}->{columns}->{percentage} = $self->{CONFIG}->{columns}->{number};
		$self->{CONFIG}->{columns}->{cost} = $self->{CONFIG}->{columns}->{money};
		$self->{CONFIG}->{columns}->{price} = $self->{CONFIG}->{columns}->{money};
		$self->{CONFIG}->{columns}->{username} = $self->{CONFIG}->{columns}->{unique};
	}
	
	if (@_) {
		my $config = shift;
		foreach my $hash (keys %{$config}) {
			if (ref $config->{$hash} eq 'HASH') {
				foreach my $key (keys %{$config->{$hash}}) {
					if (ref $config->{$hash}->{$key} eq 'HASH') {
						foreach my $sub_key (keys %{$config->{$hash}->{$key}}) {
							$self->{CONFIG}->{$hash}->{$key}->{$sub_key} = $config->{$hash}->{$key}->{$sub_key};
						}
					}
					else {
						$self->{CONFIG}->{$hash}->{$key} = $config->{$hash}->{$key};
					}
				}
			}
			else {
				$self->{CONFIG}->{$hash} = $config->{$hash};
			}
		}
	}
	
	return $self->{CONFIG};
}

sub build {
	my $self = shift;
	my $dbh = shift;
	my $config = $self->config;
	my $schema = $self->parse;
	return unless $schema;

	unless ($dbh) {
		die "Database name missing" unless $config->{db}->{name};
		my $host;
	 	$host = 'host='. $config->{db}->{host} if $config->{db}->{host};
		$host .= ';port='.$config->{db}->{port} if $config->{db}->{port};
		my $dsn = qq(dbi:$config->{db}->{type}:dbname=$config->{db}->{name};$host);
		$dbh = DBI->connect($dsn, $config->{db}->{username}, $config->{db}->{password}, $config->{db}->{options}) or die "Error opening database: $config->{db}->{name}\n";
	}
	
	eval {	
		foreach my $sql (split /;/, $schema) {
			$dbh->do($sql) or warn "Error executing SQL: $sql;\n";
		}
		$dbh->commit unless $config->{db}->{options}->{AutoCommit};
	};

	if ($@) {
		warn "Transaction aborted: $@";
		eval {$dbh->rollback};
  	}
	
	$dbh->disconnect or die "Error closing database: $config->{db}->{name}\n";
}

sub parse {
	my $self = shift;
	my $string = shift;

	if ($string) {
		my $config = $self->config;
		foreach my $expression (split /\./, $string) {
			my $schema;
			if ($expression =~ /\s+as\s+/) {   
				$schema = _as ($config, $expression);
			}
			elsif ($expression =~ /vice[\s\-]+versa/) {
				$schema = _many_to_many ($config, $expression);
			}
			elsif ($expression =~ /(has|have)\s+many/) {
				$schema = _has_many ($config, $expression);			
			}
			else {    
				$schema = _has_a ($config, $expression);
			}
			$self->{SCHEMA} .= $schema if $schema;
		}
	}
	return $self->{SCHEMA} || '';
}

sub show {
	my $self = shift;
	my $schema = $self->parse(@_);
	return unless $schema;
	my @pretty;
	
	foreach my $schema (split /;/, $schema) {
		if ($schema =~ /CREATE/) {
			$schema =~ s/^([^\(]+)\(/$1\(\n\t/g;
			$schema =~ s/\)([^\)]+)$/\n\)$1/g;
			$schema =~ s/([^\d]),([^\d])/$1,\n\t$2/g;
			$schema =~ s/\)$/\n)/;
		}
		push @pretty, $schema . ';';
	}
	return join "\n\n", @pretty;
}

sub _as {
	my $config = shift;
	my $expression = $config->{format}->{expression}->(shift);
	my ($table_name, $has, $foreign_table_name, $foreign_key) = split /\s+(has|have)\s+(.*)\s+as\s+(.*)/, $expression;
	return unless $table_name && $foreign_table_name && $foreign_key;
	$table_name = _normalise_table($config, $config->{format}->{table}->($table_name));
	$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($foreign_table_name));
	$foreign_key = $config->{format}->{column}->($foreign_key);
	$foreign_key = $config->{foreign_key}->{singular} ? _singularise($foreign_key) : $foreign_key;
	$foreign_key .= $config->{foreign_key}->{suffix};
	
	my $add_column = $config->{add_clause};
	$add_column =~ s/\[%\s*table_name\s*%\]/$table_name/;
	$add_column =~ s/\[%\s*table_name\s*%\]/$table_name/;
	
	my $foreign_key_column = $foreign_key . ' ' . $config->{foreign_key}->{type}->{$config->{db}->{type}};
	$add_column =~ s/\[%\s*clause\s*%\]/$foreign_key_column/;
	my $schema = $add_column;

	my $add_foreign_key = $config->{add_clause};
	$add_foreign_key =~ s/\[%\s*table_name\s*%\]/$table_name/;	
	my $foreign_key_clause = _generate_foreign_key_clause($config, $foreign_key, $foreign_table_name);
	$add_foreign_key =~ s/\[%\s*clause\s*%\]/$foreign_key_clause/;
	$schema .= $add_foreign_key;
	
	return $schema;
}

sub _many_to_many {
	my $config = shift;
	my $expression = $config->{format}->{expression}->(shift);
	$expression =~ s/,\s+vice[\s\-]+versa//;
	my ($table_name, $has, $foreign_table_name) = split /\s*(has|have)\s+many\s*/, $expression;
	return unless $table_name && $foreign_table_name;
	$table_name = _normalise_table($config, $config->{format}->{table}->($table_name));
	$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($foreign_table_name));
	my $map_table = $config->{map_table};
	$map_table =~ s/\[%\s*table_name\s*%\]/$table_name/;
	$map_table =~ s/\[%\s*foreign_table_name\s*%\]/$foreign_table_name/;
	
	my $schema = $config->{table}->{$config->{db}->{type}};
	$schema =~ s/\[%\s*table_name\s*%\]/$map_table/;
		
	my $foreign_keys;
	my @columns = ($config->{primary_key}->{name} . ' ' . $config->{primary_key}->{type}->{$config->{db}->{type}});
	
	foreach my $table ($table_name, $foreign_table_name) {
		my $foreign_key = $config->{foreign_key}->{singular} ? _singularise($table) : $table;
		$foreign_key .= $config->{foreign_key}->{suffix};
		$foreign_keys->{$foreign_key} = $table;
		push @columns, $foreign_key . ' ' . $config->{foreign_key}->{type}->{$config->{db}->{type}};
	}
	
	foreach my $foreign_key (keys %{$foreign_keys}) {
		push @columns, _generate_foreign_key_clause($config, $foreign_key, $foreign_keys->{$foreign_key});
	}
	
	my $schema_columns = join ',', @columns;
	$schema =~ s/\[%\s*columns\s*%\]/$schema_columns/;
	return $schema;
}

sub _has_many {
	my $config = shift;
	my $expression = $config->{format}->{expression}->(shift);
	my ($table_name, $has, $foreign_table_name) = split /\s*(has|have)\s+many\s*/, $expression;
	return unless $table_name && $foreign_table_name;
	$table_name = _normalise_table($config, $config->{format}->{table}->($table_name));
	$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($foreign_table_name));
	my $add_column = $config->{add_clause};
	$add_column =~ s/\[%\s*table_name\s*%\]/$foreign_table_name/;
	
	my $foreign_key = $config->{foreign_key}->{singular} ? _singularise($table_name) : $table_name;
	$foreign_key .= $config->{foreign_key}->{suffix};
	
	my $foreign_key_column = $foreign_key . ' ' . $config->{foreign_key}->{type}->{$config->{db}->{type}};
	$add_column =~ s/\[%\s*clause\s*%\]/$foreign_key_column/;
	my $schema = $add_column;
	
	my $add_foreign_key = $config->{add_clause};
	$add_foreign_key =~ s/\[%\s*table_name\s*%\]/$foreign_table_name/;
	
	my $foreign_key_clause = _generate_foreign_key_clause($config, $foreign_key, $table_name);
	$add_foreign_key =~ s/\[%\s*clause\s*%\]/$foreign_key_clause/;
	$schema .= $add_foreign_key;
	
	return $schema;
}

sub _has_a {
	my $config = shift;
	my $expression = $config->{format}->{expression}->(shift);
	my ($table_name, $has, $columns) = ($expression =~ /^([\w_\-0-9\s]+)\s+(has|have)\s+(.*)$/);
	return unless $table_name && $columns;	
	
	my ($schema, $foreign_keys, $foreign_table_name, $foreign_table_columns, $custom_columns);
	my $foreign_key_suffix = $config->{foreign_key}->{suffix};
	my $table = {name => _normalise_table($config, $config->{format}->{table}->($table_name))};
	
	push @{$table->{columns}}, {name => $config->{primary_key}->{name}, type => $config->{primary_key}->{type}->{$config->{db}->{type}}};
	
	while ($columns =~ /[()]/) {
		($foreign_table_name, $foreign_table_columns) = ($columns =~ /([\w_\-0-9\s]+)\s*($RE{balanced}{-parens=>'()'})/);		
		($foreign_table_columns) = ($foreign_table_columns =~ /\((.*)\)/);
		
		if($foreign_table_columns =~ /^\s*(has|have)/) {					
			$schema .= _has_a($config, join ' ', ($foreign_table_name , $foreign_table_columns));
			$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($foreign_table_name));
			my $foreign_key = $config->{foreign_key}->{singular} ? _singularise($foreign_table_name) : $foreign_table_name;
			$foreign_key .= $foreign_key_suffix;
			$foreign_keys->{$foreign_key} = $foreign_table_name;
			$columns =~ s/(\b[\w_\-0-9\s]*)\b\s*($RE{balanced}{-parens=>'()'})/$foreign_key/;
		}
		else {
			$foreign_table_name = $config->{format}->{column}->($foreign_table_name);
			
			if ($foreign_table_columns =~ /^reference/) {
				my $foreign_key = $foreign_table_name;
				my ($reference_table) = ($foreign_table_columns =~ /^references?\s+([\w_\-0-9\s]+)$/);
				
				if ($reference_table) {
					$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($reference_table));
				}
				else {
					$foreign_table_name =~ s/$foreign_key_suffix$//;
					$foreign_table_name = _normalise_table($config, $config->{format}->{table}->($foreign_table_name));
				}
								
				$foreign_keys->{$foreign_key} = $foreign_table_name;
			}
			elsif (exists $config->{columns}->{$foreign_table_columns}) {
				$custom_columns->{$foreign_table_name} = $config->{columns}->{$foreign_table_columns};
			}
			
			$columns =~ s/([\w_\-0-9]*)\s*($RE{balanced}{-parens=>'()'})/$1/; # clean it for the while loop
		}
	}
		
	foreach my $column (split /\s*,\s*/, $columns) {
		$column = $config->{format}->{column}->($column);
		if (exists $foreign_keys->{$column}) {
			push @{$table->{columns}}, {name => $column, type => $config->{foreign_key}->{type}->{$config->{db}->{type}}};
		}
		else {
			if (exists $custom_columns->{$column}) {
				push @{$table->{columns}}, {name => $column, type => $custom_columns->{$column}};
			}
			elsif (exists $config->{columns}->{$column}) {
				push @{$table->{columns}}, {name => $column, type => $config->{columns}->{$column}};
			}
			else {
				my $column_type;
				DEF: foreach my $column_key (keys %{$config->{columns}}) {
					if ($column =~ /$column_key/) {
						 # first match
						$column_type = $column_key;
						last DEF;
					}
				}
				
				if ($column_type) {
					push @{$table->{columns}}, {name => $column, type => $config->{columns}->{$column_type}};
				}
				else {
					push @{$table->{columns}}, {name => $column, type => $config->{columns}->{name}}; # default
				}
			} 
		}
	}
	
	my $schema_columns = [map {$_->{name} . ' ' . $_->{type}} @{$table->{columns}}];
	
	foreach my $foreign_key (keys %{$foreign_keys}) {		
		push @{$schema_columns}, _generate_foreign_key_clause($config, $foreign_key, $foreign_keys->{$foreign_key});
	}
	
	my $schema_columns_string = join ',', @{$schema_columns};
		
	$schema .= $config->{table}->{$config->{db}->{type}};
	$schema =~ s/\[%\s*table_name\s*%\]/$table->{name}/;
	$schema =~ s/\[%\s*columns\s*%\]/$schema_columns_string/;	
	
	return $schema;
}

sub _singularise  {
	# based on Rose::DB::Object::ConventionManager
	my $word = shift;
	$word =~ s/ies$/y/i;
	return $word if ($word =~ s/ses$/s/);
	return $word if($word =~ /[aeiouy]ss$/i);
	$word =~ s/s$//i;
	return $word;
}

sub _generate_foreign_key_clause {
	my ($config, $foreign_key, $reference_table) = @_;
	my $foreign_key_clause = $config->{foreign_key}->{clause};
	$foreign_key_clause =~ s/\[%\s*foreign_key\s*%\]/$foreign_key/;
	$foreign_key_clause =~ s/\[%\s*reference_table\s*%\]/$reference_table/;
	$foreign_key_clause =~ s/\[%\s*reference_primary_key\s*%\]/$config->{primary_key}->{name}/;
	return $foreign_key_clause;
}

sub _normalise_table {
	my ($config, $table) = @_;
	my $table_name;
	
	if ($config->{db}->{tables_are_singular}) {
		$table_name = _singularise($table);
	}
	else {
		$table_name = Lingua::EN::Inflect::PL(_singularise($table));
	}
	
	return $config->{db}->{table_prefix} . $table_name if defined $config->{db}->{table_prefix};
	return $table_name;
}

1;

__END__

=head1 NAME

Rose::DBx::Object::Builder - Database Table Schema Generation for Rose::DB::Object

=head1 SYNOPSIS
  
  use Rose::DBx::Object::Builder;

  my $text = 'Employees have username, password, and position (has a title and description). Projects have name and due date. Employees have many Projects and vice versa.';

  my $builder = Rose::DBx::Object::Builder->new(parse => $text);
  print $builder->show();
  
  # prints: 
  CREATE TABLE positions (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    description TEXT
  ) TYPE=INNODB;

  CREATE TABLE employees (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    position_id INTEGER,
    FOREIGN KEY (position_id) REFERENCES positions (id) ON UPDATE CASCADE ON DELETE CASCADE
  ) TYPE=INNODB;

  CREATE TABLE projects (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    due_date DATE
  ) TYPE=INNODB;

  CREATE TABLE employees_projects_map (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INTEGER,
    project_id INTEGER,
    FOREIGN KEY (employee_id) REFERENCES employees (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects (id) ON UPDATE CASCADE ON DELETE CASCADE
  ) TYPE=INNODB;

=head1 DESCRIPTION

Rose::DBx::Object::Builder generates database table schemas from simple, succinct sentences. It alleviates the need to specify the data type for every table columns and simplifies the tedious work of setting up common table relationships. The generated table schemas follow the default conventions of L<Rose::DB::Object>.

=head1 METHODS

=head2 C<new>

To instantiate a new Builder object:

  my $builder = Rose::DBx::Object::Builder->new(config => {db => {type => 'Pg', tables_are_singular => 1}}, parse => 'Users have many photo albums');

Since Builder inherits from L<Rose::Object>, the above line is equivalent to:

  my $builder = Rose::DBx::Object::Builder->new();
  $builder->config({db => {type => 'Pg', tables_are_singular => 1}});
  $builder->parse('Users have many photo albums');

=head2 C<config>

The default configurations of a Builder object can be retrieved by:

  my $config = $builder->config();

This method accepts a hashref for configuring the Builder instance.

=head3 C<db>

The C<db> option configures database related settings, for instance:

  $builder->config({
    db => {
      name => 'product',
      type => 'Pg', # defaulted to 'mysql'
      host => '10.0.0.1',
      port => '5432',
      username => 'admin',
      password => 'password',
      tables_are_singular => 1,  # table name conventions, defaulted to undef
      table_prefix => 'test_', # specify a prefix for table names
      options => {RaiseError => 1} # database connection options
    }
  });

Database connection credentials are only required if you are planning to create or alter an existing database using the generated schema. Otherwise, C<type> and C<tables_are_singular> are the only required parameters that can affect the generated schemas.

=head3 C<format>

The C<format> option is a hash of coderefs that get triggered to sanitize the expression (sentences), table names, and column names. The expression, table names, or column names are passed to the callback coderef as the only argument.

=over

=item C<expression>

The default coderef formats the given expression (sentences) into lower case and strips out all unnecessary 'the', 'a', and 'an'. The word 'and' is converted to a comma.

=item C<table>

The default coderef trims the whitespaces from the beginning and the end of the given table name and convert all other space characters in between to underscore.

=item C<column>

The default coderef for formatting column names is identical to the one used to format table names.

=back

=head3 C<table>

This option defines the CREATE TABLE statement templates for various database types. The built-in supported databases are MySQL, PostgreSQL, and SQLite. This option allows us to change the CREATE TABLE statement for existing or new database types. For instance, we can change the default MySQL storage engine to MyISAM:

  $config->{table}->{mysql} = 'CREATE TABLE [% table_name %] ([% columns %]) TYPE=MyISAM;';

=head3 C<primary_key>

Builder adds a primary key to all the tables it generate. This option defines the default primary key name and the primary key column type for each database type.

  $config->{primary_key}->{name} = 'code'; # change to primary key name to 'code', defaulted to 'id'
  $config->{primary_key}->{type}->{Pg} = 'PRIMARY KEY'; # defaulted to 'SERIAL PRIMARY KEY'

=head3 C<foreign_key>

Similar to the C<primary_key> option, this defines various settings for foreign keys:

  $config->{foreign_key}->{suffix} = '_code'; # defaulted to '_id'
  $config->{foreign_key}->{type}->{mysql} = 'BIGINT'; # defaulted to 'INTEGER'
  $config->{foreign_key}->{clause} = 'FOREIGN KEY ([% foreign_key %]) REFERENCES [% reference_table %] ([% reference_primary_key %]) ON DELETE SET NULL'; # defaulted to 'ON UPDATE CASCADE ON DELETE CASCADE'

=head3 C<add_clause>

This option defines the ALTER TABLE statement to add foreign keys for 'has many' construct.

=head3 C<map_table>

This option defines table name of the mapping table when generating many to many relationships, which is defaulted to C<[% table_name %]_[% foreign_table_name %]_map>.

=head3 C<columns>

Builder has a list of built-in column definitions, which are essentially attribute name to column data type mappings. The default list of columns can be retrieved by:

  print join (', ', keys %{$builder->config()->{columns}});

Builder tries to match the name of given attribute to the column definitions defined in C<columns>. Failing that, it will use the built-in 'name' column definition, which is by default set to 'VARCHAR(255)'.

We can customise or add new column definitions to suit our needs, for example:

  $config->{columns}->{status} = qq(VARCHAR(10) DEFAULT 'Active');
  ...
  $builder->parse('Order has order number, purchase date, and status');

generates:
  
  CREATE TABLE orders (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_number NUMERIC,
    purchase_date DATE,
    status VARCHAR(10) DEFAULT 'Active'
  ) TYPE=INNODB;
 
=head2 C<parse>

C<parse> accepts a text string and returns the generated database table schemas. The input text string could be a series of sentences (delimited by periods) in one of the following constructs:

=over

=item "... has ..."

The "has" keyword can be used to define object attributes, i.e. the columns of a table, separated by commas. For instance:

  'Employee has first name, last name, and email'

It can be also used to establish "has a" relationships between tables: 

  'Employee has first name, last name, email, and position (has title and description).'

The above expression is equivalent to:

  'Position has title and description. Employee has first name, last name, email, and position ID (reference).'

The '(reference)' clause indicates that the attribute 'position ID' is a foreign key that references a table called 'position', assuming that table names are singular and no table prefix is defined.

We can also explicitly specify the actual referenced table. For instance, the expression:

  'A project has a name and a main task ID (references task)'

generates the following table schema for MySQL:

  CREATE TABLE project (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    main_task_id INTEGER,
    FOREIGN KEY (main_task_id) REFERENCES task (id) ON UPDATE CASCADE ON DELETE CASCADE
  ) TYPE=INNODB;

We can explicitly assign a column definition to an attribute, which ultimately determines the data type of the column. For instance:

  'Product has name and total (integer).'

generates: 

  CREATE TABLE product (
   id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
   name VARCHAR(255),
   total INTEGER
  ) TYPE=INNODB;

It is possible to define "has a" relationships between objects recursively in one sentence, although it may become convoluted. For example:

  'Employee has first name, last name, email, and position (has title, description, and classification (has category and sub category)).'

The word "has" and "have" are interchangeable in Builder.

=item "... has many ..."

We can add a "has many" relationship between two existing tables, for instance:

  'The company has many locations.'

generates:

  ALTER TABLE location ADD company_id INTEGER;
  
  ALTER TABLE location ADD FOREIGN KEY (company_id) REFERENCES company (id) ON UPDATE CASCADE ON DELETE CASCADE;

In essence, the "has many" keyword creates a foreign key in the corresponding table.
  
=item "... has many ... and vice versa"

This construct is a shortcut to establish a "many to many" relationship between two existing tables by generating the intermediate table. For instance:
  
  'Employees have many Projects and vice versa.'

The above line is equivalent to:

  'Employee project map has an employee ID (reference) and an project ID (reference).'

=item "... has ... as ..."

This construct allows us to add a "has a" relationship between existing tables, for instance:

  'Employee has a position as role.'

generates:

  ALTER TABLE employee ADD role_id INTEGER;
  
  ALTER TABLE employee ADD FOREIGN KEY (role_id) REFERENCES position (id) ON UPDATE CASCADE ON DELETE CASCADE;

=back

=head2 C<show>

C<show> returns the generated schemas in a readable format:

  print $builder->show();

=head2 C<build>

C<build> executes the generated schemas using the database connection credentials defined in C<config> or the provided database handler:

  $builder->build();
  
  # or,

  $builder->build($dbh);

=head1 SEE ALSO

L<Rose::DB::Object>, L<Rose::DBx::Object::Renderer>, L<DBI>

=head1 AUTHOR

Xufeng (Danny) Liang (danny.glue@gmail.com)

=head1 COPYRIGHT & LICENSE

Copyright 2009 Xufeng (Danny) Liang, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
