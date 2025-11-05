package NVMPL::Utils;
use strict;
use warnings;
use feature 'say';
use Exporter 'import';
use File::Spec;
use Term::ANSIColor;

our @EXPORT_OK = qw(
    detect_platform
    normalize_path
    log_info
    log_warn
    log_error
    path_join
);


# ---------------------------------------------------------
# Detect the current OS/platform
# ---------------------------------------------------------

sub detect_platform {
    my $os = $^O;
    return 'windows' if $os =~ /MSWin/i;
    return 'macos' if $os =~ /darwin/i;
    return 'linux' if $os =~ /linux/i;
    return 'unix' if $os =~ /bsd|solaris/i;
    return 'unkown';
}

# ---------------------------------------------------------
# Normalize file paths cross-platform
# ---------------------------------------------------------

sub normalize_path {
    my ($path) = @_;
    return '' unless defined $path;

    $path =~ s#\\#/#g if detect_platform() eq 'windows';
    $path =~ s#/{2,}#/#g;
    $path =~ s#/$## unless $path eq '/';

    return $path;
}

# ---------------------------------------------------------
# Join path segments safely
# ---------------------------------------------------------

sub path_join {
    my @parts = @_;
    return normalize_path(File::Spec->catfile(@parts));
}

# ---------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------

sub log_info { _log('INFO', @_) }
sub log_warn { _log('WARN', @_) }
sub log_error { _log('ERROR', @_) }

sub _log {
    my ($level, $msg) = @_;
    my %colors = (
        INFO => 'green',
        WARN => 'yellow',
        ERROR => 'red',
    );

    my $color = $colors{$level} // 'white';
    my $timestamp = _timestamp();
    say colored("[$timestamp] [$level] $msg", $color);
}

# ---------------------------------------------------------
# Timestamp for logs
# ---------------------------------------------------------

sub _timestamp {
    my @t = localtime();
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
}

1;