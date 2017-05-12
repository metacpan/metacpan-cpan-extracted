# vim: ts=4 sw=4 expandtab smarttab smartindent autoindent cindent
package Nour::Database;
# ABSTRACT: Mostly just a wrapper for DBIX::Simple.

use Moose;
use namespace::autoclean;
use DBI;
use DBIx::Simple;
use Carp;
use Nour::Config;
use Mojo::Log;
use Getopt::Long qw/:config pass_through/;

with 'Nour::Base';

has log => (
    is => 'rw'
    , isa => 'Mojo::Log'
    , default => sub {
        my $self = shift;
        my $opts = $self->_opts;
        my %opts;

        return $opts->{log} if $opts->{log} and ref $opts->{log} eq 'Mojo::Log';
        if ( $opts->{log} ) {
            $opts{path} = $opts->{log} if $opts->{log} =~ /[^\d]+/;
        }
        elsif ( $ENV{DBIC_TRACE} and $ENV{DBIC_TRACE} =~ /^1=(.*)$/ ) {
            $opts{path} = $1;
            $opts->{log} = 1;
        }

        return new Mojo::Log ( level => 'debug', %opts ) if $opts->{log};
        return new Mojo::Log ( level => 'fatal' );
    }
);


has _opts => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has _conf => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has _base => ( is => 'rw', isa => 'Str' );

has _config => (
    is => 'rw'
    , isa => 'Nour::Config'
    , handles => [ qw/config/ ]
    , lazy => 1
    , required => 1
    , default => sub {
        my $self = shift;

        my $base = $self->_base;
        my %conf = %{ $self->_conf };
        my %opts;

        $opts{ '-conf' } = \%conf if %conf;
        $opts{ '-base' } = $base if $base;
        $opts{ '-base' } = 'config/database' unless $opts{ '-base' };

        return new Nour::Config ( %opts );
    }
);

has option => (
    is => 'rw'
    , isa => 'HashRef'
    , required => 1
    , lazy => 1
    , default => sub {
        my ( $self, %opts ) = @_;

        $self->merge_hash( \%opts, $self->_opts );

        GetOptions( \%opts
            , qw/
                database=s
            /
            , $self->config->{option}{getopts} ? @{ $self->config->{option}{getopts} } : ()
        );

        return \%opts;
    }
);

has _stored_handle => (
    is => 'rw'
    , isa => 'HashRef'
    , default => sub { {} }
);

has default_db => (
    is => 'rw'
    , isa => 'Str'
    , default => sub {
        my $self = shift;
        my $conf = $self->config;
        my $opts = $self->option;

        return $opts->{database}
            if $opts->{database}
                and $conf->{ $opts->{database} }
                and ref $conf->{ $opts->{database} } eq 'HASH';

        return $conf->{default}{database}
            if exists $conf->{default}{database}
                and not ref $conf->{default}{database}
                and exists $conf->{ $conf->{default}{database} }
                and ref $conf->{ $conf->{default}{database} } eq 'HASH';

        return '';
    }
);

has current_db => (
    is => 'rw'
    , isa => 'Str'
    , default => sub {
        my $self = shift;
        return ( $self->default_db or '' );
    }
);

around BUILDARGS => sub {
    my ( $next, $self, @args, $args ) = @_;

    $args = $self->$next( @args );

    for my $key ( keys %{ $args } ) {
        next unless ref $args->{ $key } eq 'DBI::db';
        my $dbh = delete $args->{ $key };
        my $dsn = "dbi:$dbh->{Driver}->{Name}:$dbh->{Name}";
        $args->{ $key }{dsn} = $dsn;
        $args->{_stored_handle}{ $key } = new DBIx::Simple ( $dbh );
    }
    $args->{_conf}{ $_ } = delete $args->{ $_ } for grep { $_ ne '_stored_handle' } keys %{ $args };

    $args->{_base} = delete $args->{_conf}{ '-base' } if defined $args->{_conf}{ '-base' };
    $args->{_opts} = delete $args->{_conf}{ '-opts' } if defined $args->{_conf}{ '-opts' };
    $args->{_conf} = delete $args->{_conf}{ '-conf' } if defined $args->{_conf}{ '-conf' };

    return $args;
};

around BUILD => sub {
    my ( $next, $self, @args, $prev ) = @_;

    $prev = $self->$next( @args );

    my $conf = $self->config;

    my %default = %{ $conf->{default} }
        if exists $conf->{default} and ref $conf->{default} eq 'HASH';
    delete $default{database};

    for my $alias ( grep { my $a = $_; my $c = grep { my $b = $_; $a eq $b } qw/default option/; my $d = !$c; $d } grep { ref $conf->{ $_ } eq 'HASH' } keys %{ $conf } ) {
        $conf->{ $alias }{__override} = delete $conf->{ $alias };

        $self->merge_hash( $conf->{ $alias }, \%default );
        $self->merge_hash( $conf->{ $alias }, delete $conf->{ $alias }{__override} );

        my %conf = %{ delete $conf->{ $alias } };

        ( $conf{database} = $conf{dsn} ) =~ s/^.*[:;](?:dbname|database)=([^;]+).*$/$1/;
        $conf->{ $alias }{name} = $alias;
        $conf->{ $alias }{conf} = \%conf;
        $conf->{ $alias }{args} = [
              $conf{dsn}
            , $conf{username}
            , $conf{password}
            , $conf{option} ? $conf{option} : {}
        ];
    }

    return $prev;
};

after BUILD => sub {
    my ( $self, @args ) = @_;

    $self->switch_to( $self->default_db );
};

sub _current_handle {
    my $self = shift;

    my $db = $self->current_db;
    my $dbh = $self->_stored_handle->{ $db };

    return $dbh;
}

sub switch_to {
    my ( $self, $db ) = @_;

    my $conf = $self->config;

    do {
        carp "no such database '$db'";
        return;
    } unless $conf->{ $db };

    do {
        my $dbh;

        eval {
            $dbh = DBI->connect( @{ $conf->{ $db }{args} } );
        };

        croak "problem connecting to database $db: ", $@ if $@ or not $dbh;
        $self->_stored_handle->{ $db } = new DBIx::Simple ( $dbh );
    } unless $self->_stored_handle->{ $db } and $self->_stored_handle->{ $db }->dbh->ping;

    $self->current_db( $db );

    return $self->_stored_handle->{ $db };
}


sub db {
    my ( $self, @args ) = @_;
    return $self->switch_to( @args ) if @args;
    return $self;
}

sub cfg {
    my ( $self ) = @_;
    my $db = $self->current_db;
    return $self->config->{ $db };
}


sub tx {
    my ( $self, $code ) = @_;
    return unless ref $code eq 'CODE';

    my $orig = $self->_current_handle->dbh;
    my $clone = $orig->clone;
       $clone->{AutoCommit} = 0;

    my $dbh = new DBIx::Simple ( $clone );

    if ( $code->( $dbh ) ) {
        $dbh->commit;
        # hmm, I don't know why but if the original handle has AutoCommit off it doesn't see new records created by
        # the cloned handle even after the cloned handle has committed. For this reason, I'm including this line:
        $self->_current_handle->commit unless $self->_current_handle->dbh->{AutoCommit};
    }
    else {
        $dbh->rollback;
    }

    $dbh->disconnect;
}

sub insert {
    my ( $self, $rel, $rec ) = ( shift, shift, shift );

    return unless $rel and $rec;

    my $driver = lc $self->_current_handle->dbh->{Driver}->{Name};
    my $backtick = $driver eq 'mysql' ? '`' : $driver eq 'pg' ? '"' : '';

    my %opts = ref $_[-1] eq 'HASH' ? %{ $_[-1] } : @_;
    my @vals = map { $rec->{ $_ } } sort keys %{ $rec };
    my $cols = join ', ', sort keys %{ $rec };
    my $hold = join ', ', map { '?' } sort keys %{ $rec };
    my $crud = $opts{replace} ? 'replace' : $opts{ignore} ? 'insert ignore' : 'insert';
    my $erel = $rel =~ /^$backtick.*$backtick$/ ? $rel : ( join '.', map { "$backtick$_$backtick" } split /\./, $rel );

    my ( $sql, @bind ) = $self->_current_handle->query( qq|
        $crud into $erel ( $cols ) values ( $hold )
    |, @vals );

    return $self->insert_id( $rel, $rec, %opts ) if $opts{id};
}


sub insert_id {
    my ( $self, $rel, $rec, %opts ) = @_;

    # wrap with if ( mysql )
    my $db = $self->_current_handle->dbh->{Name};
       $db =~ s/^database=([^;].*)(?:;host.*)?$/$1/;
    my $id = $opts{id} && ( ( not ref $opts{id} && $opts{id} =~ /[^\d]/ ) || ( ref $opts{id} eq 'ARRAY' ) ) ? $opts{id} : $rel .'_id';
    my $table = "`$db`.`$rel`";

    my $last_id = ref $opts{id} ? 0 : 1;
    my $id_column = $last_id ? $opts{id} =~ /[^\d]/ ? $opts{id} : $rel .'_id' : ${ $opts{id} };

    return $self->_current_handle->last_insert_id( qw/information_schema/, $db, $rel, $id_column ) if $last_id;
    return $self->_current_handle->select( \$table, $id_column, $rec )->list;
}

sub update {
    my ( $self, $rel, $rec, $cond ) = @_;
    return unless ref $cond eq 'HASH';
    return $self->_current_handle->update( $rel, $rec, $cond );
}

sub delete {
    my ( $self, $rel, $cond ) = @_;
    return unless ref $cond eq 'HASH';
    return $self->_current_handle->delete( $rel, $cond );
}

sub query {
    my $self = shift;
    if ( $self->log->level eq 'debug' ) {
        my $query = $_[0];
        for my $i ( 1 .. $#_ ) {
            if ( defined $_[ $i ] and $_[ $i ] =~ /^\d+$/ ) {
                $query =~ s/\?/$_[ $i ]/;
            }
            elsif ( defined $_[ $i ] ) {
                $query =~ s/\?/'$_[ $i ]'/;
            }
            else {
                $query =~ s/\?/null/;
            }
        }
        $query =~ s/(?:^[\r\n]+)|(?:[\r\n\s]+$)//g;
        $self->log->debug( "[query]\n$query" );
    }
    return $self->_current_handle->query( @_ );
}

sub AUTOLOAD {
    my $self = shift;

    ( my $method = $Nour::Database::AUTOLOAD ) =~ s/^.*://;

    my $dbh = $self->_current_handle;

    return $dbh->$method( @_ ) if $dbh and $dbh->can( $method );
    return $dbh->dbh->$method( @_ ) if $dbh->dbh->can( $method );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nour::Database - Mostly just a wrapper for DBIX::Simple.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

Mostly just a wrapper for DBIX::Simple.

=head1 METHODS

=head2 db

    # This method most useful when handle is imported via Moose, e.g.
    has _database => (
        is => 'rw'
        , isa => 'Nour::Database'
        , handles => [ qw/db/ ]
        , lazy => 1
        , required => 1
        , default => sub { new Nour::Database }
    );

=head2 tx

    # This code commits:
    $self->tx( sub {
        my $tx = shift;
        # do some inserts/updates
        return 1;
    } );

    # This code doesn't:
    $self->tx( sub {
        my $tx = shift;
        # do some inserts/updates
        return 0; # or die, return pre-maturely, etc.
    } );

=head2 insert_id

Review this. Extra cruft might be useful or not.

=head1 NAME

Nour::Database

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
