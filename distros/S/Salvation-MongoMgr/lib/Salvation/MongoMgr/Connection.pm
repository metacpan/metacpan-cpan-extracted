package Salvation::MongoMgr::Connection;

use utf8;
use strict;
use warnings;
use boolean;
use feature 'state';

use URI ();
use JSON 'from_json';
use File::Slurp 'read_file';
use Salvation::TC ();
use MongoDB ();


sub new {

    my ( $proto, %args ) = @_;

    Salvation::TC -> assert( \%args, 'HashRef(
        Str :db!
        Str :config_file!,
        Maybe[Str] :auth_config_file,
        Int :timeout,
        Int :query_timeout,
        Int :wtimeout,
        Str :auth_db_name,
        Str :host,
        Str :use_auth_for,
        Bool :find_master
    )' );

    $args{ 'auth_db_name' } //= 'admin';

    unless( exists $args{ 'find_master' } ) {

        $args{ 'find_master' } = true;
    }

    unless( exists $args{ 'use_auth_for' } ) {

        $args{ 'use_auth_for' } = $args{ 'db' };
    }

    my $self = bless( \%args, ( ref( $proto ) || $proto ) );

    if( defined( my $auth_config_file = $self -> auth_config_file() ) ) {

        my $rv = from_json( scalar( read_file( $auth_config_file ) ) );

        Salvation::TC -> assert( $rv, sprintf( 'HashRef(
            HashRef(
                HashRef(
                    Str :login!,
                    Str :password!
                ) :%s!
            ) :db_auth!

        )', $self -> { 'use_auth_for' } ) );

        $self -> { '_auth_info' } = $rv;

    } else {

        $self -> { '_auth_info' } = { db_auth => { $self -> { 'use_auth_for' } => {} } };
    }

    $self -> { '_mongo_servers_list' } = join( ',', @{ $self -> servers_list() } );

    return $self;
}

sub make_connection_string {
    my ($self, $mongo_servers_list) = @_;
    $mongo_servers_list //= $self -> { '_mongo_servers_list' };
    return "mongodb://${mongo_servers_list}" . ($self->{connection_args} // '');
}

sub _connect {

    my ( $self ) = @_;
    my $mongo_servers_list = $self -> { '_mongo_servers_list' };
    my $dsn = join( "\0", $mongo_servers_list, $self -> { 'find_master' } );
    state $HMONGO = {};

    if(
        exists $HMONGO -> { $dsn }
        && ( $HMONGO -> { $dsn } -> { 'pid' } == $$ )
    ) {

        $self -> { '_connection' } = $HMONGO -> { $dsn } -> { 'handle' };

    } else {

        my ( $login, $password ) = @{ $self -> credentials() }{ 'login', 'password' };

        $self -> { '_connection' } = MongoDB::MongoClient -> new(
            host => $self->make_connection_string,
            timeout => ( $self -> { 'timeout' } // 20_000 ),
            query_timeout => ( $self -> { 'query_timeout' } // 600_000 ), # in ms
            wtimeout => ( $self -> { 'wtimeout' } // 30_000 ),
            find_master => $self -> { 'find_master' },
            auto_connect => 1,
            w => 1,
            dt_type => undef,
            db_name => $self -> { 'auth_db_name' },
            ( defined $login ? ( username  => $login ) : () ),
            ( defined $password ? ( password => $password ) : () ),
        );

        $HMONGO -> { $dsn } = {
            handle => $self -> { '_connection' },
            pid => $$,
        };
    }

    return $self -> { '_connection' };
}

sub credentials {

    my ( $self ) = @_;
    my ( $login, $password ) = @{ $self
        -> { '_auth_info' }
        -> { 'db_auth' }
        -> { $self -> { 'use_auth_for' } }
    }{ 'login', 'password' };

    return {
        login => $login,
        password => $password,
    };
}

sub config_file {

    my ( $self ) = @_;

    return $self -> { 'config_file' };
}

sub auth_config_file {

    my ( $self ) = @_;

    unless( exists $self -> { 'auth_config_file' } ) {

        $self -> { 'auth_config_file' } = $self -> { 'config_file' };
    }

    return $self -> { 'auth_config_file' };
}

sub servers_list {

    my ( $self ) = @_;

    unless( exists $self -> { 'servers_list' } ) {

        if( exists $self -> { 'host' } ) {

            $self -> { 'servers_list' } = [ $self -> { 'host' } ];

        } else {

            my $config = from_json( scalar( read_file( $self -> config_file() ) ) );

            Salvation::TC -> assert( $config, 'HashRef( ArrayRef[Str] :servers_list!, HashRef[Str] :connection_args )' );

            $self -> { 'servers_list' } = $config -> { 'servers_list' };

            if(exists($config->{connection_args})) {
                my $o = URI->new;
                $o->query_form(%{$config->{connection_args}});
                $self->{connection_args} = '/' . $o->as_string;
            }
        }
    }

    return $self -> { 'servers_list' };
}

sub get_connection {

    my ( $self ) = @_;

    return $self -> _connect();
}

sub get_database {

    my ( $self, $db ) = @_;

    return $self -> get_connection() -> get_database( $db // $self -> { 'db' } );
}

sub get_collection {

    my ( $self, $collection ) = @_;

    return $self -> get_database() -> get_collection( $collection );
}


1;

__END__
