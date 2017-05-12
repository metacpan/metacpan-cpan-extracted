package Org::To::HTML::WordPress;

our $DATE = '2016-12-24'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moo;
extends 'Org::To::HTML';

use Exporter qw(import);
our @EXPORT_OK = qw(org_to_html_wordpress);

our %SPEC;

$SPEC{org_to_html_wordpress} = $Org::To::HTML::SPEC{org_to_html};
sub org_to_html_wordpress {
    Org::To::HTML::org_to_html(@_, _class => __PACKAGE__);
}

sub export_block {
    my $self = shift;
    my ($elem) = @_;

    if ($elem->name eq 'SRC') {
        join "", (
            "[sourcecode language=\"".($elem->args->[0] || "none")."\"]\n",
            $elem->raw_content,
            "[/sourcecode]\n",
        );
    } else {
        $self->SUPER::export_block(@_);
    }
}

1;
# ABSTRACT: Export Org document to HTML (WordPress variant)

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::HTML::WordPress - Export Org document to HTML (WordPress variant)

=head1 VERSION

This document describes version 0.002 of Org::To::HTML::WordPress (from Perl distribution Org-To-HTML-WordPress), released on 2016-12-24.

=head1 SYNOPSIS

 use Org::To::HTML::WordPress qw(org_to_html_wordpress);

 # use like you would use Org::To::HTML's org_to_html()

=head1 DESCRIPTION

This is a subclass of L<Org::To::HTML> that produces WordPress-variant of HTML.
Currently the differences are:

=over

=item * SRC Block

Instead of:

 <PRE CLASS="block block_src"> ... </PRE>

will instead use:

 [sourcecode language="..."]
 ...
 [/sourcecode]

=back

=head1 FUNCTIONS


=head2 org_to_html_wordpress(%args) -> [status, msg, result, meta]

Export Org document to HTML.

This is the non-OO interface. For more customization, consider subclassing
Org::To::HTML.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<css_url> => I<str>

Add a link to CSS document.

=item * B<exclude_tags> => I<array[str]>

Exclude trees that carry one of these tags.

If the whole document doesn't have any of these tags, then the whole document
will be exported. Otherwise, trees that do not carry one of these tags will be
excluded. If a selected tree is a subtree, the heading hierarchy above it will
also be selected for export, but not the text below those headings.

exclude_tags is evaluated after include_tags.

=item * B<html_title> => I<str>

HTML document title, defaults to source_file.

=item * B<ignore_unknown_settings> => I<bool>

=item * B<include_tags> => I<array[str]>

Include trees that carry one of these tags.

Works like Org's 'org-export-select-tags' variable. If the whole document
doesn't have any of these tags, then the whole document will be exported.
Otherwise, trees that do not carry one of these tags will be excluded. If a
selected tree is a subtree, the heading hierarchy above it will also be selected
for export, but not the text below those headings.

=item * B<naked> => I<bool>

Don't wrap exported HTML with HTML/HEAD/BODY elements.

=item * B<source_file> => I<str>

Source Org file to export.

=item * B<source_str> => I<str>

Alternatively you can specify Org string directly.

=item * B<target_file> => I<str>

HTML file to write to.

If not specified, HTML string will be returned.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(export_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-HTML-WordPress>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-HTML-WordPress>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-HTML-WordPress>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Org::To::HTML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
