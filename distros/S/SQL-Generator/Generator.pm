# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

our $VERSION = '0.02';

require 5.005_62;

use warnings;

use Carp;

use Class::Maker;

package Object::ObjectList;

use Class::Maker::Examples::Array;

#use Types::Array;

Class::Maker::class
{
	isa => [qw(Array)],

	attribute =>
	{
		getset => [ qw/name blessed/ ],
	},
};

sub push_new
{
	my $this = shift;

	my %arghash = @_;

	my $obj;

	my $class = $this->blessed();

	unless( $class->can( 'new' ) )
	{
			::croak "Couldn't call method new via module '$class' :$@";
	}

	$obj = $class->new( %arghash );

	$this->push( $obj );

return $obj;
}

	# search our object list and return the obj with matching attributes

sub get_where
{
	my $this = shift;

	my %arghash = @_;

	my $key = shift @{ [ keys %arghash ] };

	my @results;

		foreach my $obj ( $this->get )
		{
			if( $obj->$key() eq $arghash{$key} )
			{
				push @results, $obj;
			}
		}

	return undef unless @results;

return wantarray ? @results : $results[0];
}

sub get_where_islike
{
	my $this = shift;

	my %arghash = @_;

	my $key = shift @{ [ keys %arghash ] };

	my @results;

		foreach my $obj ( @{ $this->get } )
		{
			if( $obj->$key() =~ /$arghash{$key}/ )
			{
				push @results, $obj;
			}
		}

return \@results;
}

package SQL::Generator::Argument;

Class::Maker::class
{
	attribute =>
	{
		getset =>
		[
			qw(replace pre post token parameter),

			qw(token_printf joinstr param_printf),

			qw(joinseperator),

			qw(hash_keyprintf hash_valueprintf hash_assigner),

			qw(array_valueprintf),
		],

		hash => [qw(argtypes)],
	},
};

require 5.005_62; use warnings; use strict;

# Preloaded methods go here.

sub _preinit
{
	my $this = shift;

	$this->pre('');
	$this->post('');

	$this->token_printf('%s');	# format tokenstring
	$this->param_printf('%s');	# format paramstring
	$this->joinstr(' ');

	$this->joinseperator(', ');	# what is the seperator between elements

	$this->hash_keyprintf('%s');	# do we should quote the keys ?
	$this->hash_valueprintf("'%s'");	# do we should quote the values ?
	$this->hash_assigner(' => ');	# string between key => value pairs

	$this->array_valueprintf('%s');	# do we should quote the values ?

	$this->replace( 0 );
}

sub _postinit
{
	my $this = shift;

	if( $this->pre )
	{
		$this->token_printf( $this->pre.$this->token_printf );	# format tokenstring
	}

	if( $this->post )
	{
		$this->param_printf( $this->param_printf.$this->post );	# format tokenstring
	}

	if( $this->replace )
	{
		$this->token('');

		$this->param_printf('%s');
	}

	unless( keys %{ $this->argtypes } )
	{
		$this->argtypes->{SCALAR} = 1;
	}
}

sub scalar_totext
{
	my $this = shift;

return sprintf( $this->param_printf, ref($this->parameter) ? ${$this->parameter} : $this->parameter );
}

sub array_totext
{
	my $this = shift;

	my @fields=();

	foreach my $field ( @{ $this->parameter } )
	{
		push @fields, sprintf( $this->array_valueprintf, $field );
	}

return sprintf( $this->param_printf, join( $this->joinseperator, @fields ) );
}

sub hash_totext
{
	my $this = shift;

	my @fields=();

	while( my ($key, $value) = each %{$this->parameter} )
	{
		my $field='';

		$field .= sprintf( $this->hash_keyprintf, $key );

		$field .= $this->hash_assigner;

		$field .= sprintf( $this->hash_valueprintf, $value );

		push @fields, $field;
	}

return sprintf( $this->param_printf, join( $this->joinseperator, @fields ) );
}

sub param : method
{
	my $this = shift;

		my $param = shift;

			my $type = ref( $param ) || 'SCALAR';

			unless( $this->testType( $type ) )
			{
				::carp  'Incorrect type ', $type, ', use ', join( ' or ',$this->wantType ), ' instead';
			}

return $this->parameter( $param );
}

sub reset : method
{
	my $this = shift;

		$this->parameter( undef );
return;
}

sub wantType : method
{
	my $this = shift;

		my @allowed = ();

		foreach ( keys %{ $this->argtypes } )
		{
			if( $this->argtypes->{$_} )
			{
				push @allowed, $_;
			}
		}

return @allowed;
}

	# tests wether the given type is allowed and with undef argument returns list of allowed
	# types

sub testType($) : method
{
	my $this = shift;

		my $type = shift;

		if( $this->argtypes->{'ALL'} )
		{
			return 'ALL';
		}

		if( $this->argtypes->{$type} )
		{
			return $type;
		}

return undef;
}

	#
	# translates the element to a sql language element
	#

sub totext : method
{
	my $this = shift;

	my $pre = sprintf( $this->token_printf, $this->token );	# format tokenstring

	if( $pre )
	{
		$pre .= $this->joinstr;
	}

	my $type =  ref( $this->parameter ) || 'SCALAR';

	if( $type eq 'ARRAY' )
	{
		return $pre.$this->array_totext( $this->parameter );
	}
	elsif( $type eq 'HASH' )
	{
		return $pre.$this->hash_totext( $this->parameter );
	}
	else
	{
		return $pre.$this->scalar_totext( $this->parameter );
	}

return undef;
}

package SQL::Generator::Command;

Class::Maker::class
{
	can => [qw( validate )],

	attribute =>
	{
		getset => [qw(id subobject prettyprint)],

		array => [qw(template required)],

		hash => [qw(arguments subobjects defaults)],
	},
};

require 5.005_62;

use strict;

use warnings;

# Preloaded methods go here.

sub _preinit : method
{
	my $this = shift;

		$this->prettyprint( '' );

return;
}

sub _postinit : method
{
	my $this = shift;

			# generate 'Argument' instances for every arg of the template

		foreach my $arg ( @{ $this->template } )
		{
			if( exists $this->arguments->{$arg} )
			{
				$this->arguments->{$arg} = new SQL::Generator::Argument( token => $arg, %{ $this->arguments->{$arg} } );
			}
			else
			{
				$this->arguments->{$arg} = new SQL::Generator::Argument( token => $arg, argtypes => { SCALAR => 1 } );
			}
		}

return;
}

sub validate : method
{
	my $this = shift;

		my $href_args = shift;

			# validate if all required fields are existing

		my @missing = ();

		foreach my $element ( @{ $this->required } )
		{
			if( not exists $href_args->{$element} )
			{
				if( not exists $this->defaults->{$element} )
				{
					push @missing, $element;
				}
			}
		}

		die sprintf( 'Required argument(s) (%s) %s missing (defaults: %s)', join( ', ',@missing ), @missing > 1 ? 'are' : 'is', join( ', ', keys %{ $this->defaults } ) ) if @missing;

return 1;
}

sub totext
{
	my $this = shift;

		my $href_args = shift;

		$this->validate( $href_args );

		my @construct;

		foreach my $element ( @{ $this->template } )
		{
			#$this->debugPrint( sprintf "%s( '%s' %s )\n",$this->id, $element, (exists $href_args->{$element}) ? 'EXISTS' : 'NOT FOUND' );

			# defaults should be use, if value is missing ## ERROR/WARN: ONLY WHEN IT IS A REQUIRED ELEMENT ...see validate !!

			unless( exists $href_args->{$element} )
			{
				if( exists $this->defaults->{$element} )
				{
					$href_args->{$element} = $this->defaults->{$element};
				}
			}

			if( exists $href_args->{$element} )
			{
				if( my $subcmd = $this->subobjects->{$element} )
				{
					$this->arguments->{$element}->param( $subcmd->totext( $href_args ) );
				}
				else
				{
					$this->arguments->{$element}->param( $href_args->{$element} );
				}

				push @construct, sprintf '%s%s', $this->arguments->{$element}->totext(), $this->prettyprint;

				$this->arguments->{$element}->reset();
			}
		}

return join( ' ', @construct);
}

package SQL::Generator;

Class::Maker::class
{
	attribute =>
	{
		getset =>
		[
			qw/command pre post autoprint prettyprint  historysize/,

			qw/table database where/,

			qw/lang langrules file handle/,
		],

		array => [ qw/history/ ],

		hash => [ qw/defaults/ ],
	},
};

use strict;

use IO::File;

use vars qw($AUTOLOAD $VERSION);

use Exporter;

our %EXPORT_TAGS = ( 'all' => [ qw( ) ]  );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

# Preloaded methods go here.

sub _preinit
{
	my $this = shift;

	$this->pre( '' );

	$this->post( '' );

	$this->autoprint(0);

	$this->prettyprint(0);

	$this->historysize(100);

	$this->lang( 'MYSQL' );

	$this->file( undef );

	#$this->debugOn;
}

sub close
{
	my $this = shift;

	if( defined $this->handle() )
	{
		$this->handle->close();
	}
}

sub _postinit
{
	my $this = shift;

	$this->change_dialect( $this->lang );

	if( $this->file )
	{
		$this->debugPrint( sprintf "opening file %s as STDOUT", $this->file );

		$this->handle( new IO::File( $this->file ) ) ;

		unless( defined $this->handle() )
		{
			die sprintf "FAILURE: opening file %s as STDOUT", $this->file;
		}
	}
}

sub dialect_path
{
	my $this = shift;

		my $lang = shift || $this->lang;

return 'SQL::Generator::Lang::'.$lang;
}

sub change_dialect
{
	my $this = shift;

		my $lang = shift;

		#die "WE DIE HERE";

		my $dialect = $this->dialect_path($lang);

		eval "require $dialect";

		if( $@ )
		{
			::croak "Couldn't change/load language module '$dialect' :$@";
		}

		# update rules via new CommandList instance: SQL::Generator::Lang::*->new()

		$this->langrules( $dialect->new() );

		die "Failed loading language module" unless $this->langrules;

return $this->lang( $lang );
}

sub DEFAULT : method
{
	my $this = shift;

		my %args = @_;

		$this->defaults( \%args );

#		foreach my $key ( keys %{ $this->defaults } )
#		{
#			print "SETTING DEFAULT: $key => ", $args{$key}, "\n\n";
#		}

return;
}

sub AUTOLOAD
{
	my $func = $AUTOLOAD;

	$func =~ s/.*:://;

	return if $func eq 'DESTROY';

	my $this = shift;

		my %args = @_;

		my $result;

			# only single command per func in this version !!! we take the first one...

		my ( $cmd ) =  $this->langrules->get_where( id => $func );

		if(  defined $cmd )
		{
			$cmd->defaults( \%{ $this->defaults } );

			$result = sprintf '%s %s', $func, $cmd->totext( \%args );

			$result = $this->pre.$result.$this->post;

			if( $result eq 1 )
			{
				die "DONT KNOW WHAT THE HELL HAPPENED";
			}
		}
		else
		{
			warn( "Can't find command for $func in ", $this->dialect_path );
		}

		$this->handle->print($result) if $this->file;

		print $result if $this->autoprint;

		if( $this->history )
		{
			if( @{ $this->history } < $this->historysize )
			{
				push @{ $this->history }, $result;
			}
		}

return $result;
}

sub dump_history
{
	my $this = shift;

	my $pre = shift;

	my $post = shift;

		foreach ( @{ $this->history } )
		{
			print $pre || '', $_, $post || '';
		}

		@{ $this->history } = [];
}

1;

__END__

=head1 NAME

SQL::Generator - Generate SQL-statements with oo-perl

=head1 SYNOPSIS

  use SQL::Generator;

=head1 DESCRIPTION

With this module you can easily (and very flexible) generate/construct sql-statements. As a rookie, you
are used to write a lot of sprintf`s every time i needed a statement (i.e.for DBI). Later you start
writing your own functions for every statement and every sql-dialect (RDBMS use to have their own dialect
extending the general SQL standard). This SQL::Generator module is an approach to have a
flexible abstraction above the statement generation, which makes it easy to implement
in your perl code. Its main purpose is to directly use perl variables/objects with SQL-like code.

=head1  CLASSES

SQL::Generator

=head1 USE

Carp

=head1 CLASS METHODS

=cut

=head2 close

Destructor.

=cut

=head2 dialect_path( $dialect )

Returns the perl 'use' module path of the dialect.

=cut

=head2 change_dialect( $dialect )

Loads commandset for the dialect. Afterwards SQL::Generator  interprets its calls with this dialect.

=cut

=head1 Method B<>

=cut

=head2 dump_history

=cut

=pod

=head1 INSTALL

=head2 Standard configuration, just type in your shell:

	perl Makefile.PL
	make
	make test
	make install

=head3 or if CPAN module is working, type in your shell:

	perl -MCPAN -e 'shell install SQL::Generator'

=head2 Win32 enviroment (which have Microsoft Developer Studio installed), type in your shell:

	perl Makefile.PL
	nmake
	nmake test
	nmake install

=head3 or using CPAN, type in your shell:

	perl -MCPAN -e "shell install SQL::Generator"

=head1 EXPORT

None.

=head1 METHODS

=head2 new( ... )

new is the class constructor. It accepts a hash list of following arguments:

=over 4

=item B<LANG>	=>	(string)	.i.e.: 'MYSQL'

LANG is optional; Following alternatives are possible:

MYSQL (default), ORACLE, SQL92

This is the generator-engine specifier. It tells the SQL::Generator which dialect of
the SQL-B<LANG>UAGE will be generated / produced / constructed. This distribution only
supports a very limited subset of the MYSQL (version 3.22.30) sql command set. The
transparent implementation invites everyone to extend/contribute to the engine (have
a look at IMPLEMENTATION near the end of this document). You may also use 'ORACLE' or
'SQL92' as a parameter, but they simply represents a copy of the 'MYSQL' implementation
and were added for motivating to extend the interface (of course not tested for real
compability yet).

=item B<FILE>	=>	(string)	.i.e.: '>filename.sql'

FILE is optional;

A filename for alternativly dumping the generated sql output to a file.This should be
valid filename as used by IO::File open function. The parameter is directly forwared to
this function, therefore the heading mode controllers are significant, but you should
only use only output modes (">", ">>", ..) because SQL::Generator will only print to
the handle.

=item B<PRE> =>		(string)	.i.e.: "$line)\t\t"

PRE is optional.

A string which will be concated before each generated sql command.

PRE() is also a method, which may be called anywhere in the lifetime of an
SQL::Generator instance and will have an impact on further behaviour.

=item B<POST> =>	(string)	.i.e.: ';\n\n'

POST is optional.

A string which will be concated after each generated sql command.

POST() is also a method, which may be called anywhere in the lifetime of an
SQL::Generator instance and will have an impact on further behaviour.

=item B<AUTOPRINT> =>	(boolean)	.i.e. 0

AUTOPRINT is 0 (false) per default.

Normally when an SQL-generating method is called, it returns the result as a string,
which may printed or stored or whatever. If you want that the method is also echoing
the command to STDOUT, so turn this switch on (1).

AUTOPRINT() is also a method, which may be called anywhere in the lifetime of an
SQL::Generator instance and will have an impact on further behaviour.

=item B<prettyprint> =>	(boolean)	.i.e. 0

prettyprint is 0 (false) per default.

=item B<history> =>	(boolean)	.i.e. 0

history is 0 (false) per default.

=item B<historysize> =>	(scalar)	.i.e. 50 [lines]

historysize is 100 lines per default.

=item B<debug> =>	(boolean)	.i.e. 0

debug is 0 (false) per default.

If true (1), it turns some diagnostic printings on, but should be used from very
advanced users only.

debug() ,debugOn() or debugOff are also methods, which may be called anywhere in the
lifetime of an SQL::Generator instance and will have an impact on further behaviour.

=back

=cut

=pod

=head2 changLang( 'LANGID' )

see new( LANG ) argument description above.

Changes the (current) SQL language module. It accepts following arguments:

=over 4

=item B<LANGID>	(string)	.i.e.: 'MYSQL'

LANG is not optional; Following alternatives in this dist are possible:

MYSQL (default), ORACLE, SQL92

It changes the generator-language module (it is simply another module loaded), which
switches the translation to another SQL dialect which controlls how the output is
generated / produced / constructed. Generally it looks for <LANGID>.pm in a subpath
'Generator/Lang/' of the distribution (have a look at IMPLEMENTATION section near the
end of this document).

=back

=cut

=pod

=head2 totext( RULE )

For advanced users only ! Interprets (current) command with a rule. It accepts
following arguments:

=over 4

=item B<RULE>	(a SQL::Generator::Command instance)

RULE is not optional;

It translates the perl function call (via AUTOLOAD) to an SQL function. For the
construction of the SQL it uses an SQL::Generator::Command instance, which holds
the information how to transform the function parameters to an SQL string.

see the SQL::Generator::Command pod for specific description.

=back

=cut

=head1 EXAMPLE 1 (see test.pl in the dist-directory)

=head2 DESCRIPTION

A very simple example. It instanciates the generator and creates some example output, which
could be simply piped to an mysql database for testing (be careful if tables/database name is
existing. I guess not !).

=head2 CODE

my $table = 'sql_statement_construct_generator_table';

my $database = 'sql_statement_construct_generator_db';

my %types =
(
	row1 => 'VARCHAR(10) AUTO_INCREMENT PRIMARY KEY',

	row2 => 'INTEGER',

	row3 => 'VARCHAR(20)'
);

my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

my %alias = ( row1 => 'Name', row2 => 'Age', row3 => 'SocialID' );

	my $sql = new SQL::Generator(

		LANG => 'MYSQL',

		post => ";\n",

		history => 1,

		autoprint => 0,

		prettyprint => 0

	) or die 'constructor failed';

	$sql->CREATE( DATABASE => $database );

	$sql->USE( DATABASE => $database );

	$sql->CREATE( COLS => \%types, TABLE => $table );

	$sql->DESCRIBE( TABLE => $table );

	$sql->INSERT(

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table

		);

	foreach (keys %columns)	{ $columns{$_}++ }

	$sql->INSERT( SET => \%columns , INTO => $table );

	foreach (keys %columns)	{ $columns{$_}++ }

	$sql->REPLACE(

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table,

		);

	$sql->SELECT( ROWS => '*', FROM => $table );

	$sql->SELECT( ROWS => [ keys %types ], FROM => $table );

	$sql->SELECT(

		ROWS =>  \%alias,

		FROM => $table,

		WHERE => 'row1 = 1 AND row3 = 3'

		);

	$sql->DROP( TABLE => $table );

	$sql->DROP( DATABASE => $database );

	# evocate an errormsg

	print "\nDumping sql script:\n\n";

	for( $sql->HISTORY() )
	{
		printf "%s", $_;
	}

=head2 OUTPUT OF EXAMPLE 1

CREATE DATABASE sql_statement_construct_db;
USE sql_statement_construct_db;
CREATE TABLE sql_statement_construct_table ( row1 VARCHAR(10) AUTO_INCREMENT PRIMARY KEY, row2 INTEGER, row3 VARCHAR(20) );
DESCRIBE sql_statement_construct_table;
INSERT INTO sql_statement_construct_table ( row1, row2, row3 ) VALUES( 1, 2, 3 );
INSERT INTO sql_statement_construct_table SET row1='2', row2='3', row3='4';
REPLACE INTO sql_statement_construct_table ( row1, row2, row3 ) VALUES( 3, 4, 5 );
SELECT * FROM sql_statement_construct_table;
SELECT row1, row2, row3 FROM sql_statement_construct_table;
SELECT row1 AS 'Name', row2 AS 'Age', row3 AS 'SocialID' FROM sql_statement_construct_table WHERE row1 = 1 AND row3 = 3;
DROP TABLE sql_statement_construct_table;
DROP DATABASE sql_statement_construct_db;

=head1 EXAMPLE 2

=head2 DESCRIPTION

This example is uses the perl AUTOLOAD/BEGIN/END features. With this script template,
you are enabled to write very straightforward code, without even sensing the OO architecture
of the SQL::Generator implementation. Therefore you can directly use "functions" instead of writing
method syntax.

It looks like a new SQL script language with perl powerfeatures. It tastes like an "embedded SQL"
script, but you can simply change the destination SQL database language with one parameter.

=head2 CODE

use strict;
use vars qw($AUTOLOAD);

my $sql;

BEGIN
{
	use SQL::Generator;

	$sql = new SQL::Generator(

		LANG => 'ORACLE',

		FILE => '>create_table.oraclesql',

		post => ";\n",

		autoprint => 1,

		) or print 'object construction failed';
}

END
{
	$sql->close();
}

sub AUTOLOAD
{
	my $func = $AUTOLOAD;

	$func =~ s/.*:://;

    	return if $func eq 'DESTROY';

	my %args = @_;

	$sql->$func( %args );
}

## PERL/SQL STARTS HERE ##

my $table = 'sql_statement_construct_generator_table';

my $database = 'sql_statement_construct_generator_db';

my %types =
(
	row1 => 'VARCHAR(10) AUTO_INCREMENT PRIMARY KEY',

	row2 => 'INTEGER',

	row3 => 'VARCHAR(20)'
);

my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

my %alias = ( row1 => 'Name', row2 => 'Age', row3 => 'SocialID' );

	CREATE( DATABASE => $database );

	USE( DATABASE => $database );

	CREATE( TABLE => $table, COLS => \%types );

	DESCRIBE( TABLE => $table );

	INSERT( SET => \%columns , INTO => $table );

	DROP( TABLE => $table );

	DROP( DATABASE => $database );

=head2 OUTPUT OF EXAMPLE 2

CREATE DATABASE sql_statement_construct_db;
USE sql_statement_construct_db;
CREATE TABLE sql_statement_construct_table ( row1 VARCHAR(10) AUTO_INCREMENT PRIMARY KEY, row2 INTEGER, row3 VARCHAR(20) );
DESCRIBE sql_statement_construct_table;
INSERT INTO sql_statement_construct_table SET row1='2', row2='3', row3='4';
DROP TABLE sql_statement_construct_table;
DROP DATABASE sql_statement_construct_db;

=head1 IMPLEMENTATION

see the SQL::Generator::Lang::MYSQL pod documentation for how to easily extend the archive
of generators sql-standard/non-standard languages.

SQL::Generator::Debugable	Baseclass for symdumps, croaks and intelligent debugging.
SQL::Generator::Argument		Class that implements the translation on command argument
				level and also formats the perl function arguments to text.
SQL::Generator::Command	Class that holds the configuration of the arguments of the
				SQL-command versus perl-function.
Object::ObjectList	A list class for Command's (SQL-commands) which defines
				the language.
SQL::Generator::Lang::*		A subclass of CommandList which is dynamically used for
				SQL generation. Dictates the language conformance.

=head1 SUPPORT

By author. Ask comp.lang.perl.misc or comp.lang.perl.module if you have very general
questions. Or try to consult a perl and SQL related mailinglist before.

If all this does not help, contact me under my email below.

=head1 AUTHOR

Murat Uenalan, muenalan@cpan.org

=head1 COPYRIGHT

    The SQL::Generator module is Copyright (c) 1998-2002 Murat Uenalan. Germany. All rights reserved.

    You may distribute under the terms of either the GNU General Public
    License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

perl(1), DBI, DBIx::*, DBD::*

=cut
