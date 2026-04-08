package Module::CheckLatestVersion;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-08'; # DATE
our $DIST = 'Module-CheckLatestVersion'; # DIST
our $VERSION = '0.004'; # VERSION

## no critic: Modules::ProhibitAutomaticExportation
our @EXPORT = qw(check_latest_version);

sub check_latest_version {
    return if
        $ENV{HARNESS_ACTIVE} ||
        $ENV{RELEASE_TESTING} ||
        $ENV{AUTOMATED_TESTING} ||
        $ENV{PERL_MODULE_CHECKLATESTVERSION_SKIP};

    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $mod = shift; $mod = caller() unless $mod;
    $opts->{die} //= $ENV{PERL_MODULE_CHECKLATESTVERSION_OPT_DIE};

    require Cache::File::Simple;
    my $cachekey = __PACKAGE__ . '|' . $mod;
    my $res = Cache::File::Simple::cache($cachekey);
    unless ($res) {
        # cache miss
        require Module::CheckVersion;
        $res = Module::CheckVersion::check_module_version(module => $mod);
        Cache::File::Simple::cache($cachekey, $res);

    }

    if ($res->[0] != 200) {
        warn "Cannot check latest version of module $mod: $res->[0] - $res->[1]";
        return;
    }

    unless ($res->[2]{is_latest_version}) {
        my $msg = "Module $mod (installed version: " .
            (defined($res->[2]{installed_version}) ? $res->[2]{installed_version} : "undef") .
            ") is not the latest version (" .
            (defined($res->[2]{latest_version}) ? $res->[2]{latest_version} : "undef") .
            ").";
        if ($opts->{die}) {
            $msg .= " Please update to the latest version first.";
            die $msg;
        } else {
            $msg .= " Please consider updateing to the latest version.";
            warn $msg;
        }
    }
}

1;
# ABSTRACT: Warn/die when a module is not the latest version

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CheckLatestVersion - Warn/die when a module is not the latest version

=head1 VERSION

This document describes version 0.004 of Module::CheckLatestVersion (from Perl distribution Module-CheckLatestVersion), released on 2026-04-08.

=head1 SYNOPSIS

In F<Your/Module.pm>:

 package Your::Module;

 use Module::CheckLatestVersion; # automatically exports 'check_latest_version'

 our $VERSION = 1.23;
 our $AUTHORITY = 'cpan:PERLANCAR';

 check_latest_version();
 # check_latest_version({die=>1});

If module is not the latest version (checked against authority) then a warn
message is displayed. If the C<die> option is set, program will die.

Or, alternatively, in F<your-script.pl>:

 #!perl

 use strict;
 use warnings;
 use Module::CheckLatestVersion;
 use Your::Module;

 check_latest_version("Your::Module");
 #check_latest_version({die=>1}, "Your::Module");
 ...

=head1 DESCRIPTION

This module can be used to check other module's version against latest version
in authority. Authority can be CPAN or DarkPAN or other schemes that are
supported by L<Module::CheckVersion>.

Checking against authority is cached, by default 3600 seconds (default from
L<Cache::File::Simple>).

This can be used to ensure that scripts use the latest version of a module.

=head1 FUNCTIONS

=head2 check_latest_version

Usage:

 check_latest_version([ \%opts, ] [ $mod ])

Check module C<$mod> against authority (default is CPAN), using
L<Module::CheckVersion>. C<$mod> defaults to the caller's package. If module is
not the latest version, a warning is emitted.

When one of these environment variables are set, will skip checking (no-op):
C<HARNESS_ACTIVE>, C<RELEASE_TESTING>, C<AUTOMATED_TESTING>,
C<PERL_MODULE_CHECKLATESTVERSION_SKIP>.

Options:

=over

=item * die

Bool. If set to true, will die instead of warn.

=back

=head1 ENVIRONMENT

=head2 PERL_MODULE_CHECKLATESTVERSION_OPT_DIE

Bool. Set default value for the C<die> option.

=head2 PERL_MODULE_CHECKLATESTVERSION_SKIP

Bool. Can be set to true to skip checking.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CheckLatestVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CheckLatestVersion>.

=head1 SEE ALSO

L<Module::CheckVersion>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CheckLatestVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
