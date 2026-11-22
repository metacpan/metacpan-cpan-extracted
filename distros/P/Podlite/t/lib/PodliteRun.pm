package PodliteRun;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

our @EXPORT_OK = qw(run_perl);

my $LIB = File::Spec->rel2abs(
    File::Spec->catdir( ( File::Spec->splitpath(__FILE__) )[1], File::Spec->updir, File::Spec->updir, 'lib' ) );

# Runs a Perl program given as a string through standard input and returns
# its standard output, standard error and exit code separately. Nothing is
# written next to the tests: standard error goes to a temporary file.
sub run_perl {
    my ( $source, %opt ) = @_;
    my @switches = @{ $opt{switches} || [] };

    my ( $err_fh, $err_file ) = tempfile( UNLINK => 1 );
    my $in = gensym;
    my $pid = open3( $in, my $out, '>&' . fileno($err_fh), $^X, "-I$LIB", @switches, '-' );
    binmode $in;
    print {$in} $source;
    close $in;

    binmode $out;
    my $stdout = do { local $/; <$out> };
    waitpid $pid, 0;
    my $exit = $? >> 8;

    open my $read_err, '<', $err_file or die "Cannot read $err_file: $!";
    binmode $read_err;
    my $stderr = do { local $/; <$read_err> };
    close $read_err;

    return {
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr ? $stderr : '',
        exit   => $exit,
    };
}

1;
