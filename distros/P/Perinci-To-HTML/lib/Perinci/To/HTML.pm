package Perinci::To::HTML;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Log::Any::IfLOG '$log';
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-HTML';

extends 'Perinci::To::PackageBase';

has heading_level => (is => 'rw', default=>sub{1});

sub BUILD {
    my ($self, $args) = @_;
}

sub _md2html {
    require Text::Markdown;

    my ($self, $md) = @_;
    state $m2h = Text::Markdown->new;
    $m2h->markdown($md);
}

sub h {
    my ($self, $level, $text) = @_;
    $level += $self->heading_level;

    "<h$level>$text</h$level>";
}

sub span {
    my ($self, $class, $text) = @_;
    qq[<span class="$class">$text</span>];
}

sub start_div {
    my ($self, $class) = @_;
    $self->add_doc_lines(qq[<div class="$class">]);
    $self->inc_indent;
}

sub end_div {
    my ($self, $class) = @_;
    $self->dec_indent;
    $self->add_doc_lines(qq[</div><!-- $class -->]);
}

sub before_generate_doc {
    my ($self) = @_;
    $self->SUPER::before_generate_doc;
    $self->start_div("doc");
}

sub after_generate_doc {
    my ($self) = @_;
    $self->end_div("doc");
    $self->SUPER::after_generate_doc;
}

sub doc_gen_summary {
    my ($self) = @_;

    $self->start_div("name");
    $self->add_doc_lines(
        $self->h(0, __("Name")),
        $self->doc_parse->{name},
    );
    $self->end_div("name");
    $self->add_doc_lines("");

    return unless $self->doc_parse->{summary};

    $self->start_div("summary");
    $self->add_doc_lines(
        $self->h(0, uc(__("Summary"))),
        $self->doc_parse->{summary},
    );
    $self->add_doc_lines("");
}

sub doc_gen_version {
    my ($self) = @_;

    $self->start_div("version");
    $self->add_doc_lines(
        $self->{_meta}{entity_v},
    );
    $self->end_div("version");
    $self->add_doc_lines("");
}

sub doc_gen_description {
    my ($self) = @_;

    return unless $self->doc_parse->{description};

    $self->start_div("description");
    $self->add_doc_lines(
        $self->h(0, uc(__("Description"))),
        $self->_m2h($self->doc_parse->{description}),
    );
    $self->start_div("description");
    $self->add_doc_lines("");
}

sub _fdoc_gen {
    my ($self, $url) = @_;
    my $p = $self->doc_parse->{functions}{$url};

    my $has_args = !!keys(%{$p->{args}});

    $self->start_div("fdoc");

    $self->start_div("name");
    $self->add_doc_lines(
        $self->h(1, __("Name")),
        $p->{name},
    );
    $self->end_div("name");

    if ($p->{summary}) {
        $self->start_div("summary");
        $self->add_doc_lines(
            $self->h(1, __("Summary")),
            $p->{summary} . ($p->{summary} =~ /\.$/ ? "":"."),
        );
        $self->end_div("summary");
    }

    if ($p->{description}) {
        $self->start_div("description");
        $self->add_doc_lines(
            $self->h(1, __("Description")),
            $p->{description},
        );
        $self->end_div("description");
    }

    $self->start_div("parameters");
    $self->add_doc_lines(
        $self->h(1, __("Parameters")),
        "<ul>",
    );
    for my $name (sort keys %{$p->{args}}) {
        my $pa = $p->{args}{$name};
        my $req = $pa->{schema}[1]{req};

        $self->add_doc_lines(join(
            "",
            qq[<li><span class="name${\($req ? ' req' : '')}">$name</span> ],
            $pa->{human_arg},
            (defined($pa->{human_arg_default}) ?
                 " (" . __("default") .
                     ": $pa->{human_arg_default})" : "")
        ), "");
        if ($pa->{summary}) {
            $self->start_div("summary");
            $self->add_doc_lines(
                $pa->{summary} . ($p->{summary} =~ /\.$/ ? "" : "."),
                "") if $pa->{summary};
            $self->end_div("summary");
        }
        if ($pa->{description}) {
            $self->start_div("description");
            $self->add_doc_lines(
                $self->_m2h($pa->{description})
            );
            $self->end_div("description");
        }
    }
    $self->add_doc_lines("</ul>");
    $self->end_div("parameters");

    # XXX result summary

    # XXX result description

    $self->end_div("fdoc");
    $self->add_doc_lines("");
}

sub doc_gen_functions {
    my ($self) = @_;
    my $pff = $self->doc_parse->{functions};

    $self->start_div("functions");

    # XXX categorize functions based on tags
    for my $url (sort keys %$pff) {
        my $p = $pff->{$url};
        $self->_fdoc_gen($url);
    }

    $self->end_div("functions");
}

1;
# ABSTRACT: Generate HTML documentation from Rinci package metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::To::HTML - Generate HTML documentation from Rinci package metadata

=head1 VERSION

This document describes version 0.04 of Perinci::To::HTML (from Perl distribution Perinci-To-HTML), released on 2015-09-04.

=head1 DESCRIPTION

This documentation is geared more into documenting HTTP API. If you want
something more Perl-oriented, try L<Perinci::To::POD> (and convert the resulting
POD to HTML).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-To-HTML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
