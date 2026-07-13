package RPi::Const::BuildCheck;

use strict;
use warnings;

our $VERSION = '1.07';

# The single source of truth for the minimum wiringPi version. It absorbs the
# canonical RPi::Const::WIRINGPI_MIN_VERSION constant (the ONE place to bump);
# the literal is only a last-resort fallback if RPi::Const can't be loaded at
# configure time.
our $MIN_WIRINGPI_VERSION = eval {
    require RPi::Const;
    RPi::Const::WIRINGPI_MIN_VERSION();
} || '3.18';

sub wiringpi_build_check {
    my (%opt) = @_;

    my $na = $opt{na} // \&_default_na;

    # RPI_DIST_RELEASE bypasses the check so release tarballs can be cut on a
    # non-Pi machine (env_release overrides the env var for tests).
    my $release = exists $opt{env_release} ? $opt{env_release} : $ENV{RPI_DIST_RELEASE};
    return 1 if $release;

    if (! _header_found('wiringPi.h', %opt)) {
        return $na->(
            "wiringPi is not installed and RPI_DIST_RELEASE is not set, " .
            "exiting...\n"
        );
    }

    my $min = $opt{min_version} // $MIN_WIRINGPI_VERSION;

    my $output = exists $opt{gpio_output}
        ? $opt{gpio_output}
        : _gpio_version_output($opt{gpio_path});

    if (! defined $output) {
        return $na->(
            "can not determine wiringPi version and RPI_DIST_RELEASE is not " .
            "set. Ensure version $min or greater is installed. Can't " .
            "continue\n"
        );
    }

    my $installed = _parse_gpio_version($output);

    if (! defined $installed) {
        # An unparseable 'gpio -v' must NOT silently pass (the original guard's
        # bug): treat it exactly like an absent version - NA, not a build
        # against a possibly-too-old library.
        return $na->(
            "could not parse the wiringPi version from 'gpio -v' and " .
            "RPI_DIST_RELEASE is not set. Ensure version $min or greater is " .
            "installed. Can't continue\n"
        );
    }

    if (! version_ge($installed, $min)) {
        return $na->(
            "\nyou must have wiringPi version $min or greater installed to " .
            "continue.\n\nYou have version $installed\n"
        );
    }

    return 1;
}

sub i2c_build_check {
    my (%opt) = @_;

    my $na = $opt{na} // \&_default_na;

    my $release = exists $opt{env_release} ? $opt{env_release} : $ENV{RPI_DIST_RELEASE};
    return 1 if $release;

    my @headers = @{ $opt{headers} // ['linux/i2c-dev.h', 'linux/i2c.h'] };

    for my $header (@headers) {
        if (! _header_found($header, %opt)) {
            return $na->(
                "the I2C development header <$header> is not installed " .
                "(try 'apt-get install libi2c-dev') and RPI_DIST_RELEASE is " .
                "not set, exiting...\n"
            );
        }
    }

    return 1;
}

sub version_ge {
    # Integer (major, minor) tuple comparison - NOT a decimal or version->parse
    # compare. wiringPi minors are plain integers, so 3.8 is TEN releases older
    # than 3.18 and must fail a 3.18 minimum (the bug the old guards had).
    my ($have, $want) = @_;

    my ($h_major, $h_minor) = _split_version($have);
    my ($w_major, $w_minor) = _split_version($want);

    return 0 if ! defined $h_major || ! defined $w_major;

    return $h_major > $w_major if $h_major != $w_major;
    return $h_minor >= $w_minor;
}

# --- private helpers -------------------------------------------------------

# Is $header reachable? An explicit include_dirs opt is the EXACT search list
# (tests + manual override) - no compiler probe then. Otherwise search the two
# default prefixes first, and only on a miss fall back to the C compiler's own
# header search path, so a wiringPi/i2c header installed outside the defaults
# is still found. All I/O stays injectable via include_dirs / cc_output.
sub _header_found {
    my ($header, %opt) = @_;

    if ($opt{include_dirs}) {
        return (grep { -f "$_/$header" } @{ $opt{include_dirs} }) ? 1 : 0;
    }

    return 1 if grep { -f "$_/$header" } '/usr/include', '/usr/local/include';
    return 1 if grep { -f "$_/$header" } _compiler_include_dirs(%opt);
    return 0;
}

# Ask the C compiler where it actually searches for <...> headers, by parsing
# its verbose preprocessor output. Best-effort: any failure yields an empty
# list, never a die. $opt{cc_output} injects canned output; $opt{cc} the binary.
sub _compiler_include_dirs {
    my (%opt) = @_;

    my $output = exists $opt{cc_output}
        ? $opt{cc_output}
        : _cc_verbose_output($opt{cc});
    return if ! defined $output;

    my @dirs;
    my $in_list = 0;
    for my $line (split /\n/, $output) {
        if ($line =~ /#include\s*<\.\.\.>\s*search starts here/) {
            $in_list = 1;
            next;
        }
        last if $line =~ /End of search list/;
        next if ! $in_list;

        (my $dir = $line) =~ s/^\s+//;
        $dir =~ s/\s+$//;
        $dir =~ s/\s*\(framework directory\)$//;   # clang annotation
        push @dirs, $dir if length $dir && -d $dir;
    }

    return @dirs;
}

sub _cc_verbose_output {
    my ($cc) = @_;
    $cc = $cc // $ENV{CC} || 'cc';

    # gcc/clang emit the header search list to STDERR for an empty compile.
    my $out = `$cc -E -Wp,-v -xc /dev/null 2>&1`;
    return length $out ? $out : undef;
}

sub _split_version {
    my ($version) = @_;
    return if ! defined $version || $version !~ /^(\d+)\.(\d+)$/;
    return ($1, $2);
}

sub _parse_gpio_version {
    my ($output) = @_;
    return if ! defined $output;
    return $1 if $output =~ /version:\s*(\d+\.\d+)/i;
    return;
}

sub _gpio_version_output {
    my ($gpio_path) = @_;

    my $bin = $gpio_path;

    if (! defined $bin) {
        my ($dir) = grep { -x "$_/gpio" } split /:/, ($ENV{PATH} // '');
        $bin = defined $dir ? "$dir/gpio" : undef;
    }

    return if ! defined $bin || ! -x $bin;

    return scalar `$bin -v 2>/dev/null`;
}

sub _default_na {
    my ($message) = @_;
    print $message;
    exit 0;
}

1;

__END__

=head1 NAME

RPi::Const::BuildCheck - canonical wiringPi/I2C Makefile.PL build guards for the
RPi:: distribution family

=head1 SYNOPSIS

In an XS distribution's C<Makefile.PL>, before C<WriteMakefile>:

    use ExtUtils::MakeMaker;

    eval {
        require RPi::Const::BuildCheck;
        RPi::Const::BuildCheck->import;
    };
    if (! $@) {
        RPi::Const::BuildCheck::wiringpi_build_check();   # dists linking wiringPi
        # or, for a raw-I2C dist:
        # RPi::Const::BuildCheck::i2c_build_check();
    }

    WriteMakefile( ... );

=head1 DESCRIPTION

Every XS distribution in the C<RPi::WiringPi> family needs the same
C<Makefile.PL> guard: verify its build dependency (the wiringPi library, or the
Linux I2C development headers) is present, honour the C<RPI_DIST_RELEASE> bypass
so release tarballs can be cut on a non-Pi machine, and - crucially - C<exit 0>
B<before> C<WriteMakefile> when the dependency is missing, so CPAN testers
report C<NA> rather than C<FAIL>.

Hand-copying that logic into ~20 distributions caused drift (differing minimum
versions) and left latent bugs. This module is the single canonical
implementation, pulled in via C<CONFIGURE_REQUIRES> so it is available before
configure runs.

The minimum wiringPi version is B<not> stored here - it is
L<RPi::Const/WIRINGPI_MIN_VERSION>, the family-wide constant. This module reads
it into C<$RPi::Const::BuildCheck::MIN_WIRINGPI_VERSION>; bumping the family
minimum is a single edit to that constant and one C<RPi::Const> release.

=head1 PACKAGE VARIABLES

=head2 $MIN_WIRINGPI_VERSION

The minimum acceptable wiringPi version, read from
L<RPi::Const/WIRINGPI_MIN_VERSION> at load time (falling back to a literal only
if C<RPi::Const> can't be loaded).

=head1 FUNCTIONS

=head2 wiringpi_build_check(%opts)

For distributions that link C<-lwiringPi>. Returns true when the requirement is
satisfied (or bypassed via C<RPI_DIST_RELEASE>); otherwise it invokes the
"not available" action (by default: print a message and C<exit 0>).

It checks, in order: the C<RPI_DIST_RELEASE> bypass; that C<wiringPi.h> exists
in an include directory; that C<gpio -v> reports a version; that the version
parses; and that it is greater than or equal to L</$MIN_WIRINGPI_VERSION> using
an integer (major, minor) tuple comparison. An unparseable or absent version is
treated as NA, never a silent pass.

Header discovery searches C</usr/include> and C</usr/local/include>, and on a
miss also consults the C compiler's own C<< <...> >> search path (parsed from
its verbose preprocessor output), so a wiringPi installed outside the two
default prefixes is still found. Passing C<include_dirs> overrides this with an
exact list and skips the compiler probe.

All I/O is injectable so the logic is testable off-Pi:

    include_dirs => \@dirs      # exact header search path (skips cc probe)
    cc           => $path       # C compiler to probe (default $ENV{CC} || cc)
    cc_output    => $string     # canned `cc -E -Wp,-v` output
    gpio_output  => $string     # canned `gpio -v` output
    gpio_path    => $path       # path to the gpio binary
    min_version  => $string     # override the minimum
    env_release  => $bool       # override $ENV{RPI_DIST_RELEASE}
    na           => $coderef     # action on an unsatisfied check ($msg -> ...)

=head2 i2c_build_check(%opts)

For distributions that use the raw Linux I2C userspace interface
(C<linux/i2c-dev.h>) rather than wiringPi. Same NA-not-FAIL and
C<RPI_DIST_RELEASE> semantics; checks that the I2C development headers are
present, using the same broadened discovery as
L</wiringpi_build_check(%opts)> (default prefixes, then the compiler's search
path). Accepts C<include_dirs>, C<headers>, C<cc>, C<cc_output>, C<env_release>
and C<na> opts.

=head2 version_ge($have, $want)

Returns true if wiringPi version C<$have> is greater than or equal to C<$want>,
comparing C<major> then C<minor> as integers (so C<3.8> is older than C<3.18>).
Returns false if either version is missing or not C<< \d+.\d+ >>.

=head1 SEE ALSO

L<RPi::Const>, whose C<WIRINGPI_MIN_VERSION> constant is the canonical minimum.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut
