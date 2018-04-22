package Test::BDD::Cucumber::Definitions::File;

use strict;
use warnings;

use Const::Fast;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use File::Slurper;
use File::Spec::Functions qw(catdir splitdir);
use File::Basename qw(dirname);
use IO::Capture::Stderr;
use IPC::Run3;
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;
use Try::Tiny;

our $VERSION = '0.38';

our @EXPORT_OK = qw(File);

const my %TYPES => (
    'regular file'           => sub { return -f $_[0] },
    'directory'              => sub { return -d $_[0] },
    'symbolic link'          => sub { return -l $_[0] },
    'fifo'                   => sub { return -p $_[0] },
    'socket'                 => sub { return -S $_[0] },
    'block special file'     => sub { return -b $_[0] },
    'character special file' => sub { return -c $_[0] },
);

## no critic [Subroutines::RequireArgUnpacking]

sub File {
    return __PACKAGE__;
}

sub path_set {
    my $self = shift;
    my ($path) = validator_n->(@_);

    S->{File} = __PACKAGE__;

    S->{_File}->{path} = $path;

    return 1;
}

sub exists_yes {
    my $self = shift;

    my @dirs = splitdir( dirname( S->{_File}->{path} ) );

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

    if ( !ok( -e S->{_File}->{path}, "File exists" ) ) {
        diag( sprintf( q{File '%s': %s}, S->{_File}->{path}, $! ) );

        return;
    }

    return 1;
}

sub exists_no {
    my $self = shift;

    my @dirs = splitdir( dirname( S->{_File}->{path} ) );

    my $dirname = q{};

    for my $dir (@dirs) {
        $dirname = catdir( $dirname, $dir );

        # intermediate dir no exists
        if ( !-e $dirname ) {
            pass('Intermediate directory not exists');
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

    return if ( !ok( !-e S->{_File}->{path}, 'File not exists' ) );

    return 1;
}

sub type_is {
    my $self = shift;
    my ($type) = validator_n->(@_);

    return if !File->exists_yes();

    if ( !ok( exists $TYPES{$type}, 'A valid file type is specified' ) ) {
        diag( 'Unknown file type ' . np $type);

        return;
    }

    if ( !ok( $TYPES{$type}->( S->{_File}->{path} ), "File type is a $type" ) ) {
        diag( sprintf( q{ Error: %s}, $! ) );

        _stat( S->{_File}->{path} );

        return;
    }

    return 1;
}

sub read_text {
    my $self = shift;
    my ($encoding) = validator_n->(@_);

    return _read($encoding);
}

sub read_binary {
    my $self = shift;

    return _read();
}

sub content {
    my $self = shift;

    return S->{_File}->{content};
}

sub _read {
    my ($encoding) = @_;

    my $error;

    my $capture = IO::Capture::Stderr->new();

    $capture->start();

    S->{_File}->{content} = try {
        if ( defined $encoding ) {
            return File::Slurper::read_text( S->{_File}->{path}, $encoding );
        }
        else {
            return File::Slurper::read_binary( S->{_File}->{path} );
        }
    }
    catch {
        $error = $_[0];

        return;
    };

    $capture->stop();

    if ( !ok( !$error, qq{File read} ) ) {
        diag($error);

        for ( $capture->read ) {
            diag("Warning: $_");
        }

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
