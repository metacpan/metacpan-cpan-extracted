package Perinci::To::POD;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-24'; # DATE
our $DIST = 'Perinci-To-Doc'; # DIST
our $VERSION = '0.877'; # VERSION

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::To::PackageBase';

sub BUILD {
    my ($self, $args) = @_;
}

sub _podquote {
    require String::PodQuote;
    String::PodQuote::pod_quote($_[0]);
}

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub gen_doc_section_summary {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_summary;

    my $name_summary = join(
        "",
        $dres->{name} // "",
        ($dres->{name} && $dres->{summary} ? ' - ' : ''),
        $dres->{summary} // ""
    );

    $self->add_doc_lines(
        "=head1 " . uc(__("Name")),
        "",
        $self->_podquote($name_summary),
        "",
    );
}

sub gen_doc_section_version {
    my ($self) = @_;

    my $meta = $self->meta;

    $self->add_doc_lines(
        "=head1 " . uc(__("Version")),
        "",
        $meta->{entity_v} // '?',
        "",
    );
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Description")),
        ""
    );

    $self->SUPER::gen_doc_section_description;

    if ($dres->{description}) {
        $self->add_doc_lines(
            $self->_md2pod($dres->{description}),
            "",
        );
    }

    #$self->add_doc_lines(
    #    __("This module has L<Rinci> metadata") . ".",
    #    "",
    #);
}

sub _gen_func_doc {
    my $self = shift;
    my %args = @_;

    my $o = Perinci::Sub::To::POD->new(
        _pa => $self->{_pa},
        export => $self->{exports} ? $self->{exports}{$args{name}} : undef,
        %args,
    );
    $o->gen_doc;
    $o->doc_lines;
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::POD;

    my ($self) = @_;
    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Functions")),
    );

    $self->SUPER::gen_doc_section_functions;

    # XXX categorize functions based on tags?
    my $i;
    for my $furi (sort keys %{ $dres->{functions} }) {
        $self->add_doc_lines('') if $i++;
        my $meta = $dres->{function_metas}{$furi};
        next if ($meta->{is_meth} || $meta->{is_class_meth}) && !($meta->{is_func} // 1);
        $self->add_doc_lines("");
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines($_);
        }
    }
    $self->add_doc_lines('');
}

sub gen_doc_section_methods {
    require Perinci::Sub::To::POD;

    my ($self) = @_;
    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Methods")),
    );

    $self->SUPER::gen_doc_section_methods;

    # XXX categorize methods based on tags?
    my $i;
    for my $furi (sort keys %{ $dres->{functions} }) {
        $self->add_doc_lines('') if $i++;
        my $meta = $dres->{function_metas}{$furi};
        next unless ($meta->{is_meth} || $meta->{is_class_meth}) && !($meta->{is_func} // 1);
        $self->add_doc_lines("");
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines($_);
        }
    }
    $self->add_doc_lines('');
}

sub gen_doc_section_links {
    my $self = shift;

    my %seen_urls;
    my $meta = $self->meta;
    my $child_metas = $self->child_metas;

    my @links;
    push @links, @{ $meta->{links} } if $meta->{links};
    for my $m (values %$child_metas) {
        for my $link (@{ $m->{links} || [] }) {
            # skip function that links to a prog: URL; this is probably not
            # relevant for module doc
            next if $link->{url} =~ /\Aprog:/;

            push @links, $link;
        }
    }

    if (@links) {
        $self->add_doc_lines("=head1 " . __("SEE ALSO"), "");
        for my $link0 (@links) {
            my $link = ref($link0) ? $link0 : {url=>$link0};
            my $url = $link->{url};
            next if $seen_urls{$url}++;
            $url =~ s!\A(pm|pod|prog):(//?)?!!;
            $self->add_doc_lines(
                "L<$url>." .
                    (defined $link->{summary} ? " ".$self->_podquote($link->{summary})."." : "") .
                    (defined $link->{description} ? " " . $self->_md2pod($link->{description}) : ""),
                "");
        }
    }
}

1;
# ABSTRACT: Generate POD documentation for a package from Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::To::POD - Generate POD documentation for a package from Rinci metadata

=head1 VERSION

This document describes version 0.877 of Perinci::To::POD (from Perl distribution Perinci-To-Doc), released on 2021-05-24.

=head1 SYNOPSIS

You can use the included L<peri-doc> script, or:

 use Perinci::To::POD;
 my $doc = Perinci::To::POD->new(
     name=>"Foo::Bar", meta => {...}, child_metas => {...});
 say $doc->gen_doc;

To generate documentation for a single function, see L<Perinci::Sub::To::POD>.

To generate a usage-like help message for a single function, you can try the
L<peri-func-usage> from the L<Perinci::CmdLine::Classic> distribution.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-To-Doc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-To-Doc/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
