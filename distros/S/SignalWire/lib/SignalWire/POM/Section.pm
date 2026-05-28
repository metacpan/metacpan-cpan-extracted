package SignalWire::POM::Section;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# Typed POM Section — Perl port of signalwire.pom.pom.Section
# (signalwire-python/signalwire/signalwire/pom/pom.py).
#
# Each Section has a title, optional body text, optional bullet points,
# and any number of nested subsections. The class can render itself as
# Markdown or XML and serialise to a hash for JSON/YAML emission.
#
# Output format MUST match the Python reference byte-for-byte; see
# t/pom/prompt_object_model.t for the parity assertions.

use strict;
use warnings;
use Moo;
use Scalar::Util qw(blessed);
use Carp qw(croak);
use Tie::IxHash;

# ---------- attributes ----------

# title is optional only on the top-level/first section of a POM; for
# subsections the caller is required to provide one (validated in
# add_subsection / set when calling the constructor directly).
has title => (
    is      => 'rw',
    default => sub { undef },
);

has body => (
    is      => 'rw',
    default => sub { '' },
);

has bullets => (
    is      => 'rw',
    default => sub { [] },
);

has subsections => (
    is      => 'rw',
    default => sub { [] },
);

# Whether this section should be auto-numbered when rendered alongside
# numbered siblings. ``undef`` means "follow sibling default"; explicit
# 0 forces a section to stay un-numbered even when siblings are
# numbered. Mirrors Python's ``numbered`` arg semantics.
has numbered => (
    is      => 'rw',
    default => sub { undef },
);

has numberedBullets => (
    is      => 'rw',
    default => sub { 0 },
);

# ---------- BUILD: validate types of body / bullets ----------

sub BUILD {
    my ($self, $args) = @_;

    if (defined $args->{body} && ref $args->{body}) {
        croak "body must be a string, not " . ref($args->{body})
            . ". If you meant to pass a list of bullet points, use bullets parameter instead.";
    }
    if (defined $args->{bullets} && ref $args->{bullets} ne 'ARRAY') {
        croak "bullets must be a list or undef, not " . ref($args->{bullets});
    }
    return;
}

# ---------- public methods ----------

# Replace the body text on this section. Mirrors Python's
# ``Section.add_body`` which is documented to "Add OR REPLACE the body
# text" — calling this overwrites any prior value rather than appending.
sub add_body {
    my ($self, $body) = @_;
    croak "body must be a string, not " . ref($body) if ref $body;
    $self->body($body);
    return $self;
}

# Append bullets to the existing list (does NOT replace).
sub add_bullets {
    my ($self, $bullets) = @_;
    croak "bullets must be a list, not " . (ref($bullets) || 'scalar')
        if !defined $bullets || ref $bullets ne 'ARRAY';
    push @{ $self->bullets }, @$bullets;
    return $self;
}

# Add a subsection and return the newly-created Section object so the
# caller can chain ``->add_body / ->add_bullets`` onto it (matching
# Python's return-the-Section ergonomic).
sub add_subsection {
    my ($self, %opts) = @_;

    croak "Subsections must have a title" unless defined $opts{title};

    my $sub = SignalWire::POM::Section->new(
        title           => $opts{title},
        body            => exists $opts{body}            ? $opts{body}            : '',
        bullets         => exists $opts{bullets}         ? $opts{bullets}         : [],
        numbered        => exists $opts{numbered}        ? $opts{numbered}        : 0,
        numberedBullets => exists $opts{numberedBullets} ? $opts{numberedBullets} : 0,
    );
    push @{ $self->subsections }, $sub;
    return $sub;
}

# Convert the section to an ordered hashref for JSON/YAML emission.
# Key order matches Python's to_dict (title, body, bullets, subsections,
# numbered, numberedBullets). Empty fields are dropped — the resulting
# hash is suitable for `from_json` / `from_yaml` round-tripping.
sub to_hash {
    my ($self) = @_;
    tie my %data, 'Tie::IxHash';

    if (defined $self->title) {
        $data{title} = $self->title;
    }
    if (defined $self->body && length $self->body) {
        $data{body} = $self->body;
    }
    if ($self->bullets && @{ $self->bullets }) {
        $data{bullets} = [ @{ $self->bullets } ];
    }
    if ($self->subsections && @{ $self->subsections }) {
        $data{subsections} = [ map { $_->to_hash } @{ $self->subsections } ];
    }
    if ($self->numbered) {
        $data{numbered} = JSON::PP::true();
    }
    if ($self->numberedBullets) {
        $data{numberedBullets} = JSON::PP::true();
    }

    return \%data;
}

# Render this section as Markdown. ``level`` is the heading level (1=#,
# 2=##, ...). ``section_number`` is an arrayref of the section's
# position among numbered siblings (e.g. [1,2,3] for "1.2.3."). Mirrors
# Python's Section.render_markdown signature/output exactly.
sub render_markdown {
    my ($self, $level, $section_number) = @_;
    $level //= 2;
    $section_number //= [];

    my @md;

    if (defined $self->title) {
        my $prefix = '';
        if (@$section_number) {
            $prefix = join('.', @$section_number) . '. ';
        }
        push @md, ('#' x $level) . " ${prefix}" . $self->title . "\n";
    }

    if (defined $self->body && length $self->body) {
        push @md, $self->body . "\n";
    }

    if ($self->bullets && @{ $self->bullets }) {
        my $i = 0;
        for my $bullet (@{ $self->bullets }) {
            $i++;
            if ($self->numberedBullets) {
                push @md, "${i}. $bullet";
            } else {
                push @md, "- $bullet";
            }
        }
        push @md, '';
    }

    # If any subsection has numbered=true (truthy, not just defined),
    # all sibling subsections that are not explicitly numbered=>0 get
    # a number too. Matches Python's any-numbered semantics.
    my $any_subsection_numbered = 0;
    for my $sub (@{ $self->subsections }) {
        if ($sub->numbered) { $any_subsection_numbered = 1; last; }
    }

    my $i = 0;
    for my $sub (@{ $self->subsections }) {
        $i++;
        my ($new_section_number, $next_level);
        if (defined $self->title || @$section_number) {
            # Python: ``if any_subsection_numbered and subsection.numbered is not False``
            # Use defined-but-zero to mean "explicit false"; any other
            # truthy / undef value participates in numbering.
            if ($any_subsection_numbered
                && !(defined $sub->numbered && !$sub->numbered)) {
                $new_section_number = [ @$section_number, $i ];
            } else {
                $new_section_number = $section_number;
            }
            $next_level = $level + 1;
        } else {
            # Root-without-title: don't increment numbering or level.
            $new_section_number = $section_number;
            $next_level = $level;
        }
        push @md, $sub->render_markdown($next_level, $new_section_number);
    }

    return join("\n", @md);
}

# Render this section as XML. ``indent`` is the number of two-space
# indentation levels. ``section_number`` is the same numbering arrayref
# used by render_markdown. Mirrors Python's Section.render_xml exactly.
sub render_xml {
    my ($self, $indent, $section_number) = @_;
    $indent //= 0;
    $section_number //= [];

    my $indent_str = '  ' x $indent;
    my @xml;

    push @xml, "${indent_str}<section>";

    if (defined $self->title) {
        my $prefix = '';
        if (@$section_number) {
            $prefix = join('.', @$section_number) . '. ';
        }
        push @xml, "${indent_str}  <title>${prefix}" . $self->title . '</title>';
    }

    if (defined $self->body && length $self->body) {
        push @xml, "${indent_str}  <body>" . $self->body . '</body>';
    }

    if ($self->bullets && @{ $self->bullets }) {
        push @xml, "${indent_str}  <bullets>";
        my $i = 0;
        for my $bullet (@{ $self->bullets }) {
            $i++;
            if ($self->numberedBullets) {
                push @xml, "${indent_str}    <bullet id=\"${i}\">${bullet}</bullet>";
            } else {
                push @xml, "${indent_str}    <bullet>${bullet}</bullet>";
            }
        }
        push @xml, "${indent_str}  </bullets>";
    }

    if ($self->subsections && @{ $self->subsections }) {
        push @xml, "${indent_str}  <subsections>";
        my $any_subsection_numbered = 0;
        for my $sub (@{ $self->subsections }) {
            if ($sub->numbered) { $any_subsection_numbered = 1; last; }
        }
        my $i = 0;
        for my $sub (@{ $self->subsections }) {
            $i++;
            my $new_section_number;
            if (defined $self->title || @$section_number) {
                if ($any_subsection_numbered
                    && !(defined $sub->numbered && !$sub->numbered)) {
                    $new_section_number = [ @$section_number, $i ];
                } else {
                    $new_section_number = $section_number;
                }
            } else {
                $new_section_number = $section_number;
            }
            push @xml, $sub->render_xml($indent + 2, $new_section_number);
        }
        push @xml, "${indent_str}  </subsections>";
    }

    push @xml, "${indent_str}</section>";

    return join("\n", @xml);
}

1;

__END__

=head1 NAME

SignalWire::POM::Section - one section of a Prompt Object Model document

=head1 SYNOPSIS

    use SignalWire::POM::Section;

    my $section = SignalWire::POM::Section->new(
        title   => 'Greeting',
        body    => 'You are a helpful assistant.',
        bullets => ['Be polite', 'Be concise'],
    );

    my $sub = $section->add_subsection(
        title => 'Tone',
        body  => 'Speak warmly.',
    );

    print $section->render_markdown;
    print $section->render_xml;

=head1 DESCRIPTION

L<SignalWire::POM::Section> is a Perl port of
C<signalwire.pom.pom.Section> from the Python SignalWire SDK.  Both
implementations render byte-for-byte identical Markdown/XML/JSON output
so prompts authored in either language can be consumed interchangeably.

=head1 SEE ALSO

L<SignalWire::POM::PromptObjectModel> — the top-level container that
holds a list of Sections.

=cut
