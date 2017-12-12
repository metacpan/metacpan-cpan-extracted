package Perinci::To::Text;

our $DATE = '2017-12-09'; # DATE
our $VERSION = '0.862'; # VERSION

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::To::PackageBase';
with    'Perinci::To::Doc::Role::Section::AddTextLines';

sub BUILD {
    my ($self, $args) = @_;
}

sub gen_doc_section_summary {
    my ($self) = @_;

    #my $meta = $self->meta;
    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_summary;

    my $name_summary = join(
        "",
        $dres->{name} // "",
        ($dres->{name} && $dres->{summary} ? ' - ' : ''),
        $dres->{summary} // ""
    );

    $self->add_doc_lines(uc(__("Name")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($name_summary);
    $self->dec_doc_indent;
}

sub gen_doc_section_version {
    my ($self) = @_;

    my $meta = $self->meta;
    #my $dres = $self->{_doc_res};

    $self->add_doc_lines("", uc(__("Version")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($meta->{entity_v} // '?');
    $self->dec_doc_indent;
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_description;
    return unless $dres->{description};

    $self->add_doc_lines("", uc(__("Description")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($dres->{description});
    $self->dec_doc_indent;
}

sub _gen_func_doc {
    my $self = shift;
    my $o = Perinci::Sub::To::Text->new(_pa=>$self->{_pa}, @_);
    $o->gen_doc;
    $o->doc_lines;
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::Text;

    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->add_doc_lines("", uc(__("Functions")), "");
    $self->SUPER::gen_doc_section_functions;
    for my $furi (sort keys %{ $dres->{functions} }) {
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines({wrap=>0}, $_);
        }
        $self->add_doc_lines('');
    }
}

1;
# ABSTRACT: Generate text documentation for a package from Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::To::Text - Generate text documentation for a package from Rinci metadata

=head1 VERSION

This document describes version 0.862 of Perinci::To::Text (from Perl distribution Perinci-To-Doc), released on 2017-12-09.

=head1 SYNOPSIS

 use Perinci::To::POD;
 my $doc = Perinci::To::Text->new(
     name=>'Foo::Bar', meta => {...}, child_metas=>{...});
 say $doc->gen_doc;

You can also try the L<peri-doc> script with the C<--format text> option:

 % peri-doc --format text /Some/Module/

To generate a usage-like help message for a single function, you can try the
L<peri-func-usage> from the L<Perinci::CmdLine::Classic> distribution.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-To-Doc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-Doc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
