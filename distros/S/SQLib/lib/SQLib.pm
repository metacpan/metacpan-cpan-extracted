#!/usr/bin/perl

=head1 NAME

SQLib - A simple module to manage and store SQL queries in separate files.

=head1 VERSION

Version 0.05

=head1 AUTHOR

Mateusz Szczyrzyca, mateusz at szczyrzyca.pl

=head1 SYNOPSIS

The module allows to store SQL queries in separate files and provides easy 
access to them. This functionality is helpful if you want to separate a Perl 
code from a SQL code.

A file with list of queries has the following syntax:

 [NAME_OF_QUERY1]
 -- A SQL query with {vars} to replace 
 [/NAME_OF_QUERY1]

 [NAME_OF_QUERY2]
 -- A SQL query with {vars} to replace
 [/NAME_OF_QUERY2]

 ...

 [NAME_OF_QUERY_N]
 -- A SQL query with {vars} to replace
 [/NAME_OF_QUERY_N]

 [     QUERIES_WITH_SPACES_IN_NAME_ARE_POSSIBLE  ]
                -- A SQL query with spaces
 [     /   QUERIES_WITH_SPACES_IN_NAME_ARE_POSSIBLE       ]

First parenthesis "[" always starts from a new line (don't use whitespaces).

Empty lines between queries are ignored. If there are two or more SQL queries 
with same [NAME], then only one (first) will be used. 

If a query with a specified name doesn't exist then undef is returned as soon 
as if a file or query has an invalid syntax.

[QUERY_NAME]A sql code[/QUERY_NAME] isn't a valid syntax as well.


Simple example (file_with_queries.sql):

 [CHECK_PASSWORD]
 -- Comments for SQL debug
 -- Some::Program @ CHECK_PASSWORD
 -- Check a user password
 SELECT
  login,password
 FROM
  {table}
 WHERE
 (
   login = '{login}',
  AND
   password = '{password}'
 );
 [/CHECK_PASSWORD]

And how to use it in a perl code:

 use SQLib;
 my $SQLib = SQLib->new( './file_with_queries.sql' );

 my %sql_params =
 (
  table    => 'cms_users',
  login    => 'someuser',
  password => 'somepass'
 );

 my $check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );

In the above example $check_auth_query contains:

 -- Comments for SQL debug
 -- Some::Program @ CHECK_PASSWORD
 -- Check a user password
 SELECT
  login,password
 FROM
  cms_users
 WHERE
 (
   login = 'someuser',
  AND
   password = 'somepass'
 );

=cut

#####################################################################
#####################################################################
#####################################################################

package SQLib;
use utf8;
use strict;
use Tie::File;
our $VERSION = '0.05';

sub new
{
 my $class = shift;
 my $self = { file => $_[ 0 ] };

 die 'ERROR: Cannot find: ' . $self->{'file'} if ( ! -e $self->{'file'} );

 tie my @queries, 'Tie::File', $self->{'file'}
  or die 'SQLib: I cannot open the file with queries: ' . $self->{'file'};
 $self->{'queries'} = \@queries;
 bless $self, $class;
};

sub get_query
{
 my $self = shift;
 my $name = shift;
 my $params = shift;

 my @queries = @{ $self->{'queries'} };

 my $sql = "\n";
 my $reading;

 for my $i ( 0 .. $#queries )
 {
  last if ( $queries[ $i ] =~ m/^\[\s*\/\s*$name\s*\]$/ );
  next if ( $queries[ $i ] =~ m/^\s*$/ && !$reading );
  return undef if $reading && $queries[ $i ] =~ m/^\[/;

  if ( $reading )
  {
   $sql .= $queries[ $i ] . "\n";
   next;
  }

  if ( $queries[ $i ] =~ m/^\[\s*$name\s*\]\s*/ )
  {
   $reading = 1;
   next;
  }
 }

 ### The requested query doesn't exist
 return undef if !$reading;

 my %hash = %{ $params };

 foreach my $key ( sort ( keys ( %hash )  )  )
 {
  my $tmp = $hash{ $key };
  $sql =~ s/\{$key\}/$tmp/g;
 }

 return $sql;
};

1;
