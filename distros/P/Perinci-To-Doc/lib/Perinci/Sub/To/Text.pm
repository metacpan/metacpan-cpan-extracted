package Perinci::Sub::To::Text;

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::Sub::To::FuncBase';
with    'Perinci::To::Doc::Role::Section::AddTextLines';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-14'; # DATE
our $DIST = 'Perinci-To-Doc'; # DIST
our $VERSION = '0.879'; # VERSION

sub BUILD {
    my ($self, $args) = @_;
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    my ($self) = @_;

    my $meta  = $self->meta;
    my $dres  = $self->{_doc_res};

    my $orig_result_naked = $meta->{_orig_result_naked} // $meta->{result_naked};

    $self->add_doc_lines(
        "+ ".$dres->{name}.$dres->{args_plterm}.' -> '.$dres->{human_ret},
    );
    $self->inc_doc_indent;

    $self->add_doc_lines("", $dres->{summary})     if $dres->{summary};
    $self->add_doc_lines("", $dres->{description}) if $dres->{description};
    if (keys %{$dres->{args}}) {
        use experimental 'smartmatch';
        $self->add_doc_lines(
            "",
            __("Arguments") .
                ' (' . __("'*' denotes required arguments") . '):',
            "");
        my $i = 0;
        my $arg_has_ct;
        for my $name (sort keys %{$dres->{args}}) {
            my $prev_arg_has_ct = $arg_has_ct;
            $arg_has_ct = 0;
            my $ra = $dres->{args}{$name};
            next if 'hidden' ~~ @{ $ra->{arg}{tags} // [] };
            $self->add_doc_lines("") if $i++ > 0 && $prev_arg_has_ct;
            $self->add_doc_lines(join(
                "",
                "- ", $name, ($ra->{arg}{req} ? '*' : ''), ' => ',
                $ra->{human_arg},
                (defined($ra->{human_arg_default}) ?
                     " (" . __("default") .
                         ": $ra->{human_arg_default})" : "")
            ));
            if ($ra->{summary} || $ra->{description}) {
                $arg_has_ct++;
                $self->inc_doc_indent(2);
                $self->add_doc_lines($ra->{summary}.".") if $ra->{summary};
                if ($ra->{description}) {
                    $self->add_doc_lines("", $ra->{description});
                }
                $self->dec_doc_indent(2);
            }
        }
    }

    if ($meta->{dies_on_error}) {
        $self->add_doc_lines("", __("This function dies on error."), "");
    }

    $self->add_doc_lines("", __("Return value") . ':');
    $self->inc_doc_indent;
    $self->add_doc_lines(__(
'Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.'))
        unless $orig_result_naked;
    $self->add_doc_lines($dres->{res_summary} . ($dres->{res_schema} ? " ($dres->{res_schema}[0])" : "")) if $dres->{res_summary};

    $self->dec_doc_indent;

    $self->dec_doc_indent;
}

1;
# ABSTRACT: Generate text documentation from Rinci function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::To::Text - Generate text documentation from Rinci function metadata

=head1 VERSION

This document describes version 0.879 of Perinci::Sub::To::Text (from Perl distribution Perinci-To-Doc), released on 2022-05-14.

=head1 SYNOPSIS

 use Perinci::Sub::To::Text;

 my $doc = Perinci::Sub::To::Text->new(meta => {...});
 say $doc->gen_doc;

You can also try the L<peri-doc> script with the C<--format text> option:

 % peri-doc --format text /Some/Module/somefunc

To generate a usage-like help message for a function, you can try
L<peri-func-usage> which is included in the L<Perinci::CmdLine::Classic>
distribution.

 % peri-func-usage http://example.com/api/somefunc

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-To-Doc>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-Doc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
