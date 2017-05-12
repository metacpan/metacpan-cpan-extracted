package # hide from PAUSE
    DBHelper;
use strict;
use warnings;
use Carp 'croak';

# lifted from DBIx::Class' DBICTest.pm
sub _database {
    my $self    = shift;
    my $db_file = shift
        or croak 'unspecified database file';

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $ENV{"DBICTEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"DBICTEST_DBUSER"} || '';
    my $dbpass = $ENV{"DBICTEST_DBPASS"} || '';

    # we had some warnings telling us not to explicitly set AutoCommit
    # so we've removed it from the connect_info and let everything else do
    # what it does best
    my @connect_info = ($dsn, $dbuser, $dbpass, { });

    return @connect_info;
}

# lifted from DBIx::Class' DBICTest.pm
sub _init_schema {
    my $self = shift;
    my %args = @_;
    my $schema;

    my $schema_class = $args{schema_class}
        or croak q{'schema_class' unspecified};
    my $db_file = $args{db_file}
        or croak q{'db_file' unspecified};
    my $sql_file = $args{sql_file}
        or croak q{'sql_file' unspecified};
    my $namespace = $args{namespace}
        or croak q{'namespace' unspecified};

    if ($args{compose_connection}) {
      $schema = ${schema_class}->compose_connection(
                  $namespace, $self->_database($db_file)
                );
    } else {
      $schema = ${schema_class}->compose_namespace($namespace);
    }
    if ( !$args{no_connect} ) {
      $schema = $schema->connect($self->_database($db_file));
      $schema->storage->on_connect_do(['PRAGMA synchronous = OFF']);
    }
    if ( !$args{no_deploy} ) {
        ${namespace}->deploy_schema( $schema, $sql_file );
        ${namespace}->populate_schema( $schema ) if( !$args{no_populate} );
    }
    return $schema;
}

# lifted from DBIx::Class' DBICTest.pm
sub deploy_schema {
    my $self        = shift;
    my $schema      = shift;
    my $sql_file    = shift
        or croak 'no sql file specified';

    if ($ENV{"DBICTEST_SQLT_DEPLOY"}) {
        return $schema->deploy();
    } else {
        open IN, $sql_file;
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
    }
}

1;
# vim: ts=8 sts=4 et sw=4 sr sta
