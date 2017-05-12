package Test::Chado::DBManager::Pg;
{
  $Test::Chado::DBManager::Pg::VERSION = 'v4.1.1';
}

use namespace::autoclean;
use Moo;
use MooX::late;
use Types::Standard qw/Bool Str/;
use DBI;
use IPC::Cmd qw/can_run run/;
use Data::Random qw/rand_chars/;

has 'is_dynamic_schema' => ( is => 'ro', isa => Bool, default => 0 );
with 'Test::Chado::Role::HasDBManager';

before [ 'deploy_schema', 'deploy_by_dbi' ] => sub {
    my ($self)    = shift;
    my $namespace = $self->schema_namespace;
    my $user      = $self->user;
    my $dbh       = $self->dbh;

    $dbh->do(qq{DROP SCHEMA IF EXISTS $namespace CASCADE});
    $dbh->do(qq{CREATE SCHEMA $namespace });
    $dbh->do(qq{SET search_path TO $namespace});
};

has 'schema_namespace' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    default => sub {
        my ($self) = @_;
        return join '',
            rand_chars( set => 'loweralpha', min => 9, max => 10 );
    }
);

sub _build_dbh {
    my ($self) = @_;
    my $attr = $self->dbi_attributes;
    $attr->{AutoCommit} = 1;
    my $dbh = DBI->connect( $self->dsn, $self->user, $self->password, $attr );
    $dbh->do(qq{SET client_min_messages=WARNING});
    return $dbh;
}

sub _build_database {
    my ($self) = @_;
    my $driver_dsn;
    if ( $self->driver_dsn ) {
        $driver_dsn = $self->driver_dsn;
    }
    else {
        my @parsed_dsn = DBI->parse_dsn( $self->dsn );
        $driver_dsn = $parsed_dsn[-1];
    }
    if ( $driver_dsn =~ /d(atabase|b|bname)=(\w+)\;/ ) {
        return $2;
    }
}

sub _build_driver { return 'Pg' }

sub create_database {
    my ($self) = @_;
    my $dbname = $self->database;
    $self->dbh->do(qq{CREATE DATABASE $dbname});
}

sub drop_database {
    my ($self) = @_;
    my $dbname = $self->database;
    $self->dbh->do(qq{DROP DATABASE $dbname});
}

sub drop_schema {
    my ($self)    = @_;
    my $dbh       = $self->dbh;
    my $namespace = $self->schema_namespace;
    $dbh->do(qq{DROP SCHEMA IF EXISTS $namespace CASCADE});
    $self->clear_schema_namespace;
}

sub get_client_to_deploy {
    return;
}

sub deploy_by_client {
    my ( $self, $client ) = @_;
    my $host = 'localhost';
    if ( $self->dsn =~ /host=([^;]+)/ ) { $host = $1; }
    my $user = $self->user || '';
    $ENV{PGPASSWORD} = $self->password || '';
    my $cmd = [
        $client, '-h', $host,      '-U',
        $user,   '-f', $self->ddl, $self->database
    ];
    my ( $success, $error_code, $full_buf,, $stdout_buf, $stderr_buf )
        = run( command => $cmd, verbose => 1 );
    return $success if $success;
    die "unable to run command : ", $error_code, " ", $stderr_buf;
}

1;

__END__

=pod

=head1 NAME

Test::Chado::DBManager::Pg

=head1 VERSION

version v4.1.1

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
