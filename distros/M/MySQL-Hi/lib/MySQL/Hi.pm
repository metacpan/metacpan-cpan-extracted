package MySQL::Hi;

use strict;
use warnings;

our $VERSION = "0.03";

use Carp;
use Config::Simple;

use Moose;
use Moose::Util::TypeConstraints;
use File::HomeDir;


# MySQL username
#
has user => (
    is      => 'ro',
    isa     => subtype(
        'Str' => where {
            defined
                && length > 0
                && ! /^\s*$/i
            },
            message { 'Invalid username' }
    ),
    default => sub { $ENV{USER} },
);

# Config file
#
has config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_config',
);


# Credentials:
#
# db_name => {
#     mode1 => {
#         host     => "hostname",
#         password => "t0p$ecR3T",
#         post     => 3306,
#     }
#     ...
# }
#
has cred => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[HashRef[Maybe[Str]]]]',
    lazy    => 1,
    builder => '_builder_read_credentials',
    traits  => ['Hash'],
    handles => {
        get_cred => 'get',
    },
);


# Params from the config file to be used to create credentials
# ( and default values )
#
has known_params => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        +{
            host     => 'localhost',
            port     => 3306,
            password => undef,
        };
    },
    traits  => ['Hash'],
    handles => {
        all_params    => 'keys',
        knows         => 'exists',
        default_value => 'get',
    },
);


# Builds config file name in the user directory
#
sub _build_config {
    my ( $self ) = @_;
    my $user = $self->user();
    my $home = File::HomeDir->home();
    if ( !$home ) {
        croak "Cannot detect your home directory. You should explicitly specify the path to your config file\n";
    }
    return  "$home/mysqlhi.conf";
}


# Reads credentials from the config file
#
sub _builder_read_credentials {
    my ( $self ) = @_;

    my $config = $self->config();
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

        unless ( $self->knows( $param ) ) {
            carp "Unknown param '$param'\n";
            next;
        }

        my ( $db, $mode ) = split ':', $db_mode, 2;
        $mode //= '';

        $cred{$db}{$mode}{$param} = $vars{ $key };
    }

    return \%cred;
}


# Return credentials for a specific DB and mode
#
sub get_credentials {
    my ( $self, $db, $mode ) = @_;

    my %credentials = ();

    if ( $db ) {
        if ( my $db_cred = $self->get_cred( $db ) ) {
            if ( my $db_mode = $db_cred->{ $mode } ) {
                for my $key ( $self->all_params() ) {
                    $credentials{ $key } = exists $db_mode->{ $key }
                        ? $db_mode->{ $key }
                        : $self->default_value( $key );
                }
            }
        }
    }

    return %credentials;
}


# Splits the string [db]:[mode]
#
sub _parse_db_mode {
    my ( $self, $db, $mode ) = @_;

    my ( $d, $m ) = split ':', $db, 2;

    if ( $m && $mode && $m ne $mode ) {
        croak "Don't know which mode to use: '$m' or '$mode'\n";
    }
    else {
        $m ||= $mode || '';
    }

    return ( $d, $m );
}


# Generates command line options for MySQL client
#
sub get_options {
    my ( $self, $db, $mode ) = @_;

    ( $db, $mode ) = $self->_parse_db_mode( $db, $mode );

    my %credentials = $self->get_credentials( $db, $mode );

    croak "Can't find credentials for database '$db:"
        . ( $mode || '[no mode]' )
        . "'\n"
        unless %credentials;

    $credentials{ $_ } //= ''
        for keys %credentials;

    my @options = (
        "-u" => $self->user(),
        "-h" => $credentials{host},
        "-P" => $credentials{port},
        "-p$credentials{password}",
        "-D" => $db,
    );

    return @options;
}


# Generates DSN string for mysql driver
#
sub get_dsn {
    my ( $self, $db, $mode ) = @_;

    ( $db, $mode ) = $self->_parse_db_mode( $db, $mode );

    my %credentials = $self->get_credentials( $db, $mode );

    croak "Can't find credentials for database '$db:"
        . ( $mode || '[no mode]' )
        . "'\n"
        unless %credentials;

    my $password = $credentials{password} // '';
    my $str = 'DBI:mysql:'
        . 'host=' . $credentials{host}
        . ';port=' . $credentials{port}
        . ';database=' . $db;

    return ( $str, $self->user(), $password );
}


__PACKAGE__->meta->make_immutable;

1;


__END__


=head1 NAME

MySQL::Hi - Credentials for MySQL/MariaDB from config files

=head1 SYNOPSIS

    my $hi = MySQL::Hi->new(
        user => $user,
        config => '/path/to/config.conf' );

    # Command line options
    my @options = $hi->get_options( $db, $mode );

    # DSN
    my ( $dsn, $user, $password ) = $hi->get_dsn();

=head1 DESCRIPTION

The module to read config with credentials for MySQL/MariaDB conection.

It does B<NOT> do any MySQL/MariaDB connections, it is B<ONLY> needed to
read a config file and return credentials, comannd line options for
MySQL/MariaDB client, or DSN for L<DBD::mysql> driver.

=head1 METHODS

=over

=item new( [user => $user,] [config => $config ] )

Creates an object.

=over

=item user

Username to connect to DB. If omitted, curent username is taken.

=item config

Path to a cofigfile. By default it searces for the file F<mysqlhi.conf>
in user's home directory. See L<mysqlhi/"Config file"> for config file
format.

B<NOTE:> I only tested it on Debian and Ubuntu. I have not tested it on
other operating systems. As long as it uses L<File::HomeDir> it should,
in theory, work on other OSes too. If it does not, your patches are
welcome.

=back

=item get_options( $db[, $mode] )

Returns a list of parameters which can be directly used for the command
C<exec>:

    exec 'mysql', $hi->get_options( $db, $mode );

B<NOTE:> C<exec> should be used with multiple parameters. This will make
sure that all parameters are passed to the command correctly, and it
will run C<mysql> directly without C<sh -c> predicate. As a useful side
effect, in the list of processes your MySQL/MariaDB client will not show
password.

The method accepts two parameters: C<$db> (database name) and C<$mode>
(Optional, used to specify credentials for a certain mod). See
L<mysqlhi> for information about modes.

=item get_dsn( $db[, $mode] )

Accepts the same parameter as C<get_credentials>, Returns DSN, username
and password which can be used directly in C<DBI->connect()>:

    DBI->conect( $hi->get_dsn( $db, $mode ) )

=item get_credentials( [ $db, $mode] ] )

With no param it return all parsed credentials from the config file.

If C<$db> and C<$mode> are provided, return a hashref with credentials
for this databade in this mode.

=back

=head1 BUGS

Not reported... Yet...

=head1 SEE ALSO

L<mysqlhi>

=head1 AUTHOR

Andrei Pratasavitski <andrei.protasovitski@gmail.com>

=head1 LICENSE

    This script is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

=cut
