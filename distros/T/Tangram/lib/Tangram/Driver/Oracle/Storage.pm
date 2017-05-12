

package Tangram::Driver::Oracle::Storage;

use strict;

use Tangram::Storage;
use vars qw(@ISA);
 @ISA = qw( Tangram::Storage );

sub open_connection
{
    my $self = shift;

    my $db = $self->SUPER::open_connection(@_);

    # Oracle doesn't really have a default date format (locale
    # dependant), so adjust it to use ISO-8601.
    $db->do
	("ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD\"T\"HH24:MI:SS'");
    $db->do
	("ALTER SESSION SET CONSTRAINTS = DEFERRED");
    $db->{RaiseError} = 1;
    $db->{LongTruncOk} = 0;
    $db->{LongReadLen} = 1024*1024;
    return $db;
}


sub has_tx()         { 1 }
sub has_subselects() { 1 }
sub from_dual()      { " FROM DUAL" }

1;
