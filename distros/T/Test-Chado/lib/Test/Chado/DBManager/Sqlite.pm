package Test::Chado::DBManager::Sqlite;
{
  $Test::Chado::DBManager::Sqlite::VERSION = 'v4.1.1';
}

use namespace::autoclean;
use Moo;
use MooX::late;
use DBI;
use File::Temp qw/:POSIX/;
use IPC::Cmd qw/can_run run/;


has 'is_dynamic_schema' => (is => 'ro', isa => 'Bool', default => 1);
with 'Test::Chado::Role::HasDBManager';

has '+dsn' => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $file = tmpnam();
        $self->driver('SQLite');
        return "dbi:SQLite:dbname=$file";
    }
);

sub _build_dbh {
    my ($self) = @_;
    return DBI->connect( $self->dsn, '', '', $self->dbi_attributes );
}

sub _build_database {
    my ($self) = @_;
    my $driver_dsn;
    if ( $self->driver_dsn ) {
        $driver_dsn = $self->driver_dsn;
    }
    else {
        my @parsed_dsn = DBI->parse_dsn($self->dsn);
        $driver_dsn = $parsed_dsn[-1];
    }

    if ( $driver_dsn =~ /(dbname|(.+)?)=(\S+)/ ) {
        return $3;
    }
}

sub _build_driver { return 'SQLite'}

sub create_database {
    return 1;
}

sub drop_database {
    my ($self) = @_;
    return $self->dbh->disconnect;
}

sub drop_schema {
    my ($self) = @_;
    my $dbh = $self->dbh;

    my $arr = $dbh->selectall_arrayref(
        qq{SELECT name FROM sqlite_master where type = 'table' });
    for my $row (@$arr) {
        my $table = $row->[0];
        $dbh->do(qq{ DROP TABLE $table });
    }
}

sub get_client_to_deploy {
    my ($self) = @_;
    my $cmd;
    if ( $cmd = can_run 'sqlite3' ) {
        return $cmd;
    }
    elsif ( $cmd = can_run 'sqlite' ) {
        return $cmd;
    }
    else {
        return $cmd;
    }
}

sub deploy_by_client {
    my ( $self, $client ) = @_;
    my $cmd = [ $client, '-noheader', $self->database, '<', $self->ddl ];
    my ( $success, $error_code, $full_buf,, $stdout_buf, $stderr_buf )
        = run( command => $cmd, verbose => 1 );
    return $success if $success;
    die "unable to run command : ", $error_code, " ", $stderr_buf;
}


1;

__END__

=pod

=head1 NAME

Test::Chado::DBManager::Sqlite

=head1 VERSION

version v4.1.1

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
