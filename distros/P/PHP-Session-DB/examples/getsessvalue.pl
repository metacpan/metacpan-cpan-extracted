use strict;
use PHP::Session::DB;
use Getopt::Std;

# Usage: perl getsessvalue.pl -u [dbuname] -p [dbpasswd] -n [dbname] -t [dbtype] -T [dbtable] -h [dbhost] -P [dbport] -s [sessionid] [variable]
# where [dbuname] is the database username
#       [dbpasswd] is dbuname's password
#	[dbname] is the database name
#       [dbtype] is a valid DBI driver (default: mysql)
#       [dbtable] is the table where the sessions are stored (default: sessions)
#       [dbhost] database host (default: localhost)
#	[dbport] database port (default: 3306)
#	[sessionid] is your session id
#	[variable] is the variable whose value you want to retrieve
my %arg;
getopts("u:p:n:t:T:h:P:s:",\%arg);

# Default values
my $uname = $arg{u};
my $passwd = $arg{p};
my $name = $arg{n};
my $type = $arg{t} || 'mysql';
my $table = $arg{T} || 'sessions';
my $host = $arg{h} || 'localhost';
my $port = $arg{P} || 3306;
my $sessid = $arg{s};

if(!$ARGV[0]) {
  print <<EOF;
PHP::Session::DB example - Coded by Roberto Alamos Moreno <ralamosm\@cpan.org>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Usage: perl $0 -u [dbuname] -p [dbpasswd] -n [dbname] -t [dbtype] -T [dbtable] -h [dbhost] -P [dbport] -s [sessionid] [variable]
where [dbuname] is the database username
      [dbpasswd] is dbuname's password
      [dbname] is the database name
      [dbtype] is a valid DBI driver (default: mysql)
      [dbtable] is the table where the sessions are stored (default: sessions)
      [dbhost] database host (default: localhost)
      [dbport] database port (default: 3306)
      [sessionid] is your session id
      [variable] is the variable whose value you want to retrieve

EOF

  exit -1;
}

my $session = PHP::Session::DB->new($sessid,{DBUSER => $uname, DBPASSWD => $passwd, DBNAME => $name});
my $var = $session->get($ARGV[0]);
if($var eq '') {
  print $ARGV[0]." not found\n";
} else {
  print $ARGV[0]."=".$var."\n";
}
