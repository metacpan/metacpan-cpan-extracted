package Sort::Key::SortKey;

use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
use Module::Load::Util;
use Sort::Key ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-24'; # DATE
our $DIST = 'Sort-Key-SortKey'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = @Sort::Key::EXPORT_OK;

for my $f (qw/
                 nsort nsort_inplace
                 isort isort_inplace
                 usort usort_inplace
                 rsort rsort_inplace
                 rnsort rnsort_inplace
                 risort risort_inplace
                 rusort rusort_inplace
             /) {
    *{"$f"} = \&{"Sort::Key\::$f"};
}

for my $f (qw/
                 keysort keysort_inplace
                 rkeysort rkeysort_inplace
                 nkeysort nkeysort_inplace
                 rnkeysort rnkeysort_inplace
                 ikeysort ikeysort_inplace
                 rikeysort rikeysort_inplace
                 ukeysort ukeysort_inplace
                 rukeysort rukeysort_inplace
             /) {
    *{"$f"} = sub {
        my $sortkey = shift;
        my $is_numeric = $f =~ /^(n|rn|i|ri|u|ru)/;
        my $ns_prefixes = $is_numeric ? ["SortKey::Num", "SortKey"] : ["SortKey"];
        my ($mod, $args) = Module::Load::Util::_normalize_module_with_optional_args($sortkey);
        $mod = Module::Load::Util::_load_module({ns_prefixes=>$ns_prefixes}, $mod);
        my $keygen = &{"$mod\::gen_keygen"}(@$args);
        &{"Sort::Key::$f"}(sub { $keygen->($_) }, @_);
    };
}

for my $f (qw/
                 multikeysorter multikeysorter_inplace
             /) {
    # XXX currently we don't wrap
    *{"$f"} = \&{"Sort::Key\::$f"};
}

1;
# ABSTRACT: Thin wrapper for Sort::Key to easily use SortKey::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Key::SortKey - Thin wrapper for Sort::Key to easily use SortKey::*

=head1 VERSION

This document describes version 0.001 of Sort::Key::SortKey (from Perl distribution Sort-Key-SortKey), released on 2024-01-24.

=head1 SYNOPSIS

 use Sort::Key::SortKey qw(nkeysort);

 my @sorted = nkeysort "pattern_count=string.foo", @items; # see SortKey::Num::pattern_count
 my @sorted = nkeysort [pattern_count => {string=>"foo"}], @items; # ditto
 ...

=head1 DESCRIPTION

This is a thin wrapper for L<Sort::Key>. Instead of directly specifying a
codeblock, you specify a L<SortKey> module name with optional arguments.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Key-SortKey>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Key-SortKey>.

=head1 SEE ALSO

L<Sort::Key>

L<SortKey>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Key-SortKey>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
