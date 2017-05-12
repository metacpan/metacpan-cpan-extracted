#!/usr/bin/perl -w

use utf8;
use strict;
use warnings;
use boolean;

BEGIN {

    require Carp;

    $SIG{ __DIE__ } = \&Carp::confess;
    $SIG{ __WARN__ } = \&Carp::cluck;
};

use JSON ();
use Getopt::Long 'GetOptions';
use Salvation::TC ();
use Salvation::MongoMgr ();

use Salvation::TC::Utils;

enum 'KnownCommands', [
    'compare_indexes', 'hosts_list', 'get_indexes', 'reload', 'list_masters',
    'shell', 'exec', 'run', 'help', 'compare_collection_hashes',
];

no Salvation::TC::Utils;

++$|;

if( scalar( @ARGV ) == 0 ) {

    help();
    exit( 0 );
}

{
    my %connection = ( discovery => true );
    my @add_hosts = ();
    my @exclude_hosts = ();
    my $auth_db_name = undef;
    my $use_auth = true;
    my $discovery = undef;
    my $pretty = true;
    my $shell = false;
    my $help = undef;

    GetOptions(
        'db=s' => \$connection{ 'db' },
        'add=s' => \@add_hosts,
        'exclude=s' => \@exclude_hosts,
        'discovery!'=> \$discovery,
        'config=s' => \$connection{ 'config_file' },
        'auth-config=s' => \$connection{ 'auth_config_file' },
        'auth!' => \$use_auth,
        'auth-db=s' => \$auth_db_name,
        'pretty!' => \$pretty,
        'shell!' => \$shell,
        'help!' => \$help,
    );

    if( $help ) {

        help();
        exit( 0 );
    }

    if( $use_auth ) {

        unless( defined $connection{ 'auth_config_file' } ) {

            delete( $connection{ 'auth_config_file' } );
        }

    } else {

        $connection{ 'auth_config_file' } = undef;
    }

    if( defined $auth_db_name ) {

        $connection{ 'auth_db_name' } = $auth_db_name;
    }

    my $mgr = Salvation::MongoMgr -> new(
        connection => \%connection,
        ( ( scalar( @add_hosts ) > 0 ) ? ( add_hosts => \@add_hosts ) : () ),
        ( ( scalar( @exclude_hosts ) > 0 ) ? ( exclude_hosts => \@exclude_hosts ) : () ),
        ( defined $discovery ? ( discovery => $discovery ) : () ),
    );

    if( $shell ) {

        while( true ) {

            print "mongomgr> ";
            my $line = readline( STDIN );

            last unless defined $line;

            chomp( $line );
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;

            if( length( $line ) > 0 ) {

                eval{ run_command( $mgr, [ split( /\s+/, $line ) ], { pretty => $pretty } ) };

                print( "$@\n" ) if $@;
            }
        }

    } else {

        run_command( $mgr, \@ARGV, { pretty => $pretty } );
    }
}

exit 0;

sub run_command {

    my ( $mgr, $args, $opts ) = @_;
    my $cmd = shift( @$args );

    unless( defined $cmd ) {

        help();
        return;
    }

    Salvation::TC -> assert( $cmd, 'KnownCommands' );

    if( $cmd eq 'help' ) {

        help();

    } else {

        my $rv = $mgr -> $cmd( $args );
        my $json = JSON -> new() -> utf8( 1 ) -> allow_blessed( 1 );

        if( $opts -> { 'pretty' } ) {

            $json = $json -> pretty();
        }

        print( $json -> encode( $rv ) . "\n" );
    }

    return;
}

sub help {

    print <<HELP;
Example usage:
    $0 --db [db name] --config [file] [command]

Required options:
    --db [db name]  Database name
    --config [file] Path to driver config file

Optional options:
    --add [host]    Explicitly add host to list
    --exclude [host]    Explicitly exclude host from list
    --no-discovery  Turn automatic hosts' discovery off
    --auth-config   Path to auth config file
                    By default it is the same as driver config file
    --no-auth   Do not use auth
    --auth-db   Authentication database
                Default is "admin"
    --no-pretty Turn pretty output off
    --shell Shell mode
    --help  Print this message and exit

Known commands:
    compare_indexes [collection1] [collectionN] Compare indexes for those
                                                collections between all hosts
    compare_collection_hashes [collection1] [collectionN] Compare hashes for those
                                                          collections between all
                                                          specified configservers
    hosts_list  List all known hosts
    get_indexes [collection] ([host])    List all indexes for specified
                                         collection
                                         By default host is current database host
    reload  Force client to reload cached data
    list_masters    List all known masters
    shell [host] [cmd] ...  Change shell to one specified by cmd which is one of
                            the following:
                                - mongo
                                - files (for mongofiles)
                            For current database host use dot symbol (.)
                            [cmd] could be followed by any number of arguments
                            being passed to the new shell
    exec [host] [cmd] ...   Exec command specified by cmd which is one of
                            the following:
                                - mongo
                                - files (for mongofiles)
                            For current database host use dot symbol (.)
                            [cmd] could be followed by any number of arguments
                            being passed to the command being run
    run [host] ...  Run database command via mongo shell on specific host
                    For current database host use dot symbol (.)
    help    Prints this message
HELP
;
}

__END__
