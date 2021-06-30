package Require::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-29'; # DATE
our $DIST = 'Require-Util'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Feature::Compat::Try;

use Exporter qw(import);
our @EXPORT_OK = qw(require_any try_require);

our $err;

sub require_any {
    return 1 unless @_;
    my $err;
    for my $mod (@_) {
        my $mod_pm = $mod;
        if ($mod =~ /\A\w+(::\w+)*\z/) {
            ($mod_pm = "$mod.pm") =~ s!::!/!g;
        }
        my $mod_err;
        try {
            require $mod_pm;
        } catch ($mod_err) {
            $err = $mod_err;
            next;
        };
        return $mod;
    }
    die $err;
}

sub try_require {
    my $mod = shift;

    my $mod_pm = $mod;
    if ($mod =~ /\A\w+(::\w+)*\z/) {
        ($mod_pm = "$mod.pm") =~ s!::!/!g;
    }

    my $mod_err;
    try {
        require $mod_pm;
    } catch ($mod_err) {
        $Require::Util::err = $mod_err;
        return 0;
    };
    1;
}

1;
# ABSTRACT: Utilities related to require()

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Util - Utilities related to require()

=head1 VERSION

This document describes version 0.001 of Require::Util (from Perl distribution Require-Util), released on 2021-06-29.

=head1 SYNOPSIS

 use Require::Util qw(require_any try_require);

=head1 DESCRIPTION

B<EXPERIMENTAL.>

=head1 FUNCTIONS

=head2 require_any

Usage:

 my $res = require_any $modname1, $modname2, ...;

Example:

 my $res = require_any "Foo::Bar", "Baz/Qux.pm";

Require modules listed as arguments, stopping after the first success. If all
modules cannot be loaded, will die. Module name can be specified as C<Foo::Bar>
syntax or as C<Foo/Bar.pm> syntax. Unlike C<require()> which just returns true,
upon success the function will return the module name that gets loaded.

=head2 try_require

Usage:

 my $res = try_require $modname;

Example:

 my $res = try_require "Foo::Bar";
 my $res = try_require "Foo/Bar.pm";

Try requiring specified module (wrapping the C<require> statement in a
C<try/catch> block), returning true on success or false on failure (detail error
message is stored in C<$Require::Util::err>. Module name can be specified as
C<Foo::Bar> syntax or as C<Foo/Bar.pm> syntax.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head2 Alternatives for C<try_require>

To simply check whether the module source is available without actually loading
a file, use C<module_installed> from L<Module::Installed::Tiny> or
C<check_install> from L<Module::Load::Conditional>. Module like
L<Module::Path::More> can also be used if you want to ignore C<@INC> hooks.

=head2 Alternatives for C<require_any>

Note that C<can_load> from C<Module::Load::Conditional> loads I<all> modules
instead of just one.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
