package TableData::Lingua::Word::EN::Adverb::TalkEnglish;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-07'; # DATE
our $DIST = 'TableDataBundle-Lingua-Word-EN-Adverb'; # DIST
our $VERSION = '0.003'; # VERSION

our %STATS = ("num_columns",2,"num_rows",114); # STATS

1;
# ABSTRACT: List of words that are used as adverbs only, from talkenglish.com

=pod

=encoding UTF-8

=head1 NAME

TableData::Lingua::Word::EN::Adverb::TalkEnglish - List of words that are used as adverbs only, from talkenglish.com

=head1 VERSION

This document describes version 0.003 of TableData::Lingua::Word::EN::Adverb::TalkEnglish (from Perl distribution TableDataBundle-Lingua-Word-EN-Adverb), released on 2023-02-07.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Lingua::Word::EN::Adverb::TalkEnglish;

 my $td = TableData::Lingua::Word::EN::Adverb::TalkEnglish->new;

 # Iterate rows of the table
 $td->each_row_arrayref(sub { my $row = shift; ... });
 $td->each_row_hashref (sub { my $row = shift; ... });

 # Get the list of column names
 my @columns = $td->get_column_names;

 # Get the number of rows
 my $row_count = $td->get_row_count;

See also L<TableDataRole::Spec::Basic> for other methods.

To use from command-line (using L<tabledata> CLI):

 # Display as ASCII table and view with pager
 % tabledata Lingua::Word::EN::Adverb::TalkEnglish --page

 # Get number of rows
 % tabledata --action count_rows Lingua::Word::EN::Adverb::TalkEnglish

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 2     |
 | num_rows    | 114   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Lingua-Word-EN-Adverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Lingua-Word-EN-Adverb>.

=head1 SEE ALSO

L<https://www.talkenglish.com/vocabulary/top-250-adverbs.aspx>

L<TableData::Lingua::Word::EN::Noun::TalkEnglish>,
L<TableData::Lingua::Word::EN::Adjective::TalkEnglish>

Other C<TableData::Lingua::Word::EN::Adverb::*> modules.

L<TableData>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Lingua-Word-EN-Adverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
word,frequency
not,658
also,419
very,191
often,187
however,128
too,114
usually,101
really,79
early,77
never,76
always,69
sometimes,67
together,63
likely,57
simply,54
generally,52
instead,50
actually,46
again,44
rather,42
almost,41
especially,41
ever,39
quickly,39
probably,38
already,36
below,36
directly,34
therefore,34
else,30
thus,28
easily,26
eventually,26
exactly,26
certainly,22
normally,22
currently,19
extremely,18
finally,18
constantly,17
properly,17
soon,17
specifically,17
ahead,16
daily,16
highly,16
immediately,16
relatively,16
slowly,16
fairly,15
primarily,15
completely,14
ultimately,14
widely,14
recently,13
seriously,13
frequently,12
fully,12
mostly,12
naturally,12
nearly,12
occasionally,12
carefully,11
clearly,11
essentially,11
possibly,11
slightly,11
somewhat,11
equally,10
greatly,10
necessarily,10
personally,10
rarely,10
regularly,10
similarly,10
basically,9
closely,9
effectively,9
initially,9
literally,9
mainly,9
merely,9
gently,8
hopefully,8
originally,8
roughly,8
significantly,8
totally,7
twice,7
elsewhere,6
everywhere,6
obviously,6
perfectly,6
physically,6
successfully,5
suddenly,5
truly,5
virtually,5
altogether,4
anyway,4
automatically,4
deeply,4
definitely,4
deliberately,4
hardly,4
readily,4
terribly,4
unfortunately,4
forth,3
briefly,2
moreover,2
strongly,2
honestly,1
previously,1
