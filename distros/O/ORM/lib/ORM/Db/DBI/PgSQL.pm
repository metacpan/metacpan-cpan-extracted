#
# DESCRIPTION
#   PerlORM - Object relational mapper (ORM) for Perl. PerlORM is Perl
#   library that implements object-relational mapping. Its features are
#   much similar to those of Java's Hibernate library, but interface is
#   much different and easier to use.
#
# AUTHOR
#   Alexey V. Akimov <akimov_alexey@sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2005-2006 Alexey V. Akimov
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#   
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

package ORM::Db::DBI::PgSQL;

$VERSION = 0.83;

use base 'ORM::Db::DBI';

##
## CONSTRUCTORS
##

## use: ORM::Db::DBI::PgSQL->new
## (
##     host        => string,
##     database    => string,
##     namespace   => string || undef,
##     user        => string,
##     password    => string,
##     pure_perl_driver => boolean,
## );
##
sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    unless( $arg{pure_perl_driver} )
    {
        $arg{data_source} = "DBI:Pg:dbname='$arg{database}';host='$arg{host}';port=".($arg{port}||5432);
    }

    $arg{driver} = $arg{pure_perl_driver} ? 'PgPP' : 'Pg';
    $self        = $class->SUPER::new( %arg );

    $self->{pure_perl_driver} = $arg{pure_perl_driver};
    $self->{namespace}        = $arg{namespace} || 'public';

    return $self;
}

##
## CLASS METHODS
##

sub qc
{
    my $self = shift;
    my $str  = shift;

    if( defined $str )
    {
        $str =~ s/\'/\'\'/g;
        $str = "'$str'";
    }
    else
    {
        $str = 'NULL';
    }

    return $str;
}

sub qi
{
    my $self = shift;
    my $str  = shift;

    $str =~ s/\"/\"\"/g;
    $str = "\"$str\"";

    return $str;
}

sub qt { $_[0]->qi( $_[1] ); }
sub qf { $_[0]->qi( $_[1] ); }

##
## OBJECT METHODS
##

sub _namespace        { $_[0]->{namespace}; }
sub _pure_perl_driver { $_[0]->{pure_perl_driver}; }

## use: $id = $db->insertid()
##
sub insertid
{
    my $self = shift;
    my $id;

    if( !$self->_db_handler )
    {
        $id = undef;
    }
    elsif( $self->_pure_perl_driver )
    {
        $id = $self->_PgPP_last_insert_id
        (
            $self->_db_handler,
            $self->database,
            undef,
            $self->{last_insert_table},
            undef
        );
    }
    else
    {
        $id = $self->_db_handler->last_insert_id
        (
            $self->database,
            undef,
            $self->{last_insert_table},
            undef
        );
    }

    return $id;
}

sub insert_object
{
    my $self = shift;
    my %arg  = @_;

    $self->{last_insert_table} = (ref $arg{object})->_db_table( 0 );

    $self->SUPER::insert_object( %arg )
}

sub table_struct
{
    my $self    = shift;
    my %arg     = @_;
    my $error   = ORM::Error->new;
    my %field;
    my %defaults;
    my $res;

    ## Fetch table structure

    # WARNING! DBD::PgPP driver does not support the following
    # so version detection probably should be rewriten to use
    # "SELECT version()" or something else.

    my $version = $self->_db_handler->{pg_server_version} || 0;
    my $old_ver = $version < 70300;
    my $catalog = $old_ver ? '' : 'pg_catalog.';

    #ORM::DbLog->write_to_stderr(1);
    $res = $self->select
    (
        error => $error,
        query =>
        (
            # This SQL query was crafted from DBD::Pg::column_info,
            # the reason it was not used itself is because it is
            # not supported by DBD::PgPP.
            'SELECT
                a.attnum AS "Index",
                a.attname AS "Field",
                (
                    t.typname ||
                    CASE WHEN a.atttypmod = -1
                        THEN \'\'
                        ELSE \'(\' || a.atttypmod || \')\'
                    END
                ) AS "Type",
                af.adsrc AS "Default"
            FROM
                '.$catalog.'pg_type t
                JOIN '.$catalog.'pg_attribute a ON (t.oid = a.atttypid)
                JOIN '.$catalog.'pg_class c ON (a.attrelid = c.oid)
                LEFT JOIN '.$catalog.'pg_attrdef af ON (a.attnum = af.adnum AND a.attrelid = af.adrelid)
                '.( $old_ver ? '' : "JOIN ${catalog}pg_namespace n ON (n.oid = c.relnamespace)" ).'
            WHERE
                a.attnum >= 0
                AND c.relkind IN (\'r\',\'v\')
                AND c.relname = ' . $self->qc( $arg{table} ) . '
                '.( $old_ver ? '' : 'AND n.nspname = '.$self->qc( $self->_namespace ) ).'
            ORDER BY "Index"'
        )
    );
    #ORM::DbLog->write_to_stderr(0);

    unless( $error->fatal )
    {
        while( $data = $res->next_row )
        {
            $defaults{$data->{Field}} = $self->_parse_default_value( $data->{Default} );
            $field{$data->{Field}}    = $arg{class}->_db_type_to_class( $data->{Field}, $data->{Type} );
        }
    }

    ## Fetch class references
    if( scalar( %field ) )
    {
        $res = $self->select
        (
            error => $error,
            query => 'SELECT * FROM '.$self->qt('_ORM_refs').' WHERE class='.$self->qc( $arg{class} ),
        );
        unless( $error->fatal )
        {
            while( $data = $res->next_row )
            {
                if( exists $field{$data->{prop}} )
                {
                    $field{$data->{prop}} = $data->{ref_class};
                }
            }
        }
    }

    $error->upto( $arg{error} );
    return \%field, \%defaults;
}

sub _sql_limit
{
    my $self     = shift;
    my $page     = (int shift)||1;
    my $pagesize = int shift;
    my $sql;

    if( $pagesize )
    {
        $sql = "LIMIT $pagesize OFFSET ".(($page-1)*$pagesize);
    }

    return $sql;
}

sub _lost_connection
{
    my $self = shift;
    my $err  = shift;

    # mysql: defined $err && ( $err == 2006 || $err == 2013 );
    warn "Don't know how to verify whether error was caused by connection abort!";
    undef;
}

# PgSQL does not support FOR UPDATE together with SELECT DISTINCT
sub _ta_select { ''; }

sub _parse_default_value
{
    my $self  = shift;
    my $value = shift;

    if( defined $value && $value =~ /^'(.*)'::[^:]+$/ )
    {
        $value = $1;
        $value =~ s/''/'/g;
    }
    else
    {
        $value = undef;
    }

    return $value;
}

# Cloned from DBD::Pg
sub _PgPP_last_insert_id
{
    my ($self, $dbh, $catalog, $schema, $table, $col, $attr) = @_;

    ## Our ultimate goal is to get a sequence
    my ($sth, $count, $SQL, $sequence);

    ## Cache all of our table lookups? Default is yes
    my $cache = 1;

    ## Catalog and col are not used
    $schema = '' if ! defined $schema;
    $table = '' if ! defined $table;
    my $cachename = "lii$table$schema";

    my $version = $self->_db_handler->{pg_server_version} || 0;
    my $old_ver = $version < 70300;
    my $use_cat = $old_ver ? '' : 'pg_catalog.';

    if (defined $attr and length $attr) {
        ## If not a hash, assume it is a sequence name
        if (! ref $attr) {
            $attr = {sequence => $attr};
        }
        elsif (ref $attr ne 'HASH') {
            return $dbh->set_err(1, "last_insert_id must be passed a hashref as the final argument");
        }
        ## Named sequence overrides any table or schema settings
        if (exists $attr->{sequence} and length $attr->{sequence}) {
            $sequence = $attr->{sequence};
        }
        if (exists $attr->{pg_cache}) {
            $cache = $attr->{pg_cache};
        }
    }

    if (! defined $sequence and exists $dbh->{private_dbdpg}{$cachename} and $cache) {
        $sequence = $dbh->{private_dbdpg}{$cachename};
    }
    elsif (! defined $sequence) {
        ## At this point, we must have a valid table name
        if (! length $table) {
            return $dbh->set_err(1, "last_insert_id needs at least a sequence or table name");
        }
        my @args = ($table);

        ## Only 7.3 and up can use schemas
        $schema = '' if( $old_ver );

        ## Make sure the table in question exists and grab its oid
        my ($schemajoin,$schemawhere) = ('','');
        if (length $schema) {
            $schemajoin = "\n JOIN pg_catalog.pg_namespace n ON (n.oid = c.relnamespace)";
            $schemawhere = "\n AND n.nspname = ?";
            push @args, $schema;
        }
        $SQL = "SELECT c.oid FROM ${use_cat}pg_class c $schemajoin\n WHERE relname = ?$schemawhere";
        $sth = $dbh->prepare($SQL);
        $count = $sth->execute(@args);
        if (!defined $count or $count eq '0E0') {
            $sth->finish();
            my $message = qq{Could not find the table "$table"};
            length $schema and $message .= qq{ in the schema "$schema"};
            return $dbh->set_err(1, $message);
        }
        my $oid = $sth->fetchall_arrayref()->[0][0];
        ## This table has a primary key. Is there a sequence associated with it via a unique, indexed column?
        $SQL = "SELECT a.attname, i.indisprimary, substring(d.adsrc for 128) AS def\n".
            "FROM ${use_cat}pg_index i, ${use_cat}pg_attribute a, ${use_cat}pg_attrdef d\n ".
                "WHERE i.indrelid = $oid AND d.adrelid=a.attrelid AND d.adnum=a.attnum\n".
                    "  AND a.attrelid=$oid AND i.indisunique IS TRUE\n".
                        "  AND a.atthasdef IS TRUE AND i.indkey[0]=a.attnum\n".
                            " AND d.adsrc ~ '^nextval'";
        $sth = $dbh->prepare($SQL);
        $count = $sth->execute();
        if (!defined $count or $count eq '0E0') {
            $sth->finish();
            $dbh->set_err(1, qq{No suitable column found for last_insert_id of table "$table"});
        }
        my $info = $sth->fetchall_arrayref();

        ## We have at least one with a default value. See if we can determine sequences
        my @def;
        for (@$info) {
            next unless $_->[2] =~ /^nextval\('([^']+)'::/o;
            push @$_, $1;
            push @def, $_;
        }
        if (!@def) {
            $dbh->set_err(1, qq{No suitable column found for last_insert_id of table "$table"\n});
        }
        ## Tiebreaker goes to the primary keys
        if (@def > 1) {
            my @pri = grep { $_->[1] } @def;
            if (1 != @pri) {
                $dbh->set_Err(1, qq{No suitable column found for last_insert_id of table "$table"\n});
            }
            @def = @pri;
        }
        $sequence = $def[0]->[3];
        ## Cache this information for subsequent calls
        $dbh->{private_dbdpg}{$cachename} = $sequence;
    }

    $sth = $dbh->prepare("SELECT currval(?)");
    $sth->execute($sequence);
    return $sth->fetchall_arrayref()->[0][0];

}

##
## SQL FUNCTIONS
##

