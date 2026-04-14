package Software::Policies::Contributing::PerlDistZilla;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: Contributing / PerlDistZilla

our $VERSION = '0.003';

use Carp;
use Data::Section -setup;
use Text::Template ();

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $version = delete $args{'version'} // '1';
    my $format  = delete $args{'format'}  // 'markdown';

    my %attributes;
    my $attrs = delete $args{'attributes'} // {};
    $attributes{'ai_disclosure'} = $attrs->{'ai_disclosure'} // 0;
    $attributes{'ai_assisted'}   = $attrs->{'ai_assisted'}   // 1;

    croak 'Unknown arguments: ', join q{,}, keys %args if (%args);

    if ( $attributes{'ai_disclosure'} ) {
        $attributes{'ai_disclosure_text'} = _ai_assisted( $attributes{'ai_assisted'}, $format );
    }

    my ($data_section)     = __PACKAGE__ =~ m/.+::([^:]+)$/msx;
    my $data_section_label = $data_section . q{_v} . $version . q{_} . $format;
    my $template           = $self->section_data($data_section_label);
    croak "Cannot find data section $data_section_label"
      if ( !$template );
    my $text = Text::Template->fill_this_in(
        ${$template},
        HASH       => \%attributes,
        DELIMITERS => [qw/{{ }}/],
    );
    return (
        policy   => 'Contributing',
        class    => 'PerlDistZilla',
        version  => $version,
        text     => $text,
        filename => _filename($format),
        format   => $format,
    );
}

sub get_available_classes_and_versions {
    return {
        'PerlDistZilla' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'markdown' => 1,
                'text'     => 1,
            },
        },
    };
}

sub _filename {
    my ($format) = @_;
    my %formats = (
        'markdown' => 'CONTRIBUTING.md',
        'text'     => 'CONTRIBUTING.txt',
    );
    return $formats{$format};
}

sub _ai_assisted {
    my ( $wanted, $format ) = @_;
    if ($wanted) {
        if ( $format eq 'markdown' ) {
            return <<'EOF';
### AI-assisted contributions

This project uses AI-assisted development tools. If you also use AI tools
when preparing your contribution, please note the following:

- Review, understand, and test all AI-generated code before submitting.
  Do not submit raw, unreviewed AI output.
- Be prepared to disclose which AI tools you used if asked.
- Consider the ethical implications of your tool choices, particularly
  regarding training data practices.

See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for the full policy on AI usage
in this project.

EOF
        }
        else {
            return <<'EOF';
AI-assisted contributions

This project uses AI-assisted development tools. If you also use AI tools
when preparing your contribution, please note the following:

- Review, understand, and test all AI-generated code before submitting.
  Do not submit raw, unreviewed AI output.
- Be prepared to disclose which AI tools you used if asked.
- Consider the ethical implications of your tool choices, particularly
  regarding training data practices.

See file AI_DISCLOSURE.md for the full policy on AI usage
in this project.

EOF
        }
    }
    else {
        if ( $format eq 'markdown' ) {
            return <<'EOF';
### AI-assisted contributions

This project does not accept contributions that were produced with
the assistance of AI tools. This includes, but is not limited to,
code generated or substantially modified by large language models
(such as ChatGPT, Claude, or GitHub Copilot), AI-powered code
completion tools, and AI-generated documentation or test cases.

Minor incidental use of AI, such as IDE autocomplete features that
operate on local context only, is not considered a violation of this
policy.

By submitting a contribution, you represent that the work is your
own and was not produced by or with the assistance of AI tools
beyond the exception noted above.

If you are unsure whether your use of a particular tool falls under
this policy, please ask before submitting.

See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for the full rationale
behind this policy.

EOF
        }
        else {
            return <<'EOF';
AI-assisted contributions

This project does not accept contributions that were produced with
the assistance of AI tools. This includes, but is not limited to,
code generated or substantially modified by large language models
(such as ChatGPT, Claude, or GitHub Copilot), AI-powered code
completion tools, and AI-generated documentation or test cases.

Minor incidental use of AI, such as IDE autocomplete features that
operate on local context only, is not considered a violation of this
policy.

By submitting a contribution, you represent that the work is your
own and was not produced by or with the assistance of AI tools
beyond the exception noted above.

If you are unsure whether your use of a particular tool falls under
this policy, please ask before submitting.

See file AI_DISCLOSURE.md for the full rationale
behind this policy.

EOF
        }
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::Contributing::PerlDistZilla - Create project policy file: Contributing / PerlDistZilla

=head1 VERSION

version 0.003

=for Pod::Coverage new create get_available_classes_and_versions

=begin stopwords




=end stopwords

=head1 METHODS

=head2 new

=head2 create

Create the policy.

Options:

=over 8

=item class

Available classes: B<PerlDistZilla> (default).

=item version

Available versions: 1 (default).

=item format

Available formats: markdown (default), text.

=item attributes

=over 8

=item ai_disclosure

Add an AI disclosure to the policy. Allowed values: 0, 1. Default: 0.

=item ai_assisted

If I<ai_disclosure> is true, I<ai_assisted> defines if AI assisted contributions are welcome or not.
Allowed values: 0, 1. Default: 1.

=back

=back

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ PerlDistZilla_v1_markdown ]__
## HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

The distribution is managed with Dist::Zilla.  This means than many of the
usual files you might expect are not in the repository, but are generated at
release time, as is much of the documentation.  Some generated files are
kept in the repository as a convenience (e.g. Makefile.PL or cpanfile).

Generally, **you do not need Dist::Zilla to contribute patches**.  You do need
Dist::Zilla to create a tarball.  See below for guidance.

### Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use `cpanm` to
satisfy dependencies like this:

    $ cpanm --installdeps .

Otherwise, look for either a `Makefile.PL` or `cpanfile` file for
a list of dependencies to satisfy.

### Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

For most of my distributions, `prove` is entirely sufficient for you to test any
patches you have. I use `prove` for 99% of my testing during development.

### Code style and tidying

Please try to match any existing coding style.  If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

If there is a `tidyall.ini` file, you can also install Code::TidyAll and run
`tidyall` on a file or `tidyall -a` to tidy all files.

{{ $ai_disclosure_text }}### Patching documentation

Much of the documentation Pod is generated at release time.  Some is
generated boilerplate; other documentation is built from pseudo-POD
directives in the source like C<=method> or C<=func>.

If you would like to submit a documentation edit, please limit yourself to
the documentation you see.

If you see typos or documentation issues in the generated docs, please
email or open a bug ticket instead of patching.

### Installing and using Dist::Zilla

Dist::Zilla is a very powerful authoring tool, optimized for maintaining a
large number of distributions with a high degree of automation, but it has a
large dependency chain, a bit of a learning curve and requires a number of
author-specific plugins.

To install it from CPAN, I recommend one of the following approaches for
the quickest installation:

    # using CPAN.pm, but bypassing non-functional pod tests
    $ cpan TAP::Harness::Restricted
    $ PERL_MM_USE_DEFAULT=1 HARNESS_CLASS=TAP::Harness::Restricted cpan Dist::Zilla

    # using cpanm, bypassing *all* tests
    $ cpanm -n Dist::Zilla

In either case, it's probably going to take about 10 minutes.  Go for a walk,
go get a cup of your favorite beverage, take a bathroom break, or whatever.
When you get back, Dist::Zilla should be ready for you.

Then you need to install any plugins specific to this distribution:

    $ cpan `dzil authordeps`
    $ dzil authordeps | cpanm

Once installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil xtest

You can learn more about Dist::Zilla at http://dzil.org/
__[ PerlDistZilla_v1_text ]__
HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

The distribution is managed with Dist::Zilla.  This means than many of the
usual files you might expect are not in the repository, but are generated at
release time, as is much of the documentation.  Some generated files are
kept in the repository as a convenience (e.g. Makefile.PL or cpanfile).

Generally, **you do not need Dist::Zilla to contribute patches**.  You do need
Dist::Zilla to create a tarball.  See below for guidance.

Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use `cpanm` to
satisfy dependencies like this:

    $ cpanm --installdeps .

Otherwise, look for either a `Makefile.PL` or `cpanfile` file for
a list of dependencies to satisfy.

Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

For most of my distributions, `prove` is entirely sufficient for you to test any
patches you have. I use `prove` for 99% of my testing during development.

Code style and tidying

Please try to match any existing coding style.  If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

If there is a `tidyall.ini` file, you can also install Code::TidyAll and run
`tidyall` on a file or `tidyall -a` to tidy all files.

{{ $ai_disclosure_text }}Patching documentation

Much of the documentation Pod is generated at release time.  Some is
generated boilerplate; other documentation is built from pseudo-POD
directives in the source like C<=method> or C<=func>.

If you would like to submit a documentation edit, please limit yourself to
the documentation you see.

If you see typos or documentation issues in the generated docs, please
email or open a bug ticket instead of patching.

Installing and using Dist::Zilla

Dist::Zilla is a very powerful authoring tool, optimized for maintaining a
large number of distributions with a high degree of automation, but it has a
large dependency chain, a bit of a learning curve and requires a number of
author-specific plugins.

To install it from CPAN, I recommend one of the following approaches for
the quickest installation:

    # using CPAN.pm, but bypassing non-functional pod tests
    $ cpan TAP::Harness::Restricted
    $ PERL_MM_USE_DEFAULT=1 HARNESS_CLASS=TAP::Harness::Restricted cpan Dist::Zilla

    # using cpanm, bypassing *all* tests
    $ cpanm -n Dist::Zilla

In either case, it's probably going to take about 10 minutes.  Go for a walk,
go get a cup of your favorite beverage, take a bathroom break, or whatever.
When you get back, Dist::Zilla should be ready for you.

Then you need to install any plugins specific to this distribution:

    $ cpan `dzil authordeps`
    $ dzil authordeps | cpanm

Once installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil xtest

You can learn more about Dist::Zilla at http://dzil.org/
__END__
