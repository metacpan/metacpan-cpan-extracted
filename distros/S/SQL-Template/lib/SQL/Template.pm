package SQL::Template;

use warnings;
use strict;

use Carp;
use DBI qw(:sql_types);
use SQL::Template::XMLBuilder;

=head1 NAME

SQL::Template - A new way to organize your database code

=head1 VERSION

Version 0.2.4

=cut

our $VERSION = '0.2.4';

=head1 SYNOPSIS

   use SQL::Template;
   
   my $sql = SQL::Template->new(-filename=>"my-custom-sqls.xml");
   my $dbh =DBI->connect("dbi:SQLite:dbname=example.sqlite","","");
   
   #Simple record insert
   $sql->do("insert_country", $dbh, {COUNTRY_ID=>'ES', NAME=>'SPAIN'} );

   # fetch records
   my $stmt = $sql->select_stmt("query_for_persons", $dbh, {NAME=>'JOHN'} );
   while( my $hr = $stmt->fetchrow_hashref ) {
      print $hr->{NAME}, "\n";
   }
   $stmt->finish;
   
   
   ### file: my-custom-sqls.xml
   <?xml version="1.0" encoding="iso-8859-1"?>
   
   <st:sql>
   <st:do name="insert_country" >
      INSERT INTO COUNTRY(COUNTRY_ID, NAME)
      VALUES( ${COUNTRY_ID}, ${NAME} )
   </st:do>
   
   <st:select name="query_for_persons" >
      SELECT * FROM PERSON 
      <st:if test="${NAME}" prepend="WHERE">
         NAME=${NAME}
      </st:if>
   </st:select>	   
   
   </st:sql>
   
=cut

=head1 DESCRIPTION

Write SQL sentences in external files and use them from Perl.

Imagine this situation: you know DBI and you like it, because you can make use of
your SQL knowledge. But you are not happy having the SQL code into the Perl code.
You can use other CPAN modules, which let us to abstract SQL code. But we want to
write SQL code, we feel confortable with it.

This module decouples SQL sentences from Perl code, writting sentences in a XML file,
that you can use in different parts of your code. SQL::Template allows dynamic test of
expressions, and reuse of fragments.

The SQL handled sentences are SQL-inyection free; SQL::Template make use of parameter
binding.

=head1 XML file

The XML file contains the SQL sentences that you will use with SQL::Template. This is more
than a dictionary container, it allows us to build dinamyc SQL and reuse fragments.

=head2 General

The different parts are enclosed between C<< <st:sql> >> and C<< </st:sql> >>

   <?xml version="1.0" encoding="iso-8859-1"?>
   <st:sql>

   <!-- file contents -->

   </st:sql>

=head2 st:do

This command is used to make DDL sentences or INSERT, UPDATE and DELETE. For example:

   <st:do name="update_named_1" >
      UPDATE AUTHOR SET NAME=${NAME}, FIRST_NAME=${FIRSTNAME, SQL_VARCHAR} 
      WHERE AUTHOR_ID=${ID}
   </st:do>

This simple command shows us important things:

=over

=item name

The name attribute is mandatory, and it will be used to link the Perl code with the SQL

=item parameters

Parameters tou pass with a HASH reference to SQL::Template are binding to the SQL. In the
previous example, C<${NAME}> and C<${FIRSTNAME, SQL_VARCHAR}>. The fisrt is the simple use,
where the parameter will be replaced (using DBI bind). The second one will be used if you
need to indicate the data type. 

=back


=head2 st:select

If we need to make SELECT sentences, the command C<st:select> will be used. This is a simple
example:

   <st:select name="query_for_author" >
      SELECT * FROM AUTHOR WHERE AUTHOR_ID=${ID}
   </st:select>

Like the previous one, you can bind parameters with the C<${variable}> syntaxt


=head2 st:fragment

When we are writting SQL sentences, there are many of them similar, changing specific parts. 
I think that you can reuse SQL fragments in order to reduce the code you write, and to make
the maintenance easier.

=over 2

=item define a fragment

   <st:fragment name="filter_authors_with_A">
      AND NAME LIKE 'A%'
   </st:fragment>
	
=item use it

   <st:select name="query_for_authors_with_A" >
      SELECT * FROM AUTHOR WHERE AUTHOR_ID=${ID}
      <st:include name="filter_authors_with_A"/>
   </st:select>

=back

=head2 Dynamic sentences

SQL::Template dynamic feature is simple and strong. It allow us to write comple SQL
sentences that can be different depending on parameters values. For example:

   <st:select name="query_named_1" >
      SELECT * FROM AUTHOR
      WHERE YEAR=${YEAR}
      <st:if test="${GENDER} eq 'F'" prepend="AND">
			CITY != ${CITY}
      </st:if>
      <st:else>
         AGE > 18
      </st:else>		
   </st:select> 

As you can see, C<< <st:if> >> command is used to build dynamic SQL. The "if" command
can be used in C<< <st:do> >> and C<< <st:fragment> >>. It's composed by:

=over 2

=item test

Any valid Perl expression, where you can bind the parameters. SQL::Templante will eval
this expression in order to calculate the result. Boolean "true" or "false" rules are the
same that Perl uses in boolean expressions

=item prepend

If the test expression returns "true", prepend this text to the SQL block enclosed by "st:if".
It isn't mandatory.

=item <st:else>

The common "else" section in any "if" block. It isn't mandatory, and it will be used if
the test expression returns false.

=back

=head1 METHODS

SQL::Template methods are written in a way that it's similar to DBI interface, so I hope
you will be confortable with them. 


=head2 new ( option=>value )

The C<new()> function takes a list of options and values, and returns
a new B<SQL::Template> object which can then be used to use SQL sentences. 
The accepted options are (one of them is mandatory):

=over

=item -filename

This determines the XML file which contains the SQL sentences. The object
creation phase involves parsing the file, so any error (like syntax) cause 
an exception throw. If everything is fine, all commands searched are cached 
in order to improve the performance

=item -string

If you prefer to build a string with XML-syntax, you can build a SQL::Template
object in that way.

=back

=cut

#******************************************************************************

sub new {
	my ($class, %param) = @_;
	my $builder = SQL::Template::XMLBuilder->new;
	
	if( $param{-filename} ) {
		croak "XML config file not found [$param{-filename}]" unless(-e $param{-filename});
		$builder->parse_file( $param{-filename} );
	}
	elsif( $param{-string} ) {
		$builder->parse_string( $param{-string} );
	}
	else {
		croak "XML config file not specified";
	}
	
	my $self = {
		COMMANDS => $builder->get_commands
	};
	return bless $self, $class;
}

#******************************************************************************

sub _prepare_and_bind {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $command = $self->{COMMANDS}->{lc($name)};
	croak "Command not found: $name" if(!$command);
	my $sql = $command->sql($params);
	my $bindings = $command->bindings($params);
	
	my @matches = $sql =~ m!(\$\{\s*\w+\s*\})!gx;
	$sql =~ s!\$\{\s*\w+\s*\}!?!gx;
	
	my $stmt;
	eval {
		$stmt = $dbh->prepare($sql);
	};
	croak "${@}with SQL: $sql" if($@);
	
	if( $bindings ) {
		my $pcount = 1;
		foreach my $key( @matches ) {
			if( ! exists($bindings->{$key}) ) {
				croak "parameter not found: $key";
			}
			elsif( $bindings->{$key} and ('ARRAY' eq ref($bindings->{$key}) ) ) {
				$stmt->bind_param($pcount++, $bindings->{$key}->[0], eval($bindings->{$key}->[1]) );
			}
			else {
			#print "BIND: $key => ", $bindings->{$key}, "\n";
				$stmt->bind_param($pcount++, $bindings->{$key});
			}
		}
	}
	return $stmt;
}

#******************************************************************************

=head2 select_stmt ( $name, $dbh, $params, $attrs )

This method search in the command cache, and if it's found, SQL::Template
try to apply the params and execute in provided database handle. These are
the arguments:

=over

=item $name

The name of SQL sentence to use. This must match with a sentence in the
XML file.

=item $dbh

The database handle to be used. Note tat SQL::Template doesn't establish a
connection with your DB, it only use the one you want.

=item $params

When the SQL sentence needs parameters, you must provide them with a hash 
reference variable.

=item $attrs

Any aditional attribute you need to pass to the database driver, it will be used
in the DBI commands. Typically, you don't use this param.

=back

This methods use the following DBI functions: prepare, bind_param, execute. It 
returns a DBI::st handle, you can fetch in the habitual way. For example:

   my $stmt = $sql->select_stmt("query_for_persons", $dbh, {NAME=>'JOHN'} );
   while( my @row = $stmt->fetchrow_array ) {
      print "@row\n";
   }
   $stmt->finish;

=cut

sub select_stmt {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->_prepare_and_bind($name, $dbh, $params, $attrs);
	$stmt->execute;
	return $stmt;
}

=head2 selectrow_array ( $name, $dbh, $params, $attrs )

This method interface is similar to the previous you have seen 
in section L</"select_stmt">.
In this case, SQL::Template makes a call to DBI C<fetchrow_array>
function and C<finish> the statement handle, returning an array
with the results

=cut

sub selectrow_array {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->select_stmt($name, $dbh, $params, $attrs);
	my @row = $stmt->fetchrow_array;
	$stmt->finish;
	return @row;
}

=head2 selectrow_arrayref ( $name, $dbh, $params, $attrs )

This method interface is similar to the previous you have seen 
in section L</"selectrow_array">.
In this case, SQL::Template makes a call to DBI C<fetchrow_arrayref>
function and C<finish> the statement handle, returning an array reference
with the results

=cut

sub selectrow_arrayref {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->select_stmt($name, $dbh, $params, $attrs);
	my $row = $stmt->fetchrow_arrayref;
	$stmt->finish;
	return $row;
}

=head2 selectrow_hashref ( $name, $dbh, $params, $attrs )

This method interface is similar to the previous you have seen 
in section L</"selectrow_array">.
In this case, SQL::Template makes a call to DBI C<fetchrow_hashref>
function and C<finish> the statement handle, returning a hash reference
with the results

=cut

sub selectrow_hashref {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->select_stmt($name, $dbh, $params, $attrs);
	my $href = $stmt->fetchrow_hashref;
	$stmt->finish;
	return $href;
}


=head2 selectall_arrayref

This method combines "prepare", "execute" and "fetchall_arrayref" into a single call. 
It returns a reference to an array containing a reference to an array (or hash, see below) 
for each row of data fetched.
This method interface is similar to the previous you have seen 
in section L</"selectrow_array">.

See DBI C<selectall_hashref> method for more details.

=cut

sub selectall_arrayref {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->select_stmt($name, $dbh, $params, $attrs);
	my $aref = $stmt->fetchall_arrayref;
	$stmt->finish;
	return $aref;
}

=head2 selectall_hashref

This method combines "prepare", "execute" and "fetchall_arrayref" into a single call. 
It returns a reference to an array containing a reference to an hash 
for each row of data fetched.
This method interface is similar to the previous you have seen 
in section L</"selectrow_array">.

See DBI C<selectall_hashref> method for more details.

=cut

sub selectall_hashref {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->select_stmt($name, $dbh, $params, $attrs);
	my $href = $stmt->fetchall_hashref;
	$stmt->finish;
	return $href;
}


=head2 do ( $name, $dbh, $params, $attrs )

This method interface is similar to the previous you have seen 
in section L</"select_stmt">. The main use of this function is 
to execute DDL commands and INSERT, UPDATE or DELETE commands.
In this case, SQL::Template makes a call to DBI C<execute>
function and returns its results to the caller.

=cut


sub do {
	my ($self, $name, $dbh, $params, $attrs) = @_;
	my $stmt = $self->_prepare_and_bind($name, $dbh, $params, $attrs);
	return $stmt->execute;
}

#*************************************************************************

=head1 AUTHOR

prz, C<< <niceperl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-template at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Template>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Template


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SQL-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SQL-Template>

=item * Search CPAN

L<http://search.cpan.org/dist/SQL-Map/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 prz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;
