package My::Common;

# $Id: Common.pm,v 3.2 2004/01/10 02:49:58 lachoy Exp $

use strict;
use SPOPS::DBI;

# CHANGE
#
# Modify $SPOPS_DB below to:
#
#     SPOPS::DBI::MySQL     if you're using MySQL
#     SPOPS::DBI::Sybase    if you're using Sybase ASA/ASE or MS SQL
#     SPOPS::DBI::Pg        if you're using PostgreSQL
#     SPOPS::DBI::Oracle    if you're using Oracle
#     SPOPS::DBI::SQLite    if you're using SQLite
#     SPOPS::DBI::InterBase if you're using InterBase/FirebirdSQL

my $SPOPS_DB = 'SPOPS::DBI::SQLite';
eval "require $SPOPS_DB";

@My::Common::ISA = ( $SPOPS_DB, 'SPOPS::DBI' );
$My::Common::VERSION = sprintf("%d.%02d", q$Revision: 3.2 $ =~ /(\d+)\.(\d+)/);

# CHANGE
#
# Modify database connection info as needed

use constant DBI_DSN      => 'DBI:SQLite:dbname=sqlite_test.db';
use constant DBI_USER     => '';
use constant DBI_PASSWORD => '';

1;
