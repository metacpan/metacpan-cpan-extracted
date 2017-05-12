#!/usr/bin/env perl
use 5.012000;
use DBI;
use Data::Dumper;
use strict; use warnings;
use Getopt::Compact;
use Fatal qw/ DBI::connect /;
use Pg::Corruption qw/ connect_db schema_name primary_keys dup_pks/;


my $att = { AutoCommit=>1 ,  Profile=>0, };

my $opt = new Getopt::Compact
              args   => '-d database  scheama.table ',
              modes  => [qw(verbose quiet)],
              struct =>  [ [ [qw(H host)],   'hostname' , '=s' ],
			   [ [qw(p port)],   'port'     , '=s' ], 
		   	   [ [qw(d db)],     'database' , '=s' ],
		   	   [ [qw(U user)],   'user'     , '=s' ],
		   	   [ [qw(W passwd)], 'passwd'   , '=s' ],
	];
my $o  = $opt->opts;
$o->{host}  //= 'localhost';
$o->{port}  //=  5432      ;
$o->{user}  //=  getlogin  ;
my ($schema,$table) = schema_name(shift);
$table    or do{ say $opt->usage and exit};
$o->{db}  or do{ say $opt->usage and exit};
$o->{help}  and say $opt->usage and exit 1;

my $dh  = connect_db($o);
my @pks = primary_keys($schema,$table,$dh,$o) ;
!@pks and say  qq(Exiting... no pk found in "schema.$table") and exit;

my $rows = dup_pks ($schema,$table, \@pks, $dh, $o) ;
say sprintf '%s -- %s ', ($rows?'not ok':'ok'), "$schema.$table"  if $o->{verbose} ;
exit $rows;

END { $dh and  $dh->rollback and $dh->disconnect };
