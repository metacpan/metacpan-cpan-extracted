package SignalWire::POM::PromptObjectModel;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# Typed Prompt Object Model — Perl port of
# signalwire.pom.pom.PromptObjectModel
# (signalwire-python/signalwire/signalwire/pom/pom.py).
#
# A POM is an ordered tree of L<SignalWire::POM::Section> objects that
# collectively describe a structured prompt for a large language model.
# This class exposes JSON / YAML serialisation, Markdown / XML rendering,
# and a search/append API that matches the Python reference exactly.
#
# Output format MUST match the Python reference byte-for-byte; see
# t/pom/prompt_object_model.t for the parity assertions.

use strict;
use warnings;
use Moo;
use Scalar::Util qw(blessed);
use Carp qw(croak);
use JSON::PP ();
use Tie::IxHash;
use SignalWire::POM::Section;

# ---------- attributes ----------

has sections => (
    is      => 'rw',
    default => sub { [] },
);

has debug => (
    is      => 'rw',
    default => sub { 0 },
);

# ---------- Class methods (constructors from JSON / YAML) ----------

# Build a PromptObjectModel from JSON. Accepts either a JSON string or
# an already-decoded arrayref (mirroring Python's overloaded contract).
#
# Python signature: ``@staticmethod from_json(json_data)``. The
# ``$class_or_self`` receiver name is the SDK-wide convention for
# Perl methods that mirror Python ``@staticmethod`` helpers — both
# ``Class->from_json($data)`` and ``$instance->from_json($data)`` work,
# and the cross-language signature diff strips the receiver entirely.
sub from_json {
    my ($class_or_self, $json_data) = @_;
    my $class = ref($class_or_self) || $class_or_self;
    my $data;
    if (!ref $json_data) {
        $data = JSON::PP::decode_json($json_data);
    } else {
        $data = $json_data;
    }
    return $class->_from_data($data);
}

# Build a PromptObjectModel from YAML. Accepts either a YAML string or
# an already-decoded arrayref. Requires YAML::PP at runtime — loaded
# lazily so JSON-only callers don't pay the dependency.
#
# Python signature: ``@staticmethod from_yaml(yaml_data)`` — the
# ``$class_or_self`` receiver name marks it as a static helper for
# the cross-language diff (see ``from_json`` above).
sub from_yaml {
    my ($class_or_self, $yaml_data) = @_;
    my $class = ref($class_or_self) || $class_or_self;
    my $data;
    if (!ref $yaml_data) {
        require YAML::PP;
        require YAML::PP::Common;
        my $yp = YAML::PP->new(
            preserve => YAML::PP::Common::PRESERVE_ORDER(),
        );
        $data = $yp->load_string($yaml_data);
    } else {
        $data = $yaml_data;
    }
    return $class->_from_data($data);
}

# Internal factory: walk a list of section hashrefs and build the
# Section tree. Validates the same constraints Python's _from_dict
# enforces (title type, bullets type, every section has a body or
# bullets or subsections, only the first top-level section may omit
# its title).
sub _from_data {
    my ($class, $data) = @_;
    croak "POM data must be an arrayref of section hashes"
        unless ref $data eq 'ARRAY';

    my $self = $class->new;
    my $i = 0;
    for my $sec (@$data) {
        croak "Each POM section must be a hashref" unless ref $sec eq 'HASH';
        # Python: "only the first section can have no title" — Python
        # silently sets a default title; mirror that.
        if ($i > 0 && !exists $sec->{title}) {
            $sec->{title} = 'Untitled Section';
        }
        push @{ $self->sections }, _build_section_from_hash($sec, 0);
        $i++;
    }
    return $self;
}

sub _build_section_from_hash {
    my ($d, $is_subsection) = @_;
    croak "Each section must be a hashref" unless ref $d eq 'HASH';

    if (exists $d->{title} && defined $d->{title} && ref $d->{title}) {
        croak "'title' must be a string if present";
    }
    if (exists $d->{subsections} && ref $d->{subsections} ne 'ARRAY') {
        croak "'subsections' must be an arrayref if provided";
    }
    if (exists $d->{bullets} && ref $d->{bullets} ne 'ARRAY') {
        croak "'bullets' must be an arrayref if provided";
    }
    if (exists $d->{numbered}) {
        my $v = $d->{numbered};
        croak "'numbered' must be a boolean if provided"
            if ref $v && !( JSON::PP::is_bool($v) );
    }
    if (exists $d->{numberedBullets}) {
        my $v = $d->{numberedBullets};
        croak "'numberedBullets' must be a boolean if provided"
            if ref $v && !( JSON::PP::is_bool($v) );
    }

    my $has_body        = (exists $d->{body} && defined $d->{body} && length $d->{body}) ? 1 : 0;
    my $has_bullets     = (exists $d->{bullets} && @{ $d->{bullets} || [] }) ? 1 : 0;
    my $has_subsections = (exists $d->{subsections} && @{ $d->{subsections} || [] }) ? 1 : 0;
    if (!$has_body && !$has_bullets && !$has_subsections) {
        croak "All sections must have either a non-empty body, non-empty bullets, or subsections";
    }

    if ($is_subsection && !exists $d->{title}) {
        croak "All subsections must have a title";
    }

    my %args = (
        title   => $d->{title},
        body    => exists $d->{body}    ? $d->{body}    : '',
        bullets => exists $d->{bullets} ? [ @{ $d->{bullets} } ] : [],
    );
    if (exists $d->{numbered}) {
        $args{numbered} = $d->{numbered} ? 1 : 0;
    }
    if (exists $d->{numberedBullets}) {
        $args{numberedBullets} = $d->{numberedBullets} ? 1 : 0;
    }

    my $section = SignalWire::POM::Section->new(%args);
    for my $sub (@{ $d->{subsections} || [] }) {
        push @{ $section->subsections }, _build_section_from_hash($sub, 1);
    }
    return $section;
}

# ---------- public methods ----------

# Append a top-level section to the model and return the new Section
# object. ``title`` may be undef ONLY for the very first section (this
# is the Python contract — the first section of a POM may render
# title-less prose).
sub add_section {
    my ($self, %opts) = @_;

    if (!defined $opts{title} && @{ $self->sections } > 0) {
        croak "Only the first section can have no title";
    }

    # Python accepts either a single string OR a list for ``bullets``;
    # normalize to a list here.
    my $bullets = $opts{bullets};
    if (defined $bullets && !ref $bullets) {
        $bullets = [ $bullets ];
    } elsif (!defined $bullets) {
        $bullets = [];
    }

    my $section = SignalWire::POM::Section->new(
        title           => $opts{title},
        body            => exists $opts{body}            ? $opts{body}            : '',
        bullets         => $bullets,
        numbered        => exists $opts{numbered}        ? $opts{numbered}        : undef,
        numberedBullets => exists $opts{numberedBullets} ? $opts{numberedBullets} : 0,
    );
    push @{ $self->sections }, $section;
    return $section;
}

# Recursive depth-first search by title. Returns the first matching
# Section (or undef). Mirrors Python's find_section.
sub find_section {
    my ($self, $title) = @_;
    return _find_in($self->sections, $title);
}

sub _find_in {
    my ($sections, $title) = @_;
    for my $s (@$sections) {
        return $s if defined $s->title && $s->title eq $title;
        my $found = _find_in($s->subsections, $title);
        return $found if defined $found;
    }
    return undef;
}

# JSON-encoded representation. Output is byte-for-byte identical to
# Python's ``PromptObjectModel.to_json`` (2-space indent, no trailing
# newline, key order title/body/bullets/subsections/numbered/
# numberedBullets).
sub to_json {
    my ($self) = @_;
    my $j = JSON::PP->new
        ->indent(1)
        ->indent_length(2)
        ->space_after
        ->canonical(0);
    my $out = $j->encode($self->to_hash);
    # JSON::PP appends ``\n`` in indent mode; Python's ``json.dumps`` does not.
    chomp $out;
    return $out;
}

# YAML-encoded representation. Output matches Python's
# ``yaml.dump(..., default_flow_style=False, sort_keys=False)``.
sub to_yaml {
    my ($self) = @_;
    require YAML::PP;
    require YAML::PP::Common;
    my $yp = YAML::PP->new(
        header   => 0,
        preserve => YAML::PP::Common::PRESERVE_ORDER(),
    );
    return $yp->dump_string($self->to_hash);
}

# Convert to an arrayref of section hashes (one per top-level section).
# Each Section is itself converted via Section::to_hash, preserving the
# Python key order so JSON / YAML output is stable.
sub to_hash {
    my ($self) = @_;
    return [ map { $_->to_hash } @{ $self->sections } ];
}

# Render the entire POM as Markdown. Auto-numbers top-level sections
# when any sibling has ``numbered => 1``. Mirrors Python's
# ``PromptObjectModel.render_markdown``.
sub render_markdown {
    my ($self) = @_;

    my $any_section_numbered = 0;
    for my $sec (@{ $self->sections }) {
        if ($sec->numbered) { $any_section_numbered = 1; last; }
    }

    my @md;
    my $section_counter = 0;
    for my $sec (@{ $self->sections }) {
        my $section_number;
        if (defined $sec->title) {
            $section_counter++;
            if ($any_section_numbered
                && !(defined $sec->numbered && !$sec->numbered)) {
                $section_number = [ $section_counter ];
            } else {
                $section_number = [];
            }
        } else {
            $section_number = [];
        }
        push @md, $sec->render_markdown(2, $section_number);
    }
    return join("\n", @md);
}

# Render the entire POM as XML. Wraps a series of <section> elements in
# a <prompt> root with the standard XML declaration. Mirrors Python's
# ``PromptObjectModel.render_xml``.
sub render_xml {
    my ($self) = @_;

    my @xml = (
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<prompt>',
    );

    my $any_section_numbered = 0;
    for my $sec (@{ $self->sections }) {
        if ($sec->numbered) { $any_section_numbered = 1; last; }
    }

    my $section_counter = 0;
    for my $sec (@{ $self->sections }) {
        my $section_number;
        if (defined $sec->title) {
            $section_counter++;
            if ($any_section_numbered
                && !(defined $sec->numbered && !$sec->numbered)) {
                $section_number = [ $section_counter ];
            } else {
                $section_number = [];
            }
        } else {
            $section_number = [];
        }
        push @xml, $sec->render_xml(1, $section_number);
    }

    push @xml, '</prompt>';
    return join("\n", @xml);
}

# Append the sections of another POM as subsections of a section in
# this POM, identified either by title (string lookup) or by passing a
# Section object directly. Mirrors Python's add_pom_as_subsection.
sub add_pom_as_subsection {
    my ($self, $target, $pom_to_add) = @_;
    my $target_section;
    if (!ref $target) {
        $target_section = $self->find_section($target);
        croak "No section with title '${target}' found." unless $target_section;
    } elsif (blessed($target) && $target->isa('SignalWire::POM::Section')) {
        $target_section = $target;
    } else {
        croak "Target must be a string or a SignalWire::POM::Section object.";
    }

    croak "pom_to_add must be a SignalWire::POM::PromptObjectModel"
        unless blessed($pom_to_add)
        && $pom_to_add->isa('SignalWire::POM::PromptObjectModel');

    for my $sec (@{ $pom_to_add->sections }) {
        push @{ $target_section->subsections }, $sec;
    }
    return $self;
}

1;

__END__

=head1 NAME

SignalWire::POM::PromptObjectModel - structured prompt document for LLMs

=head1 SYNOPSIS

    use SignalWire::POM::PromptObjectModel;

    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $sec = $pom->add_section(
        title => 'Greeting',
        body  => 'You are a helpful assistant.',
    );
    $sec->add_subsection(
        title => 'Tone',
        body  => 'Speak warmly.',
    );

    print $pom->render_markdown;
    print $pom->render_xml;

    my $json = $pom->to_json;
    my $back = SignalWire::POM::PromptObjectModel->from_json($json);

=head1 DESCRIPTION

L<SignalWire::POM::PromptObjectModel> is a Perl port of
C<signalwire.pom.pom.PromptObjectModel> from the Python SignalWire SDK.
It owns an ordered list of L<SignalWire::POM::Section> objects and
provides JSON / YAML serialisation, Markdown / XML rendering, recursive
title-based search, and POM-merging via C<add_pom_as_subsection>.

The serialised form is byte-for-byte identical to the Python reference;
prompts authored in either language can be loaded by the other.

=head1 SEE ALSO

L<SignalWire::POM::Section>

=cut
