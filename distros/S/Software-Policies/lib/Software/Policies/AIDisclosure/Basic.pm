package Software::Policies::AIDisclosure::Basic;
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: AIDisclosure / Basic

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
    $attributes{'contact'}  = $attrs->{'authors'}->[0] if $attrs->{'authors'};
    $attributes{'ai_tools'} = $attrs->{'ai_tools'}     if $attrs->{'ai_tools'};
    croak q{Missing attribute 'authors'}  if ( !defined $attributes{'contact'} );
    croak q{Missing attribute 'ai_tools'} if ( !defined $attributes{'ai_tools'} );

    croak 'Unknown arguments: ', join q{,}, keys %args if (%args);

    $attributes{'tools'} = delete $attributes{'ai_tools'};

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
        policy   => 'AIDisclosure',
        class    => 'Basic',
        version  => $version,
        text     => $text,
        filename => _filename($format),
        format   => $format,
    );
}

sub get_available_classes_and_versions {
    return {
        'Basic' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'markdown' => 1,
            },
        },
    };
}

sub _filename {
    my ($format) = @_;
    my %formats = ( 'markdown' => 'AI_DISCLOSURE.md', );
    return $formats{$format};
}

1;

# Removed the original text which mentioned the license.
# ## Intellectual Property and Licensing
#
# This project is licensed under the Perl 5 License (Artistic License
# 1.0 and/or GNU General Public License version 1 or later). The
# copyright status of AI-generated code is legally unsettled in most
# jurisdictions as of this writing. Users and distributors should be
# aware of this uncertainty and assess their own risk accordingly.

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::AIDisclosure::Basic - Create project policy file: AIDisclosure / Basic

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

Available classes: B<Basic> (default).

=item version

Available versions: 1 (default).

=item format

Available formats: markdown (default).

=item attributes

=over 8

=item authors

Required attribute for contact information.

=item ai_tools

Required list of ai_tools used (a string). Example: 'Claude, Copilot and Gemini'.

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
__[ Basic_v1_markdown ]__
# AI Disclosure Statement

## Overview

This project uses AI-assisted development tools as part of its
engineering workflow. This document describes how AI is used, what
safeguards are in place, and what downstream users and contributors
should know.

## AI Tools Used

AI tools used during development have included, but are not limited
to, {{ $tools }}.
This list may not be comprehensive as tools and workflows evolve
over time.

## Nature of AI Use

AI assistance has been or may be used for the following activities:

- **Code generation** - writing new code for the module and the
  executable, including subroutines, data structures, and logic.
- **Documentation** - drafting and refining POD documentation,
  README content, and inline comments.
- **Architectural design** - exploring design alternatives, evaluating
  trade-offs, and structuring the module interface.
- **Test generation** - creating test cases and test scaffolding.
- **Debugging and troubleshooting** - diagnosing issues, analysing
  error output, and suggesting fixes.
- **Refactoring** - restructuring existing code for clarity,
  performance, or maintainability.

## Human Review and Oversight

All AI-generated or AI-assisted output has been reviewed, understood,
tested, and where necessary modified by a human developer before being
committed to the repository. No code or documentation has been
committed as raw, unreviewed AI output.

This project does not engage in so-called "vibe coding", where AI
output is accepted without understanding or verification.

## Intellectual Property and Licensing

The copyright status of AI-generated code is legally unsettled in most
jurisdictions as of this writing. Users and distributors should be
aware of this uncertainty and assess their own risk accordingly.

The author(s) have made a good-faith effort to ensure that AI tools
were not used in a way that knowingly infringes on third-party
intellectual property. However, no guarantee can be made that
AI-generated output is free from similarity to existing copyrighted
code.

## Ethical Considerations

This project favours AI tools whose developers have made reasonable
efforts toward responsible and transparent data practices. This
includes, but is not limited to, consideration of how training data
was acquired, whether creators and rights holders were respected in
that process, and whether the tool provider is transparent about
their data sourcing and labour practices.

We acknowledge that full visibility into the training data and
practices of any AI provider is not currently possible from the
outside. This is a good-faith commitment to prefer tools that align
with ethical principles, not a guarantee that every tool used meets
any particular standard. As industry norms, transparency, and
available information evolve, so will our assessment of which tools
are appropriate.

## Scope

AI assistance has been used throughout the development process rather
than being confined to specific files or modules. It is not practical
to annotate individual lines or sections as "AI-generated" versus
"human-written", because most code has been iteratively developed
with a mix of both.

## Contributor Expectations

Contributors to this project are expected to:

- Disclose if they have used AI tools in preparing their contribution.
- Ensure all submitted code has been reviewed, understood, and tested
  by the contributor.
- Not submit raw, unreviewed AI output.
- Consider the ethical implications of their choice of AI tools,
  particularly regarding how the tool's model was trained and whether
  its data sourcing practices are consistent with respect for
  creators and rights holders.
- Be prepared to identify which AI tools were used if asked.

## Contact

If you have questions about AI usage in this project, please open an
issue or contact the maintainer at {{ $contact }}.

---

*This disclosure is provided voluntarily in the interest of
transparency. It will be updated as the project evolves and as
norms around AI-assisted development continue to develop.*
