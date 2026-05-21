package TestHelper;

use strict;
use warnings;
use utf8;

use Exporter qw(import);
use IO::Uncompress::Unzip qw($UnzipError);
use JSON::XS;
use IPC::Open3;
use Path::Tiny;
use Symbol qw(gensym);
use Text::ParseWords qw(shellwords);

our @EXPORT_OK = qw(write_fixture run_cli_capture run_cli_json run_reorder_capture slurp_zip_member);

sub run_script_capture {
    my ( $script, @args ) = @_;
    my $stderr = gensym;
    my @perl_switches =
      $ENV{HARNESS_PERL_SWITCHES} ? shellwords( $ENV{HARNESS_PERL_SWITCHES} ) : ();
    my $pid    = open3(
        undef,
        my $stdout,
        $stderr,
        $^X, @perl_switches, '-Ilib', $script, @args
    );

    my $stdout_text = do { local $/; <$stdout> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );

    my $exit_code = $? >> 8;
    return ( $exit_code, $stdout_text, $stderr_text );
}

sub write_fixture {
    my ( $dir, $name, $content ) = @_;
    my $path = path( $dir, $name );
    $path->spew_utf8($content);
    return $path;
}

sub run_cli_capture {
    my (@args) = @_;
    return run_script_capture( 'bin/omop-csv-validator', @args );
}

sub run_cli_json {
    my (@args) = @_;
    my ( $exit_code, $stdout, $stderr ) = run_cli_capture(@args);
    my $payload = eval { JSON::XS->new->decode($stdout) };
    die "Could not decode CLI JSON output (exit $exit_code): $@\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n"
      if $@;
    return ( $exit_code, $payload, $stderr );
}

sub run_reorder_capture {
    my (@args) = @_;
    return run_script_capture( 'utils/reorder-csv.pl', @args );
}

sub slurp_zip_member {
    my ( $archive_path, $member_name ) = @_;
    my $zip = IO::Uncompress::Unzip->new($archive_path)
      or die "Cannot open ZIP archive '$archive_path': $UnzipError\n";

    while (1) {
        my $header = $zip->getHeaderInfo();
        my $name   = $header->{Name};
        my $text   = q{};
        my $buffer;

        while ( $zip->read($buffer) > 0 ) {
            $text .= $buffer;
        }

        return $text if $name eq $member_name;
        last unless $zip->nextStream();
    }

    die "Archive member '$member_name' not found in '$archive_path'\n";
}

1;
