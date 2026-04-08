package Module::CheckVersion;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-08'; # DATE
our $DIST = 'Module-CheckVersion'; # DIST
our $VERSION = '0.091'; # VERSION

our @EXPORT_OK = qw(check_module_version);

our %SPEC;

$SPEC{check_module_version} = {
    v => 1.1,
    summary => 'Check module version against the authority (CPAN or elsewhere)',
    description => <<'MARKDOWN',

Designed to be more general and able to provide more information in the future
in addition to mere checking of latest version, but checking latest version is
currently the only implemented feature.

Can handle non-CPAN modules, as long as you put the appropriate `$AUTHORITY` in
your modules and create the `Module::CheckVersion::AuthorityScheme::<scheme>` to
handle your authority scheme.

MARKDOWN
    args => {
        module => {
            schema => ['str*', match=>qr/\A\w+(::\w+)*\z/],
            description => <<'MARKDOWN',

This routine will try to load the module, and retrieve its `$VERSION`. If
loading fails will assume module's installed version is undef.

MARKDOWN
            req => 1,
            pos => 0,
        },
        check_latest_version => {
            schema => 'bool',
            default => 1,
            description => <<'MARKDOWN',

If set to 0, will just check installed version.

MARKDOWN
        },
        default_authority_scheme => {
            schema  => 'str',
            default => 'cpan',
            description => <<'MARKDOWN',

If a module does not set authority, the default authority scheme will be
determined from this setting. The module
`Module::CheckVersion::AuthorityScheme::<scheme>` module is used to implement
actual checking.

How module's authority is retrieved: First, if `$module->can("AUTHORITY")` then
`AUTHORITY` method is called. Otherwise, `$AUTHORITY` package variable is used.

Can also be set to undef, in which case when module's authority is not
available, will return 412 status.

MARKDOWN
        },
    },
};
sub check_module_version {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my %args = @_;
    my $mod = $args{module} or return [400, "Please specify module"];
    my $check_latest_version = $args{check_latest_version} // 1;
    my $default_authority_scheme = $args{default_authority_scheme} // 'cpan';

    my $res = {};

  LOAD_MODULE: {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        eval { require $mod_pm; 1 };
        $res->{load_module_error} = $@ if $@;
        $res->{installed_version} = do {
            if ($mod->can("VERSION")) {
                $mod->VERSION;
            } else {
                ${"$mod\::VERSION"};
            }
        };
    } # LOAD_MODULE

  CHECK_LATEST_VERSION: {
        last unless $check_latest_version;

        my $authority;
      GET_AUTHORITY: {
            if ($mod->can("AUTHORITY")) {
                $authority = $mod->AUTHORITY;
            } else {
                $authority = ${"$mod\::AUTHORITY"};
            }
            unless ($authority) {
                $authority = "$default_authority_scheme:"
                    if $default_authority_scheme;
            }
            unless ($authority) {
                return [412, "Can't determine authority for module $mod"];
            }
        } # GET_AUTHORITY

        return [412, "Module $mod\'s authority '$authority' does not contain scheme"]
            unless $authority =~ /^(\w+):(.*)/;
        my ($authority_scheme, $authority_content) = ($1, $2);

        my $scheme_mod;
      LOAD_CHECKER_MODULE: {
            $scheme_mod = "Module::CheckVersion::AuthorityScheme::$authority_scheme";
            (my $scheme_mod_pm = "$scheme_mod.pm") =~ s!::!/!g;
            require $scheme_mod_pm;
            return [500, "Cannot load checker module for authority scheme '$authority_scheme'"]
                if $@;
        } # LOAD_CHECKER_MODULE

        my $clvres = &{"$scheme_mod\::check_latest_version"}(
            $mod, $authority_scheme, $authority_content);

        if ($clvres->[0] == 200) {
            $res->{latest_version} = $clvres->[2];
        } else {
            $res->{check_latest_version_error} = $clvres->[1];
        }

    } # CHECK_LATEST_VERSION

    if ($res->{installed_version} && $res->{latest_version}) {
        my $cmp = eval {
            version->parse($res->{installed_version}) <=>
                version->parse($res->{latest_version});
        };
        if ($@) {
            $res->{compare_version_error} = @_;
            $res->{is_latest_version} = undef;
        } else {
            $res->{is_latest_version} = $cmp >= 0 ? 1:0;
        }
    }

    [200, "OK", $res];
}

1;
# ABSTRACT: Check module version against the authority (CPAN or elsewhere)

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CheckVersion - Check module version against the authority (CPAN or elsewhere)

=head1 VERSION

This document describes version 0.091 of Module::CheckVersion (from Perl distribution Module-CheckVersion), released on 2026-04-08.

=head1 SYNOPSIS

Check latest version of modules:

 use Module::CheckVersion qw(check_module_version);

 my $res = check_module_version(module => 'Clone');
 # sample result: [200, "OK", {latest_version=>'0.38', installed_version=>'0.37', is_latest_version=>0}]

 say "Module Clone is the latest version ($res->[2]{latest_version})"
     if $res->[2]{is_latest_version};

=head1 FUNCTIONS

=head2 check_module_version

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CheckVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CheckVersion>.

=head1 SEE ALSO

The distribution comes with a CLI: L<check-module-version>.

x_authority key in L<CPAN::Meta::X>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CheckVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
