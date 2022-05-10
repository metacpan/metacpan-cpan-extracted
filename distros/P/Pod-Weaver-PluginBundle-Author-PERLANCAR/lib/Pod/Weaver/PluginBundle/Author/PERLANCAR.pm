package Pod::Weaver::PluginBundle::Author::PERLANCAR;

use 5.010001;
use strict;
use warnings;

use Pod::Weaver::Config::Assembler;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-08'; # DATE
our $DIST = 'Pod-Weaver-PluginBundle-Author-PERLANCAR'; # DIST
our $VERSION = '0.293'; # VERSION

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    return (
        [ '@Author::PERLANCAR/CorePrep', _exp('@CorePrep'), {} ],
        [ '@Author::PERLANCAR/Name', _exp('Name'), {} ],
        [ '@Author::PERLANCAR/Version', _exp('Version'), {format=>'This document describes version %v of %m (from Perl distribution %r), released on %{YYYY-MM-dd}d.'} ],
        [ '@Author::PERLANCAR/prelude', _exp('Region'), { region_name => 'prelude' } ],

        [ 'SYNOPSIS', _exp('Generic'), {} ],
        [ 'DESCRIPTION', _exp('Generic'), {} ],
        [ 'OVERVIEW', _exp('Generic'), {} ],

        [ 'ATTRIBUTES', _exp('Collect'), { command => 'attr' } ],
        [ 'METHODS', _exp('Collect'), { command => 'method' } ],
        [ 'FUNCTIONS', _exp('Collect'), { command => 'func' } ],
        #[ 'TYPES', _exp('Collect'), { command => ' } ],

        [ '@Author::PERLANCAR/Leftovers', _exp('Leftovers'), {} ],
        [ '@Author::PERLANCAR/postlude',  _exp('Region'), { region_name => 'postlude' } ],

        [ '@Author::PERLANCAR/Completion::GetoptLongComplete', _exp('Completion::GetoptLongComplete'), {} ],
        [ '@Author::PERLANCAR/Completion::GetoptLongSubcommand', _exp('Completion::GetoptLongSubcommand'), {} ],
        [ '@Author::PERLANCAR/Completion::GetoptLongMore', _exp('Completion::GetoptLongMore'), {} ],

        [ '@Author::PERLANCAR/Homepage::DefaultCPAN', _exp('Homepage::DefaultCPAN'), {} ],
        [ '@Author::PERLANCAR/Source::DefaultGitHub', _exp('Source::DefaultGitHub'), {} ],
        [ '@Author::PERLANCAR/Bugs::DefaultRT', _exp('Bugs::DefaultRT'), {} ],
        [ '@Author::PERLANCAR/Authors', _exp('Authors'), {} ],
        [ '@Author::PERLANCAR/Contributors', _exp('Contributors'), {} ],
        [ '@Author::PERLANCAR/PERLANCAR/Contributing', _exp('PERLANCAR::Contributing'), {} ],
        [ '@Author::PERLANCAR/Legal', _exp('Legal'), {} ],

        [ '@Author::PERLANCAR/Rinci', _exp('-Rinci'), {} ],

        [ '@Author::PERLANCAR/AppendPrepend', _exp('-AppendPrepend'), {} ],

        [ '@Author::PERLANCAR/EnsureUniqueSections', _exp('-EnsureUniqueSections'), {} ],
        #[ '@Author::PERLANCAR/List', _exp('-Transformer'), { transformer => 'List' } ],
        [ '@Author::PERLANCAR/SingleEncoding', _exp('-SingleEncoding'), {} ],
        [ '@Author::PERLANCAR/PERLANCAR::SortSections', _exp('-PERLANCAR::SortSections'), {} ],

    );
}

1;
# ABSTRACT: PERLANCAR's default Pod::Weaver config

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::PERLANCAR - PERLANCAR's default Pod::Weaver config

=head1 VERSION

This document describes version 0.293 of Pod::Weaver::PluginBundle::Author::PERLANCAR (from Perl distribution Pod-Weaver-PluginBundle-Author-PERLANCAR), released on 2022-05-08.

=head1 SYNOPSIS

In C<weaver.ini>:

 [@Author::PERLANCAR]

or in C<dist.ini>:

 [PodWeaver]
 config_plugin = @Author::PERLANCAR

=head1 DESCRIPTION

Equivalent to (see source code).

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-PluginBundle-Author-PERLANCAR>.

=head1 SEE ALSO

L<Pod::Weaver>

L<Dist::Zilla::PluginBundle::Author::PERLANCAR>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Sergey Romanov Steven Haryanto

=over 4

=item *

Sergey Romanov <complefor@rambler.ru>

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=back

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

This software is copyright (c) 2022, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
