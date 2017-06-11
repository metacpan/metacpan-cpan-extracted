package Module::CheckVersion;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2017-06-09'; # DATE
our $DIST = 'Module-CheckVersion'; # DIST
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_module_version);

our %SPEC;

$SPEC{check_module_version} = {
    v => 1.1,
    summary => 'Check module (e.g. check latest version) with CPAN '.
        '(or equivalent repo)',
    description => <<'_',

Designed to be more general and able to provide more information in the future
in addition to mere checking of latest version, but checking latest version is
currently the only implemented feature.

Can handle non-CPAN modules, as long as you put the appropriate `$AUTHORITY` in
your modules and create the `Module::CheckVersion::<scheme>` to handle your
authority scheme.

_
    args => {
        module => {
            schema => ['str*', match=>qr/\A\w+(::\w+)*\z/],
            description => <<'_',

This routine will try to load the module, and retrieve its `$VERSION`. If
loading fails will assume module's installed version is undef.

_
            req => 1,
            pos => 0,
        },
        check_latest_version => {
            schema => 'bool',
            default => 1,
        },
        default_authority_scheme => {
            schema  => 'str',
            default => 'cpan',
            description => <<'_',

If a module does not set `$AUTHORITY` (which contains string like
`<scheme>:<extra>` like `cpan:PERLANCAR`), the default authority scheme will be
determined from this setting. The module `Module::CheckVersion::<scheme>` module
is used to implement actual checking.

Can also be set to undef, in which case when module's `$AUTHORITY` is not
available, will return 412 status.

_
        },
    },
};
sub check_module_version {
    no strict 'refs';

    my %args = @_;

    my $mod = $args{module} or return [400, "Please specify module"];
    my $defscheme = $args{default_authority_scheme} // 'cpan';

    my $scheme_mod;

    my $chkres = {};

    my $code_load_scheme_mod = sub {
        return [200] if $scheme_mod;

        # GET AUTHORITY
        my $auth;
        {
            $auth = ${"$mod\::AUTHORITY"};
            last if $auth;
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
            eval { require $mod_pm; 1 };
            if ($@) {
                $chkres->{load_module_error} = $@;
            } else {
                $auth = ${"$mod\::AUTHORITY"};
                last if $auth;
            }
            $auth = "$defscheme:" if $defscheme;
            last if $auth;
            return [412, "Can't determine AUTHORITY for $mod"];
        }

        return [412, "AUTHORITY in $mod does not contain scheme"]
            unless $auth =~ /^(\w+):/;
        my $auth_scheme = $1;

        $scheme_mod = "Module::CheckVersion::$auth_scheme";
        my $mod_pm = $scheme_mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        [200];
    };

    if ($args{check_latest_version} // 1) {
        my $loadres = $code_load_scheme_mod->();
        return $loadres unless $loadres->[0] == 200;
        my $ver = ${"$mod\::VERSION"};
        my $chkres = &{"$scheme_mod\::check_latest_version"}($mod,$ver,$chkres);
        return $chkres unless $chkres->[0] == 200;
    }

    [200, "OK", $chkres];
}

1;
# ABSTRACT: Check module (e.g. check latest version) with CPAN (or equivalent repo)

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CheckVersion - Check module (e.g. check latest version) with CPAN (or equivalent repo)

=head1 VERSION

This document describes version 0.08 of Module::CheckVersion (from Perl distribution Module-CheckVersion), released on 2017-06-09.

=head1 SYNOPSIS

Check latest version of modules:

 use Module::CheckVersion qw(check_module_version);

 my $res = check_module_version(module => 'Clone');
 # sample result: [200, "OK", {latest_version=>'0.38', installed_version=>'0.37', is_latest_version=>0}]

 say "Module Clone is the latest version ($res->[2]{latest_version})"
     if $res->[2]{is_latest_version};

=head1 FUNCTIONS


=head2 check_module_version

Usage:

 check_module_version(%args) -> [status, msg, result, meta]

Check module (e.g. check latest version) with CPAN (or equivalent repo).

Designed to be more general and able to provide more information in the future
in addition to mere checking of latest version, but checking latest version is
currently the only implemented feature.

Can handle non-CPAN modules, as long as you put the appropriate C<$AUTHORITY> in
your modules and create the C<< Module::CheckVersion::E<lt>schemeE<gt> >> to handle your
authority scheme.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<check_latest_version> => I<bool> (default: 1)

=item * B<default_authority_scheme> => I<str> (default: "cpan")

If a module does not set C<$AUTHORITY> (which contains string like
C<< E<lt>schemeE<gt>:E<lt>extraE<gt> >> like C<cpan:PERLANCAR>), the default authority scheme will be
determined from this setting. The module C<< Module::CheckVersion::E<lt>schemeE<gt> >> module
is used to implement actual checking.

Can also be set to undef, in which case when module's C<$AUTHORITY> is not
available, will return 412 status.

=item * B<module>* => I<str>

This routine will try to load the module, and retrieve its C<$VERSION>. If
loading fails will assume module's installed version is undef.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CheckVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CheckVersion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CheckVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The distribution comes with a CLI: L<check-module-version>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
