package Test::BDD::Cucumber::Definitions::File;

use strict;
use warnings;

use Const::Fast;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use File::Spec::Functions qw(catdir splitdir);
use File::Basename qw(dirname);
use IPC::Run3;
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;

our $VERSION = '0.27';

our @EXPORT_OK = qw(
    file_path_set
    file_exists
    file_noexists
    file_type_is
);
our %EXPORT_TAGS = (
    util => [
        qw(
            file_path_set
            file_exists
            file_noexists
            file_type_is
            )
    ]
);

const my %types => (
    'regular file'           => sub { return -f $_[0] },
    'directory'              => sub { return -d $_[0] },
    'symbolic link'          => sub { return -l $_[0] },
    'fifo'                   => sub { return -p $_[0] },
    'socket'                 => sub { return -S $_[0] },
    'block special file'     => sub { return -b $_[0] },
    'character special file' => sub { return -c $_[0] },
);

## no critic [Subroutines::RequireArgUnpacking]

sub file_path_set {
    my ($path) = validator_n->(@_);

    S->{file}->{path} = $path;

    return 1;
}

sub file_exists {
    my @dirs = splitdir( dirname( S->{file}->{path} ) );

    my $dirname = q{};

    for my $dir (@dirs) {
        $dirname = catdir( $dirname, $dir );

        # intermediate dir exists
        if ( !-e $dirname ) {
            fail('Intermediate directories exist');
            diag( sprintf( q{Missing directory '%s': %s}, $dirname, $! ) );

            return;
        }

        my $dirpath = _dirpath($dirname);

        # intermediate dir is available
        if ( !-e $dirpath ) {
            fail('Intermediate directories are available');
            diag( sprintf( q{Unavailable directory '%s': %s}, $dirpath, $! ) );

            return;
        }

    }

    pass('Intermediate directories exist and are available');

    if ( !ok( -e S->{file}->{path}, "File exists" ) ) {
        diag( sprintf( q{File '%s': %s}, S->{file}->{path}, $! ) );

        return;
    }

    return 1;
}

sub file_noexists {
    my @dirs = splitdir( dirname( S->{file}->{path} ) );

    my $dirname = q{};

    for my $dir (@dirs) {
        $dirname = catdir( $dirname, $dir );

        # intermediate dir no exists
        if ( !-e $dirname ) {
            pass('Intermediate directory no exists');
            diag( sprintf( q{Missing directory '%s': %s}, $dirname, $! ) );

            return 1;
        }

        my $dirpath = _dirpath($dirname);

        # intermediate dir is available
        if ( !-e $dirpath ) {
            fail('Intermediate directories is available');
            diag( sprintf( q{Unavailable directory '%s': %s}, $dirpath, $! ) );

            return;
        }
    }

    pass('Intermediate catalogs (if any) are available');

    return if ( !ok( !-e S->{file}->{path}, 'File no exists' ) );

    return 1;
}

sub file_type_is {
    my ($type) = validator_n->(@_);

    return if !file_exists();

    if ( !ok( exists $types{$type}, 'A valid file type is specified' ) ) {
        diag( 'Unknown file type ' . np $type);

        return;
    }

    if ( !ok( $types{$type}->( S->{file}->{path} ), "File type is a $type" ) ) {
        diag( sprintf( q{ Error: %s}, $! ) );

        _stat( S->{file}->{path} );

        return;
    }

    return 1;
}

sub _stat {
    my ($filename) = @_;

    run3( [ 'stat', $filename ], undef, \my $out, \my $err );

    diag( $err || $out );

    return;
}

sub _dirpath {
    my ($dirname) = @_;

    if ( $dirname ne q{/} ) {
        $dirname .= q{/};
    }

    $dirname .= q{.};

    return $dirname;
}

1;
