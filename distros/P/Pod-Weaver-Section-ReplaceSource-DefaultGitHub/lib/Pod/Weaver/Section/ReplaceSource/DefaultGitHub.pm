package Pod::Weaver::Section::ReplaceSource::DefaultGitHub;

our $DATE = '2016-01-30'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use Moose;
#use Text::Wrap ();
extends 'Pod::Weaver::Section::Source::DefaultGitHub';
with 'Pod::Weaver::Role::SectionReplacer';

sub default_section_name { 'SOURCE' }

no Moose;
1;
# ABSTRACT: Add or replace a SOURCE section (repository defaults to GitHub)

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::ReplaceSource::DefaultGitHub - Add or replace a SOURCE section (repository defaults to GitHub)

=head1 VERSION

This document describes version 0.01 of Pod::Weaver::Section::ReplaceSource::DefaultGitHub (from Perl distribution Pod-Weaver-Section-ReplaceSource-DefaultGitHub), released on 2016-01-30.

=head1 SYNOPSIS

This section plugin provides the same behaviour as
L<Pod::Weaver::Section::Source::DefaultGitHub> but with the
L<Pod::Weaver::Role::SectionReplacer> role applied.

In your F<weaver.ini>:

 [ReplaceSource::DefaultGitHub]

If C<repository> is not specified in F<dist.ini>, will search for github
user/repo name from git config file (C<.git/config>).

To specify a source repository other than C<https://github.com/USER/REPO>, in
F<dist.ini>:

 [MetaResources]
 repository=http://example.com/

=head1 DESCRIPTION

This section plugin adds or replace a SOURCE section, using C<repository>
metadata or (if not specified) GitHub.

=for Pod::Coverage .*

=head1 ATTRIBUTES

=head2 text

The text that is added. C<%s> is replaced by the repository URL.

Default:

 Source repository is at LE<lt>%sE<gt>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-ReplaceSource-DefaultGitHub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-ReplaceSource-DefaultGitHub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-ReplaceSource-DefaultGitHub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Section::Source::DefaultGitHub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
