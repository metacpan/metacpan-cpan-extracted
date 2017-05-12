#!/usr/bin/perl

use strict;

sub nvl { defined $ENV{$_[0]} ? $ENV{$_[0]} : $_[1] }

eval { require DBI };
eval { require DBD::Pg };
eval { require DBD::mysql };
eval { require DBD::SQLite };
eval { require DBD::Informix };
eval { require DBD::Oracle };

print STDERR "\n##\n";

foreach my $pkg (qw(DBI DBD::Pg DBD::mysql DBD::SQLite DBD::Informix DBD::Oracle ))
{
  no strict 'refs';
  if(defined(my $version = ${$pkg . '::VERSION'}))
  {
    print STDERR sprintf("## %-15s %s\n", $pkg, $version);
  }
}

print STDERR<<"EOF";
##
## WARNING: Almost all the tests in this module distribution need to connect
## to a database in order to run.  The tests need full privileges on this
## database: the ability to create and drop tables, insert, update, and delete
## rows, create schemas, sequences, functions, triggers, the works.
## 
## By default, the tests will try to connect to the database named "test"
## running on "localhost" using the default superuser username for each
## database type and an empty password.
## 
## If you have setup your database in a secure manner, these connection
## attempts will fail, and the tests will be skipped.  If you want to override
## these values, set the following environment variables before running tests.
## (The current values are shown in parentheses.)
## 
## Postgres:
## 
##     RDBO_PG_DSN      (@{[ nvl('RDBO_PG_DSN', 'dbi:Pg:dbname=test;host=localhost') ]})
##     RDBO_PG_USER     (@{[ nvl('RDBO_PG_USER', 'postgres') ]})
##     RDBO_PG_PASS     (@{[ nvl('RDBO_PG_PASS', '<none>') ]})
## 
## MySQL:
## 
##     RDBO_MYSQL_DSN   (@{[ nvl('RDBO_MYSQL_DSN', 'dbi:mysql:database=test;host=localhost') ]})
##     RDBO_MYSQL_USER  (@{[ nvl('RDBO_MYSQL_USER', 'root') ]})
##     RDBO_MYSQL_PASS  (@{[ nvl('RDBO_MYSQL_PASS', '<none>') ]})
##
## Oracle:
## 
##     RDBO_ORACLE_DSN  (@{[ nvl('RDBO_ORACLE_DSN', 'dbi:Oracle:dbname=test') ]})
##     RDBO_ORACLE_USER (@{[ nvl('RDBO_ORACLE_USER', '<none>') ]})
##     RDBO_ORACLE_PASS (@{[ nvl('RDBO_ORACLE_PASS', '<none>') ]})
##
## Informix:
## 
##     RDBO_INFORMIX_DSN   (@{[ nvl('RDBO_INFORMIX_DSN', 'dbi:Informix:test@test') ]})
##     RDBO_INFORMIX_USER  (@{[ nvl('RDBO_INFORMIX_USER', '<none>') ]})
##     RDBO_INFORMIX_PASS  (@{[ nvl('RDBO_INFORMIX_PASS', '<none>') ]})
## 
## SQLite: To disable the SQLite tests, set this environment varible
##
##     RDBO_NO_SQLITE  (@{[ nvl('RDBO_NO_SQLITE', '<undef>') ]})
##
## Press return to continue (or wait 60 seconds)
EOF

eval { require DBD::SQLite };

if(!$@ && $DBD::SQLite::VERSION >= 1.13)
{
print STDERR<<"EOF";

***
*** WARNING: DBD::SQLite version $DBD::SQLite::VERSION detected.  Versions 1.13 and 1.14
*** are known to have serious bugs that prevent the test suite from working
*** correctly.  In particular:
***
***     http://rt.cpan.org/Public/Bug/Display.html?id=21472
***
*** The SQLite tests will be skipped.  Please install DBD::SQLite 1.12
*** or a version that fixes the bugs in 1.13 and 1.14.
***
*** Press return to continue (or wait 60 seconds)
EOF
}

unless($ENV{'AUTOMATED_TESTING'})
{
  my %old;

  $old{'ALRM'} = $SIG{'ALRM'} || 'DEFAULT';

  eval
  {
    # Localize so I only have to restore in my catch block
    local $SIG{'ALRM'} = sub { die 'alarm' };
    alarm(60);
    my $res = <STDIN>;
    alarm(0);
  };

  if($@ =~ /alarm/)
  {
    $SIG{'ALRM'} = $old{'ALRM'};
  }
}

print "1..1\n",
      "ok 1\n";

1;

