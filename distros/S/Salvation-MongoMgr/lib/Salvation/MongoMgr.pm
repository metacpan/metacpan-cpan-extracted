package Salvation::MongoMgr;

use strict;
use warnings;
use boolean;

use URI ();
use Socket 'AF_INET6';
use Time::HiRes ();
use Salvation::TC ();
use List::MoreUtils 'uniq';
use Salvation::MongoMgr::Connection ();

our $VERSION = 0.06;

sub new {

    my ( $proto, %args ) = @_;

    Salvation::TC -> assert( \%args, 'HashRef(
        HashRef :connection!,
        ArrayRef[Str] :add_hosts,
        ArrayRef[Str] :exclude_hosts,
        Bool :discovery
    )' );

    unless( exists $args{ 'discovery' } ) {

        $args{ 'discovery' } = true;
    }

    my $self = bless( \%args, ( ref( $proto ) || $proto ) );

    $self -> { '_connection_args' } = delete( $self -> { 'connection' } );

    $self -> { 'connection' } = Salvation::MongoMgr::Connection
        -> new( %{ $self -> { '_connection_args' } } );

    return $self;
}

sub run {

    my ( $self, $args ) = @_;
    my $host = shift( @$args );

    Salvation::TC -> assert( [ $host, $args ], 'ArrayRef( Str host, ArrayRef[Str] args )' );

    if( $host eq '.' ) {

        undef( $host );
    }

    my $system_args = $self -> _shellcmd( $host, 'mongo', [] );

    unshift( @$system_args, 'echo', ( join( ' ', @$args ) ), '|' );

    print STDERR join( ' ', '+', @$system_args ), "\n";

    if( ( my $status = system( @$system_args ) ) != 0 ) {

        $status >>= 8;
        die( "Command failed with code ${status}" );
    }

    return [];
}

sub exec {

    my ( $self, $args ) = @_;
    my $host = shift( @$args );
    my $cmd = shift( @$args );

    Salvation::TC -> assert( [ $host, $cmd, $args ], 'ArrayRef( Str host, Str cmd, ArrayRef[Str] args )' );

    if( $host eq '.' ) {

        undef( $host );
    }

    $args = $self -> _shellcmd( $host, $cmd, $args );

    print STDERR join( ' ', '+', @$args ), "\n";

    if( ( my $status = system( @$args ) ) != 0 ) {

        $status >>= 8;
        die( "Command failed with code ${status}" );
    }

    return [];
}

sub shell {

    my ( $self, $args ) = @_;
    my $host = shift( @$args );
    my $cmd = shift( @$args );

    Salvation::TC -> assert( [ $host, $cmd, $args ], 'ArrayRef( Str host, Str cmd, ArrayRef[Str] args )' );

    if( $host eq '.' ) {

        undef( $host );
    }

    $args = $self -> _shellcmd( $host, $cmd, $args );

    print STDERR join( ' ', '+', @$args ), "\n";

    CORE::exec @$args;
}

sub _shellcmd {

    my ( $self, $host, $mode, $args ) = @_;
    my $mgr = $self -> get_host_manager( $host );

    # Ensures that we have connection to the host
    $mgr -> { 'connection' } -> get_connection();

    my $cmd = 'mongo';

    if( defined $mode ) {

        $cmd = {
            'files' => 'mongofiles',
            'mongo' => $cmd,

        } -> { $mode };

        die( "Unknown mode: ${mode}" ) unless defined $cmd;
    }

    my @db_args = ();

    if( $cmd eq 'mongo' ) {

        my $o = URI->new($mgr->{connection}->make_connection_string);
        $o->path($self -> { 'connection' } -> { 'db' });
        push( @db_args, (
            ($o->as_string)));
    }

    if( $cmd eq 'mongofiles' ) {

        push( @db_args, (
            '-h', ( $mgr -> { 'connection' } -> servers_list() -> [ 0 ] ),
            '--db', ( $self -> { 'connection' } -> { 'db' } ),
        ) );
    }

    foreach my $node ( @{ $mgr -> { 'connection' } -> servers_list() } ) {

        my @hp = split( /:/, $node );
        my $port = pop( @hp );
        my $host = join( ':', @hp );
        my $stop = ( $cmd eq 'mongofiles' );

        foreach my $ai ( Socket::getaddrinfo( $host, $port ) ) {

            next unless Salvation::TC -> is( $ai, 'HashRef( Int :family! )' );

            if( $ai -> { 'family' } == AF_INET6 ) {

                push( @db_args, '--ipv6' );
                $stop = true;
                last;
            }
        }

        last if $stop;
    }

    my ( $login, $password ) = @{ $mgr -> { 'connection' } -> credentials() }{ 'login', 'password' };

    return [
        $cmd, @db_args,
        ( defined $login ? ( '-u' => ( $login ) ) : () ),
        ( defined $password ? ( '-p' => ( $password ) ) : () ),
        ( ( defined $login || defined $password ) ? (
            '--authenticationDatabase', $self -> { 'connection' } -> { 'auth_db_name' },
        ) : () ),
        map( { ( $_ ) } @$args ),
    ];
}

sub compare_collection_hashes {

    my ( $self, $collections ) = @_;
    my @mismatch = ();
    my $hosts_count = undef;
    my %ignore_hosts = ();
    my %hashes = ();

    Salvation::TC -> assert( $collections, 'ArrayRef[Str]{1,}' );

    foreach my $collection ( @$collections ) {

        my %tree = ();
        my %retries = ();
        my $max_retries = 5;
        my $only_cached = true;

        foreach my $host ( @{ $self -> hosts_list() } ) {

            next if exists $ignore_hosts{ $host };

            local $MongoDB::Cursor::slave_okay = 1;

            my $hash = $hashes{ $host } //= eval{ $self -> db_hash(
                $host, only_cached => $only_cached,
            ) };

            $only_cached = true;

            if( $@ ) {

                print STDERR $@, "\n";
                $ignore_hosts{ $host } = 1;
                $hosts_count //= $self -> hosts_count();
                --$hosts_count;
                next;
            }

            unless( exists $hash -> { 'collections' } -> { $collection } ) {

                if( ++$retries{ $host } == $max_retries ) {

                    $only_cached = false;
                    delete( $hashes{ $host } );
                    Time::HiRes::sleep( 0.3 );
                    redo;

                } elsif( $retries{ $host } < $max_retries ) {

                    delete( $hashes{ $host } );
                    Time::HiRes::sleep( 0.3 );
                    redo;
                }
            }

            my $hash_str = ( $hash -> { 'collections' } -> { $collection } // '' );
            my $dest = $tree{ $hash_str } //= {

                hosts => [],
                hash => $hash_str,
            };

            push( @{ $dest -> { 'hosts' } }, $host );
        }

        $hosts_count //= $self -> hosts_count();

        while( my ( undef, $data ) = each( %tree ) ) {

            if( ( scalar( @{ $data -> { 'hosts' } } ) != $hosts_count ) || ( $data -> { 'hash' } eq '' ) ) {

                push( @mismatch, {
                    hash => $data -> { 'hash' },
                    collection => $collection,
                    hosts => [ grep( { ! exists $ignore_hosts{ $_ } } @{ $self -> remaining_hosts( @{ $data -> { 'hosts' } } ) } ) ],
                    msg => 'mismatch',
                } );
            }
        }
    }

    return \@mismatch;
}

sub db_hash {

    my ( $self, $host, %args ) = @_;
    my $mgr = $self -> get_host_manager( $host );
    my $rv = $mgr -> _run_config_command( { dbHash => 1 } );

    Salvation::TC -> assert( $rv, 'HashRef(
        HashRef[Str] :collections!,
        ArrayRef[Str] :fromCache!,
        Bool :ok!,
        Str :md5!
    )' );

    if( $args{ 'only_cached' } ) {

        my @from_cache = @{ $rv -> { 'fromCache' } };
        $_ =~ s/^config\.// for @from_cache;

        my %collections = ();

        @collections{ @from_cache } = @{ $rv -> { 'collections' } }{ @from_cache };

        $rv -> { 'collections' } = \%collections;
    }

    return $rv;
}

sub repl_set_status {

    my ( $self, $host ) = @_;
    my $mgr = $self -> get_host_manager( $host );
    my $rv = $mgr -> _run_admin_command( { replSetGetStatus => 1 } );

    Salvation::TC -> assert( $rv, 'HashRef(
        ArrayRef[HashRef(
            Int :_id!,
            Str :name!,
            Str :stateStr!
        )] :members!,
        Bool :ok!,
        Str :set!
    )' );

    return $rv;
}

sub list_masters {

    my ( $self ) = @_;
    my @list = ();

    foreach my $host ( @{ $self -> hosts_list() } ) {

        my $mgr = $self -> get_host_manager( $host );

        local $MongoDB::Cursor::slave_okay = 1;

        eval {

            if( $mgr -> metadata() -> { 'ismaster' } ) {

                push( @list, $host );
            }
        };

        if( $@ ) {

            print STDERR $@, "\n";
        }
    }

    return \@list;
}

sub get_indexes {

    my ( $self, $args ) = @_;
    my ( $collection, $host ) = @$args;

    Salvation::TC -> assert( [ $collection, $host ], 'ArrayRef( Str collection, Maybe[Str] host )' );

    my $mgr = $self -> get_host_manager( $host );

    local $MongoDB::Cursor::slave_okay = 1;

    return [ $mgr
        -> { 'connection' }
        -> get_collection( $collection )
        -> get_indexes() ];
}

sub compare_indexes {

    my ( $self, $collections ) = @_;
    my @missing = ();
    my $hosts_count = undef;
    my %ignore_hosts = ();

    Salvation::TC -> assert( $collections, 'ArrayRef[Str]{1,}' );

    foreach my $collection ( @$collections ) {

        my %tree = ();

        foreach my $host ( @{ $self -> hosts_list() } ) {

            next if exists $ignore_hosts{ $host };

            my $mgr = $self -> get_host_manager( $host );

            local $MongoDB::Cursor::slave_okay = 1;

            my @indexes = eval{ $mgr
                -> { 'connection' }
                -> get_collection( $collection )
                -> get_indexes() };

            if( $@ ) {

                print STDERR $@, "\n";
                $ignore_hosts{ $host } = 1;
                $hosts_count //= $self -> hosts_count();
                --$hosts_count;
                next;
            }

            foreach my $index ( @indexes ) {

                next unless Salvation::TC -> is( $index, 'HashRef(
                    HashRef[Int] :key!
                )' );

                my $dest = $tree{ join( "\0", map( { join( ':', ( $_, $index -> { 'key' } -> { $_ } ) ) }
                    sort( keys( %{ $index -> { 'key' } } ) ) ) ) } //= {

                    hosts => [],
                    index => $index,
                };

                push( @{ $dest -> { 'hosts' } }, $host );
            }
        }

        $hosts_count //= $self -> hosts_count();

        while( my ( undef, $data ) = each( %tree ) ) {

            if( scalar( @{ $data -> { 'hosts' } } ) != $hosts_count ) {

                push( @missing, {
                    index => $data -> { 'index' },
                    hosts => [ grep( { ! exists $ignore_hosts{ $_ } } @{ $self -> remaining_hosts( @{ $data -> { 'hosts' } } ) } ) ],
                    msg => 'missing',
                } );
            }
        }
    }

    return \@missing;
}

sub remaining_hosts {

    my ( $self, @list ) = @_;
    my %map = map( { $_ => 1 } @list );

    return [ grep( { ! exists $map{ $_ } } @{ $self -> hosts_list() } ) ];
}

sub hosts_count {

    my ( $self ) = @_;

    return scalar( @{ $self -> hosts_list() } );
}

sub hosts_list {

    my ( $self ) = @_;

    unless( exists $self -> { 'hosts_list' } ) {

        if( $self -> { 'discovery' } ) {

            if( $self -> is_mongos() ) {

                my @out = ();

                foreach my $shard ( @{ $self -> list_shards() } ) {

                    my $got_rs_status = false;

                    foreach my $host ( split( /\s*,\s*/, $shard -> { 'host' } ) ) {

                        $host =~ s/^.+?\///;
                        $host = lc( $host );

                        push( @out, $host );

                        unless( $got_rs_status ) {

                            my $status = eval{ $self -> repl_set_status( $host ) };

                            if( $@ ) {

                                print STDERR "$@\n";

                            } else {

                                foreach my $member ( @{ $status -> { 'members' } } ) {

                                    push( @out, lc( $member -> { 'name' } ) );
                                }

                                $got_rs_status = true;
                            }
                        }
                    }
                }

                $self -> { 'hosts_list' } = \@out;

            } else {

                my $metadata = $self -> metadata();

                if( exists $metadata -> { 'hosts' } ) {

                    my @out = ();

                    foreach my $host ( @{ $metadata -> { 'hosts' } } ) {

                        $host = lc( $host );

                        push( @out, $host );
                        my $status = eval{ $self -> repl_set_status( $host ) };

                        if( $@ ) {

                            print STDERR "$@\n";

                        } else {

                            foreach my $member ( @{ $status -> { 'members' } } ) {

                                push( @out, lc( $member -> { 'name' } ) );
                            }
                        }
                    }

                    $self -> { 'hosts_list' } = \@out;

                } else {

                    $self -> { 'hosts_list' } = [ lc( $metadata -> { 'me' } ) ];
                }
            }

        } else {

            $self -> { 'hosts_list' } = [];
        }

        if( exists $self -> { 'add_hosts' } ) {

            push( @{ $self -> { 'hosts_list' } },
                map( { lc( $_ ) } @{ $self -> { 'add_hosts' } } ) );
        }

        @{ $self -> { 'hosts_list' } } = uniq( @{ $self -> { 'hosts_list' } } );

        if( exists $self -> { 'exclude_hosts' } ) {

            my %map = map( { lc( $_ ) => 1 } @{ $self -> { 'exclude_hosts' } } );
            my @new_list = ();

            while( defined( my $host = shift( @{ $self -> { 'hosts_list' } } ) ) ) {

                unless( exists $map{ $host } ) {

                    push( @new_list, $host );
                }
            }

            $self -> { 'hosts_list' } = \@new_list;
        }
    }

    return $self -> { 'hosts_list' };
}

sub list_shards {

    my ( $self ) = @_;

    unless( exists $self -> { 'list_shards' } ) {

        my $rv = $self -> _run_admin_command( { listShards => 1 } );

        Salvation::TC -> assert( $rv, 'HashRef(
            Bool :ok!
        )' );

        if( $rv -> { 'ok' } ) {

            Salvation::TC -> assert( $rv, 'HashRef(
                ArrayRef[HashRef( Str :_id!, Str :host! )] :shards!
            )' );

            $self -> { 'list_shards' } = $rv -> { 'shards' };

        } else {

            $self -> { 'list_shards' } = [];
        }
    }

    return $self -> { 'list_shards' };
}

sub is_mongos {

    my ( $self ) = @_;

    return !! $self -> metadata() -> { 'msg' };
}

sub metadata {

    my ( $self ) = @_;

    unless( exists $self -> { 'metadata' } ) {

        my $rv = $self -> _run_admin_command( { isMaster => 1 } );

        Salvation::TC -> assert( $rv, 'HashRef(
            Str :msg,
            ArrayRef[Str] :hosts,
            Str :me
        )' );

        $self -> { 'metadata' } = $rv;
    }

    return $self -> { 'metadata' };
}

sub _run_admin_command {

    my ( $self, $spec ) = @_;

    return $self -> { 'connection' } -> get_database( 'admin' ) -> run_command( $spec );
}

sub _run_config_command {

    my ( $self, $spec ) = @_;

    return $self -> { 'connection' } -> get_database( 'config' ) -> run_command( $spec );
}

sub reload {

    my ( $self ) = @_;

    delete( @$self{ 'metadata', 'list_shards', 'hosts_list' } );

    return;
}

sub get_host_manager {

    my ( $self, $host ) = @_;

    return ( defined $host ? $self -> new(
        connection => {
            %{ $self -> { '_connection_args' } },
            host => $host,
            find_master => false,
        },
        add_hosts => [ $host ],
        discovery => false,
    ) : $self );
}


1;

__END__
