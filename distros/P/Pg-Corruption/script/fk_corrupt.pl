#!/usr/bin/env perl
use 5.012000;
use DBI;
use Data::Dumper;
use strict; use warnings;
use Getopt::Compact;
use Fatal qw/ DBI::connect /;
use Pg::Corruption qw/ connect_db schema_name  foreign_keys dup_fks /;

my $att = { AutoCommit=>1 ,  Profile=>0, };

my $opt = new Getopt::Compact
              #args   => '[option]...',
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

my $dh  =  connect_db($o);
my @fks =  foreign_keys($schema, $table, $dh);
!@fks and  say  qq(Exiting... no fk found in "$schema.$table" ) and exit;
my $ret = dup_fks ([@fks], $dh,$o);
say sprintf '%s -- %s ', ($ret? 'ok':'not ok'), "$schema.$table"  if $o->{verbose} ;
exit ($ret//'' cmp 'ok'? 1 : 0);

END { $dh and $dh->rollback and   $dh->disconnect }
