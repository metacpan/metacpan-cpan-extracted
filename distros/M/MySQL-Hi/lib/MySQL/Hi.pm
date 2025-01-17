package MySQL::Hi;

use strict;
use warnings;

our $VERSION = "1.00";

use Carp;
use Config::Simple;

use File::HomeDir;

# Defaults
#
my %defaults = (
    host     => 'localhost',
    port     => 3306,
    password => '',
);


# Constructor
#
# IN:
#     %params = (
#         user =>   'john_doe',
#         config => '/home/john_doe/mysqlhi.conf',
#     );
#
sub new {
    my ( $class, %params ) = @_;

    my ( $user, $config ) = _parse_params( %params );
    my $cred              = _read_credentials( $config );

    my $self = bless {
        _user    => $user,
        _config  => $config,
        _cred    => $cred,
        _options => {},
        _dsn     => {},
    }, $class;

    return $self;
}


# Parse params
#
sub _parse_params {
    my ( %params ) = @_;
    my $user   = delete $params{user};

    if ( defined $user ) {
        $user =~ s/\s//g;
        croak "Invalid user"
            if length( $user ) == 0;
    }
    else {
        $user = $ENV{USER};
    }

    # Get config
    my $config = delete $params{config};

    if ( !defined( $config ) || length( $config ) == 0 ) {
        my $home = File::HomeDir->home();
        if ( !$home ) {
            croak "Cannot detect your home directory. You should explicitly specify the path to your config file\n";
        }
        $config = "$home/mysqlhi.conf";
    }

    if ( my @keys = keys %params ) {
        carp "Unknown constructor params: " . join(", ", @keys )
    }

    return ( $user, $config );
}


# Makes sure that db name and mode are correct
#
sub _parse_db_mode {
    my ( $db, $mode ) = @_;

    # DB name must exist
    if ( !defined $db || $db =~ /^\s*$/ ) {
        croak "No DB name provided";
    }

    $db =~ s/^\s+//;
    $db =~ s/\s+$//;

    # Empty or only spaces for $mode means no mode
    if ( defined $mode ) {
        $mode =~ s/^\s+//;
        $mode =~ s/\s+$//;
        if ( $mode =~ /^\s*$/ ) {
            undef $mode;
        }
    }

    # Allowing $db to contain mode.
    my $db_mode = join ':', $db, ( $mode // () );
    my @db_mode = split ':', $db_mode, 2;
    $db_mode = join ':', @db_mode;
    return wantarray
        ?  ( $db_mode[0], $db_mode[1], $db_mode )
        : $db_mode;
}


# Read credentials from the config file
#
sub _read_credentials {
    my $config = shift;
    if ( !-f $config ) {
        croak "File '$config' does not exist\n";
    }

    my $cfg = Config::Simple->new();
    $cfg->read( $config )
        or croak $cfg->error() . "\n";

    my %cred = ();
    my %vars = $cfg->vars();
    for my $key ( keys %vars ) {
        if ( $key !~ /\./ ) {
            carp "Unknown parameter '$key' in config file, ignoring\n";
            next;
        }
        my ( $db_mode, $param ) = split '\.', $key, 2;

        $db_mode = _parse_db_mode( $db_mode );

        # Fill in with default values
        if ( !exists $cred{ $db_mode } ) {
            for my $default ( keys %defaults ) {
                $cred{ $db_mode }{ $default } = $defaults{ $default };
            }
        }

        unless ( exists $defaults{ $param } ) {
            carp "Unknown parameter '$param' in [$db_mode]\n";
            next;
        }

        $cred{ $db_mode }{ $param } = $vars{ $key };
    }

    return \%cred;
}


# Accessors
#
sub user {
    return $_[0]->{_user};
}

sub config {
    return $_[0]->{_config};
}

sub default_value {
    my ( $self, $key ) = @_;
    return exists $defaults{ $key }
        ? $defaults{ $key }
        : undef;
}

# Return credentials for a specific DB and mode
#
sub get_credentials {
    my ( $self, $db, $mode ) = @_;

    return $self->{_cred}
        if !$db;

    my $db_mode = join(':', $db, ($mode || () ) );

    return $self->{_cred}{ $db_mode }
        if exists $self->{_cred}{ $db_mode };

    carp "No credentials for the '$db_mode' in config $self->{_config}\n";
    return \%defaults;
}


# Generates command line options for MySQL client
#
sub get_options {
    my ( $self, $db, $mode ) = @_;

    ( $db, $mode, my $db_mode ) = _parse_db_mode( $db, $mode );

    if ( !exists $self->{_options}{ $db_mode } ) {
        my $credentials = $self->get_credentials( $db, $mode );

        $self->{_options}{ $db_mode } = [
            "-u" => $self->user(),
            "-h" => $credentials->{host},
            "-P" => $credentials->{port},
            "-p$credentials->{password}",
            "-D" => $db,
        ];
    }

    return @{ $self->{_options}{ $db_mode } };
}


# Generates DSN string for mysql driver
#
sub get_dsn {
    my ( $self, $db, $mode ) = @_;

    ( $db, $mode, my $db_mode ) = _parse_db_mode( $db, $mode );

    if ( !exists $self->{_dsn}{ $db_mode } ) {
        my $credentials = $self->get_credentials( $db, $mode );

        $self->{_dsn}{ $db_mode } = [
            'DBI:mysql:'
            . 'host=' . $credentials->{host}
            . ';port=' . $credentials->{port}
            . ';database=' . $db,
            $self->user(),
            $credentials->{password} // ''
        ];
    }

    return @{ $self->{_dsn}{ $db_mode } };
}



1;


__END__


=head1 NAME

MySQL::Hi - Credentials for MySQL/MariaDB from config files

=head1 SYNOPSIS

    my $hi = MySQL::Hi->new(
        user => $user,
        config => '/path/to/config.conf'
    );

    # Command line options
    my @options = $hi->get_options( $db, $mode );

    # DSN
    my ( $dsn, $user, $password ) = $hi->get_dsn();

=head1 DESCRIPTION

The module reads a config file and memorises the settings which are
necessary to connect to MySQL/MariaDB. It B<DOES NOT> perform any
conections, but rather provides a convenient way to get credentials for
accessing MySQL/MariaDB servers from Perl code or CLI.

The module is used in the L<mysqlhi> script, which is a part of this
distribution. The script prepares and executes C<mysql> command for
fast access to MySQL/MariaDB from command line.

It can also be used in Perl code to get DSN from a config file ready to
pass to L<DBD::mysql> driver.

=head1 METHODS

=over

=item new( [user => $user,] [config => $config ] )

Creates an object.

=over

=item user

Username to connect to DB. If omitted, curent username is taken.

=item config

Path to a cofigfile. By default it searces for the file F<mysqlhi.conf>
in the user's home directory. See L<mysqlhi/"Config file"> for config
file format.

B<NOTE:> I only tested it on Linux, not on other operating systems. As
long as it uses L<File::HomeDir> it should, in theory, work on other OSes
too. If it does not, your patches are welcome.

=back

=item get_options( $db[, $mode] )

Returns a list of parameters which can be directly used for the command
C<exec>:

    exec 'mysql', $hi->get_options( $db, $mode );

B<NOTE:> C<exec> should be used with multiple parameters. This will make
sure that all parameters are passed to the command correctly, and that
C<mysql> runs directly without C<sh -c> predicate, which, in turn,
guarantees that MySQL password is not exposed in the list of processes.

The method accepts two parameters: C<$db> (database name) and C<$mode>
(optional, used to specify credentials for a certain mode).
See L<mysqlhi> for information about modes.

=item get_dsn( $db[, $mode] )

Accepts the same parameter as C<get_credentials>, returns DSN, username
and password which can be used directly in C<DBI->connect()>:

    DBI->conect( $hi->get_dsn( $db, $mode ) )

=item get_credentials( [ $db, $mode] ] )

If C<$db> and C<$mode> are provided, returns a hashref with credentials
for this databade in this mode. Returns default settings otherwise:

    {
        host     => 'localhost',
        port     => 3306,
        password => '',
    }

=back

=head1 BUGS

Not reported... Yet...

=head1 SEE ALSO

L<mysqlhi>

=head1 AUTHOR

Andrei Pratasavitski <andrei.protasovitski@gmail.com>

=head1 LICENSE

    This module is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

=cut
