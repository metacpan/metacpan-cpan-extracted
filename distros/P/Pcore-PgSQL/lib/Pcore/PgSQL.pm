package Pcore::PgSQL v0.14.4;

use Pcore -dist, -class;

has data_dir => ( is => 'ro', isa => Str, required => 1 );

sub run ( $self, $cb ) {
    my $db_dir = "$self->{data_dir}/db/";

    # create and prepare data dir
    P->file->mkdir( $self->data_dir ) if !-d $self->data_dir;
    my $uid = getpwnam 'postgres';
    chown $uid, $uid, $self->data_dir or die;

    # init db
    if ( $self->is_empty ) {
        my $superuser_password;

        my $pwfile = "$self->{data_dir}/pgsql-password.txt";

        if ( !-f $pwfile ) {
            $superuser_password = P->random->bytes_hex(32);

            P->file->write_bin( $pwfile, $superuser_password );

            chown $uid, $uid, $pwfile or die;
        }
        else {
            $superuser_password = P->file->read_bin($pwfile);
        }

        say "postgres password: $superuser_password\n";

        my $res = P->pm->run_proc( [ 'su', 'postgres', '-c', "$ENV{POSTGRES_HOME}/bin/initdb --encoding UTF8 --no-locale -U postgres --pwfile $pwfile -D $db_dir" ] );

        exit 3 if !$res;

        P->file->write_text(
            "$db_dir/pg_hba.conf",
            [   q[local all all trust],           # trust any user, connected via unix socket
                q[host all all 0.0.0.0/0 md5],    # require password, when user is connected via TCP
            ]
        );

        P->file->append_text(
            "$db_dir/postgresql.conf",
            [                                     #
                q[listen_addresses='*'],
                q[unix_socket_directories='/var/run/postgresql'],
            ]
        );
    }

    # create and prepare unix socket dir
    P->file->mkdir('/var/run/postgresql/') if !-d '/var/run/postgresql';
    chown $uid, $uid, '/var/run/postgresql/' or die;

    # run server
    P->pm->run_proc(
        [ 'su', 'postgres', '-c', "$ENV{POSTGRES_HOME}/bin/postgres -D $db_dir" ],
        on_finish => sub ($proc) {
            $cb->($proc);

            return;
        }
    );

    return;
}

sub is_empty ($self) {
    return P->file->read_dir( $self->data_dir )->@* ? 0 : 1;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::PgSQL

=head1 SYNOPSIS

=head1 DESCRIPTION

    docker create --name pgsql -v pgsql:/var/local/pcore-pgsql/data/ -v /var/run/postgresql/:/var/run/postgresql/ -p 5432:5432/tcp softvisio/pcore-pgsql

    # how to connect with standard client:
    psql -U postgres
    psql -h /var/run/postgresql -U postgres

    # connect via TCP
    my $dbh = P->handle('pgsql://username:password@host:port?db=dbname');

    # connect via unix socket
    my $dbh = P->handle('pgsql://username:password@/var/run/postgresql?db=dbname');

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@cpan.org>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.

=cut
