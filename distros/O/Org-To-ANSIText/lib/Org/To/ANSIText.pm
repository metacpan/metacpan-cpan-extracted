package Org::To::ANSIText;

use 5.010001;
use strict;
use vars qw($VERSION);
use warnings;
use Log::ger;

use Exporter 'import';
use File::Slurper qw(read_text write_text);
use Org::Document;

use Moo;
with 'Org::To::Role';
extends 'Org::To::Base';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-11'; # DATE
our $DIST = 'Org-To-ANSIText'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(org_to_ansi_text);

our %SPEC;
$SPEC{org_to_ansi_text} = {
    v => 1.1,
    summary => 'Export Org document to text with ANSI color codes',
    description => <<'_',

This is the non-OO interface. For more customization, consider subclassing
Org::To::ANSIText.

_
    args => {
        source_file => {
            summary => 'Source Org file to export',
            schema => ['str' => {}],
        },
        source_str => {
            summary => 'Alternatively you can specify Org string directly',
            schema => ['str' => {}],
        },
        target_file => {
            summary => 'Text file to write to',
            schema => ['str' => {}],
            description => <<'_',

If not specified, text string will be returned.

_
        },
        include_tags => {
            summary => 'Include trees that carry one of these tags',
            schema => ['array' => {of => 'str*'}],
            description => <<'_',

Works like Org's 'org-export-select-tags' variable. If the whole document
doesn't have any of these tags, then the whole document will be exported.
Otherwise, trees that do not carry one of these tags will be excluded. If a
selected tree is a subtree, the heading hierarchy above it will also be selected
for export, but not the text below those headings.

_
        },
        exclude_tags => {
            summary => 'Exclude trees that carry one of these tags',
            schema => ['array' => {of => 'str*'}],
            description => <<'_',

If the whole document doesn't have any of these tags, then the whole document
will be exported. Otherwise, trees that do not carry one of these tags will be
excluded. If a selected tree is a subtree, the heading hierarchy above it will
also be selected for export, but not the text below those headings.

exclude_tags is evaluated after include_tags.

_
        },
        ignore_unknown_settings => {
            schema => 'bool',
        },
    },
};
sub org_to_ansi_text {
    my %args = @_;

    my $doc;
    if ($args{source_file}) {
        $doc = Org::Document->new(
            from_string => scalar read_text($args{source_file}),
            ignore_unknown_settings => $args{ignore_unknown_settings},
        );
    } elsif (defined($args{source_str})) {
        $doc = Org::Document->new(
            from_string => $args{source_str},
            ignore_unknown_settings => $args{ignore_unknown_settings},
        );
    } else {
        return [400, "Please specify source_file/source_str"];
    }

    my $obj = ($args{_class} // __PACKAGE__)->new(
        source_file   => $args{source_file} // '(source string)',
        include_tags  => $args{include_tags},
        exclude_tags  => $args{exclude_tags},
    );

    my $text = $obj->export($doc);
    #$log->tracef("text = %s", $text);
    if ($args{target_file}) {
        write_text($args{target_file}, $text);
        return [200, "OK"];
    } else {
        return [200, "OK", $text];
    }
}

sub export_document {
    my ($self, $doc) = @_;

    my $text = [];
    push @$text, $self->export_elements(@{$doc->children});
    join "", @$text;
}

sub export_block {
    my ($self, $elem) = @_;
    $elem->raw_content;
}

sub export_fixed_width_section {
    my ($self, $elem) = @_;
    $elem->text;
}

sub export_comment {
    my ($self, $elem) = @_;
    "";
}

sub export_drawer {
    my ($self, $elem) = @_;
    # currently not exported
    '';
}

sub export_footnote {
    my ($self, $elem) = @_;
    # currently not exported
    '';
}

sub export_headline {
    my ($self, $elem) = @_;

    my @children = $self->_included_children($elem);

    join("",
         ("*" x $elem->level), " ", $self->export_elements($elem->title), "\n",
         $self->export_elements(@children),
     );
}

sub export_list {
    my ($self, $elem) = @_;

    join("",
         $self->export_elements(@{$elem->children // []}),
     );
}

sub export_list_item {
    my ($self, $elem) = @_;

    my $text = [];

    push @$text, $elem->bullet, " ";

    if ($elem->check_state) {
        push @$text, "\e[1m[", $elem->check_state, "]\e[22m";
    }

    if ($elem->desc_term) {
         push @$text, "\e[1m[", $elem->desc_term, "]\e[22m", " :: ";
    }

    push @$text, $self->export_elements(@{$elem->children}) if $elem->children;

    join "", @$text;
}

sub export_radio_target {
    my ($self, $elem) = @_;
    # currently not exported
    '';
}

sub export_setting {
    my ($self, $elem) = @_;
    # currently not exported
    '';
}

sub export_table {
    my ($self, $elem) = @_;
    $self->export_elements(@{$elem->children // []}),
}

sub export_table_row {
    my ($self, $elem) = @_;
    join "", (
        "|",
        $self->export_elements(@{$elem->children // []}),
        "|\n",
    );
}

sub export_table_cell {
    my ($self, $elem) = @_;

    join "", (
        $self->export_elements(@{$elem->children // []}),
    );
}

sub export_table_vline {
    my ($self, $elem) = @_;
    # currently not exported
    '';
}

sub export_target {
    my ($self, $elem) = @_;
    '';
}

sub export_text {
    my ($self, $elem) = @_;

    my $style = $elem->style;
    my $begin_code = '';
    my $end_code   = '';
    if    ($style eq 'B') { $begin_code = "\e[1m"; $end_code   = "\e[22m" }
    elsif ($style eq 'I') { $begin_code = "\e[3m"; $end_code   = "\e[23m" }
    elsif ($style eq 'U') { $begin_code = "\e[4m"; $end_code   = "\e[24m" }
    elsif ($style eq 'S') { $begin_code = "\e[2m"; $end_code   = "\e[22m" } # strike is rendered as faint
    elsif ($style eq 'C') { }
    elsif ($style eq 'V') { }

    my $text = [];

    push @$text, $begin_code if $begin_code;
    push @$text, $elem->text;
    push @$text, $self->export_elements(@{$elem->children}) if $elem->children;
    push @$text, $end_code   if $end_code;

    join "", @$text;
}

sub export_time_range {
    my ($self, $elem) = @_;

    $elem->as_string;
}

sub export_timestamp {
    my ($self, $elem) = @_;

    $elem->as_string;
}

sub export_link {
    my ($self, $elem) = @_;

    my $text = [];
    my $link = $elem->link;

    push @$text, "[LINK:$link";
    if ($elem->description) {
        push @$text, " ", $self->export_elements($elem->description);
    }
    push @$text, "]";

    join "", @$text;
}

1;
# ABSTRACT: Export Org document to text with ANSI color codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::ANSIText - Export Org document to text with ANSI color codes

=head1 VERSION

This document describes version 0.001 of Org::To::ANSIText (from Perl distribution Org-To-ANSIText), released on 2022-10-11.

=head1 SYNOPSIS

 use Org::To::ANSIText qw(org_to_ansi_text);

 # non-OO interface
 my $res = org_to_ansi_text(
     source_file   => 'todo.org', # or source_str
     #target_file  => 'todo.txt', # default is to return the text in $res->[2]
     #include_tags => [...], # default exports all tags.
     #exclude_tags => [...], # behavior mimics emacs's include/exclude rule
 );
 die "Failed" unless $res->[0] == 200;

 # OO interface
 my $oea = Org::To::ANSIText->new();
 my $text = $oea->export($doc); # $doc is Org::Document object

=head1 DESCRIPTION

Export Org format to ANSI text (text with ANSI escape codes). To customize, you
can subclass this module.

A command-line utility L<org-to-ansi-text> is available in the distribution
L<App::OrgUtils>.

=head1 new(%args)

=head2 $exp->export_document($doc) => text

Export document to text.

=head1 FUNCTIONS


=head2 org_to_ansi_text

Usage:

 org_to_ansi_text(%args) -> [$status_code, $reason, $payload, \%result_meta]

Export Org document to text with ANSI color codes.

This is the non-OO interface. For more customization, consider subclassing
Org::To::ANSIText.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_tags> => I<array[str]>

Exclude trees that carry one of these tags.

If the whole document doesn't have any of these tags, then the whole document
will be exported. Otherwise, trees that do not carry one of these tags will be
excluded. If a selected tree is a subtree, the heading hierarchy above it will
also be selected for export, but not the text below those headings.

exclude_tags is evaluated after include_tags.

=item * B<ignore_unknown_settings> => I<bool>

=item * B<include_tags> => I<array[str]>

Include trees that carry one of these tags.

Works like Org's 'org-export-select-tags' variable. If the whole document
doesn't have any of these tags, then the whole document will be exported.
Otherwise, trees that do not carry one of these tags will be excluded. If a
selected tree is a subtree, the heading hierarchy above it will also be selected
for export, but not the text below those headings.

=item * B<source_file> => I<str>

Source Org file to export.

=item * B<source_str> => I<str>

Alternatively you can specify Org string directly.

=item * B<target_file> => I<str>

Text file to write to.

If not specified, text string will be returned.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(export_.+|before_.+|after_.+)$

=head1 ATTRIBUTES

=head1 METHODS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-ANSIText>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-ANSIText>.

=head1 SEE ALSO

L<Org::Parser>

L<org-to-ansi-text>

Other Org exporters: L<Org::To::Text>, L<Org::To::HTML>, L<Org::To::VCF>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-ANSIText>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
