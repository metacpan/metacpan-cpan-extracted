package Pcore::Handle::DBI;

use Pcore -role, -const;
use Pcore::Handle::DBI::STH;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_blessed_arrayref is_blessed_hashref is_plain_arrayref is_plain_hashref];

with qw[Pcore::Handle::Base];

has on_connect    => ();                       # Maybe [CodeRef]
has _schema_patch => ( init_arg => undef );    # HashRef

const our $SCHEMA_PATCH_TABLE_NAME => '__schema_patch';
const our $DEFAULT_MODULE          => 'main';

# SCHEMA PATCH
sub _get_schema_patch_table_query ( $self, $table_name ) {
    return <<"SQL";
        CREATE TABLE IF NOT EXISTS "$table_name" (
            "module" TEXT NOT NULL,
            "id" INT4 NOT NULL,
            "timestamp" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY ("module", "id")
        )
SQL
}

sub add_schema_patch ( $self, $id, $module, $sql = undef ) {
    if ( !defined $sql ) {
        $sql = $module;

        $module = $DEFAULT_MODULE;
    }

    die qq[Schema patch id "$id" for module "$module" is already exists] if exists $self->{_schema_patch}->{$module}->{$id};

    if ( is_plain_hashref $sql) {
        if ( $self->{is_sqlite} && exists $sql->{sqlite} ) {
            $sql = $sql->{sqlite};
        }
        elsif ( $self->{is_pgsql} && exists $sql->{pgsql} ) {
            $sql = $sql->{pgsql};
        }
        else {
            die qq[Schema patch id "$id" for module "$module" has no SQL statement for current database];
        }
    }

    return if !$sql;

    $self->{_schema_patch}->{$module}->{$id} = {
        module => $module,
        id     => $id,
        sql    => $sql,
    };

    return;
}

sub load_schema ( $self, $path, $module = $DEFAULT_MODULE ) {
    $path = P->path($path);

    for my $patch ( $path->read_dir->@* ) {
        my ($id) = $patch =~ /\A(\d+)/sm;

        my $sql = P->cfg->read("$path/$patch");

        $self->add_schema_patch( 0+ $id, $module, $sql );
    }

    return;
}

sub upgrade_schema ( $self ) {
    my ( $res, $dbh ) = $self->get_dbh;

    # unable to get dbh
    die $res if !$res;

    $res = $dbh->begin_work;

    # unable to start transaction
    die $res if !$res;

    # create patch table
    ( $res = $dbh->do( $self->_get_schema_patch_table_query($SCHEMA_PATCH_TABLE_NAME) ) ) or goto FINISH;

    for my $module ( sort keys $self->{_schema_patch}->%* ) {
        for my $id ( sort { $a <=> $b } keys $self->{_schema_patch}->{$module}->%* ) {
            ( $res = $dbh->selectrow( qq[SELECT "id" FROM "$SCHEMA_PATCH_TABLE_NAME" WHERE "module" = \$1 AND "id" = \$2], [ $module, $id ] ) ) or goto FINISH;

            # patch is already applied
            next if $res->{data};

            # apply patch
            ( $res = $dbh->do( $self->{_schema_patch}->{$module}->{$id}->{sql} ) ) or goto FINISH;

            # register patch
            ( $res = $dbh->do( qq[INSERT INTO "$SCHEMA_PATCH_TABLE_NAME" ("module", "id") VALUES (\$1, \$2)], [ $module, $id ] ) ) or goto FINISH;
        }
    }

  FINISH:
    delete $self->{_schema_patch};

    if ($res) {
        $dbh->commit;
    }
    else {
        $dbh->rollback;
    }

    return $res;
}

# QUOTE
# https://www.postgresql.org/docs/current/static/sql-syntax-lexical.html
sub quote_id ( $self, $id ) {
    if ( index( $id, q[.] ) != -1 ) {
        my @id = split /[.]/sm, $id;

        for my $s (@id) {
            $s =~ s/"/""/smg;

            $s = qq["$s"];
        }

        return join q[.], @id;
    }
    else {
        $id =~ s/"/""/smg;

        return qq["$id"];
    }
}

# QUERY BUILDER
sub prepare_query ( $self, $query ) {
    my ( @sql, @bind );

    my $i = 1;

    for my $token ( $query->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token) {
            push @sql, $token;
        }

        # ScalarRef value is processed as parameter
        elsif ( is_plain_scalarref $token ) {
            push @sql, '$' . $i++;

            push @bind, $token->$*;
        }

        # blessed ArrayRef value is processed as parameter with type
        elsif ( is_blessed_arrayref $token ) {
            push @sql, '$' . $i++;

            push @bind, $token;
        }

        # Object value
        elsif ( is_blessed_hashref $token) {
            my ( $sql, $bind ) = $token->GET_SQL_QUERY( $self, \$i );

            if ( defined $sql ) {
                push @sql, $sql;

                push @bind, $bind->@* if defined $bind;
            }
        }
        else {
            die 'Unsupported ref type';
        }
    }

    my $sql = join $SPACE, @sql;

    utf8::encode $sql if utf8::is_utf8 $sql;

    return $sql, @bind ? \@bind : undef;
}

sub query_to_string ( $self, $query, $bind = undef ) {

    # auery is arrayref
    if ( is_plain_arrayref $query) {
        ( $query, my $bind1 ) = $self->prepare_query($query);

        $bind //= $bind1;
    }

    # query is prepared sth
    elsif ( ref $query eq 'Pcore::Handle::DBI::STH' ) {
        $query = $query->{query};
    }

    # query is plain text
    else {

        # convert "?" placeholders to the "$1" style
        if ( defined $bind ) {
            my $i;

            $query =~ s/[?]/'$' . ++$i/smge;
        }

        utf8::encode $query if utf8::is_utf8 $query;
    }

    # substitute bind params
    $query =~ s/\$(\d+)/$self->quote($bind->[$1 - 1])/smge if defined $bind;

    return $query;
}

sub prepare ( $self, $query ) {
    my $bind;

    if ( is_plain_arrayref $query) {
        ( $query, $bind ) = $self->prepare_query($query);
    }
    else {

        # convert "?" placeholders to postgres "$1" style
        my $i;

        $query =~ s/[?]/'$' . ++$i/smge;

        utf8::encode $query if utf8::is_utf8 $query;
    }

    my $sth = Pcore::Handle::DBI::STH->new( query => $query );

    if (wantarray) {
        return $sth, $bind;
    }
    else {
        return $sth;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
