package Module::Abstract;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(module_abstract);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-27'; # DATE
our $DIST = 'Module-Abstract'; # DIST
our $VERSION = '0.002'; # VERSION

sub module_abstract {
    require Module::Installed::Tiny;

    my $module = shift;

    my $src = Module::Installed::Tiny::module_source($module);

    return $1 if $src =~ /^=head1 NAME\n\n.+? - (.+)/m;
    return $1 if $src =~ /^#\s*ABSTRACT\s*:\s*(.+)/m;
    undef;
}

1;
# ABSTRACT: Extract the abstract of a locally installed Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Abstract - Extract the abstract of a locally installed Perl module

=head1 VERSION

This document describes version 0.002 of Module::Abstract (from Perl distribution Module-Abstract), released on 2021-08-27.

=head1 SYNOPSIS

 use Module::Abstract qw(module_abstract);

 say module_abstract("strict"); # => prints something like: Perl pragma to restrict unsafe constructs

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 module_abstract

Usage:

 my $abstract = module_abstract($mod_name);

Extract abstract from module source. Will first load module source using
L<Module::Installed::Tiny>'s C<module_source()> function (which dies on failure
e.g. when it can't find the module). Then will search using simple regex this
pattern:

 =head1 NAME

 Some::Module::Name - some abstract

or (usually present in L<Dist::Zilla>-managed distribution):

 #ABSTRACT: some abstract

Will return undef if abstract cannot be found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Abstract>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Abstract>.

=head1 SEE ALSO

L<App::lcpan> also contains routine to extract abstract from module. It might
use Module::Abstract in the future.

L<pmabstract> from L<App::PMUtils>, a CLI front-end for Module::Abstract.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Abstract>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
