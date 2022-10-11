package Org::To::Text;

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
our $DIST = 'Org-To-Text'; # DIST
our $VERSION = '0.050'; # VERSION

our @EXPORT_OK = qw(org_to_text);

our %SPEC;
$SPEC{org_to_text} = {
    v => 1.1,
    summary => 'Export Org document to text',
    description => <<'_',

This is the non-OO interface. For more customization, consider subclassing
Org::To::Text.

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
sub org_to_text {
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

    # XXX show settings, title

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
        push @$text, "[", $elem->check_state, "]";
    }

    if ($elem->desc_term) {
         push @$text, $elem->desc_term, " :: ";
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
    if    ($style eq 'B') { $begin_code = "*"; $end_code   = "*" }
    elsif ($style eq 'I') { $begin_code = "/"; $end_code   = "/" }
    elsif ($style eq 'U') { $begin_code = "_"; $end_code   = "_" }
    elsif ($style eq 'S') { $begin_code = "+"; $end_code   = "+" }
    elsif ($style eq 'C') { $begin_code = "~"; $end_code   = "~" }
    elsif ($style eq 'V') { $begin_code = "="; $end_code   = "=" }

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
# ABSTRACT: Export Org document to text

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::Text - Export Org document to text

=head1 VERSION

This document describes version 0.050 of Org::To::Text (from Perl distribution Org-To-Text), released on 2022-10-11.

=head1 SYNOPSIS

 use Org::To::Text qw(org_to_text);

 # non-OO interface
 my $res = org_to_text(
     source_file   => 'todo.org', # or source_str
     #target_file  => 'todo.txt', # default is to return the text in $res->[2]
     #include_tags => [...], # default exports all tags.
     #exclude_tags => [...], # behavior mimics emacs's include/exclude rule
 );
 die "Failed" unless $res->[0] == 200;

 # OO interface
 my $oea = Org::To::Text->new();
 my $text = $oea->export($doc); # $doc is Org::Document object

=head1 DESCRIPTION

Export Org format to plain text, which means mostly things will be formatted
as-is. To customize, you can subclass this module.

A command-line utility L<org-to-ansi-text> is available in the distribution
L<App::OrgUtils>.

=head1 new(%args)

=head2 $exp->export_document($doc) => text

Export document to text.

=head1 FUNCTIONS


=head2 org_to_text

Usage:

 org_to_text() -> [$status_code, $reason, $payload, \%result_meta]

Export Org document to text.

This function is not exported by default, but exportable.

No arguments.

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

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-Text>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-Text>.

=head1 SEE ALSO

L<Org::Parser>

L<org-to-text>

Other Org exporters: L<Org::To::ANSIText>, L<Org::To::HTML>, L<Org::To::VCF>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2022, 2017, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-Text>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
