package TableData::Lingua::Word::EN::ByClass::Adjective::TalkEnglish;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-13'; # DATE
our $DIST = 'TableDataBundle-Lingua-Word-EN-ByClass-Adjective'; # DIST
our $VERSION = '0.004'; # VERSION

our %STATS = ("num_rows",143,"num_columns",2); # STATS

1;
# ABSTRACT: List of words that are used as adjectives only, from talkenglish.com

=pod

=encoding UTF-8

=head1 NAME

TableData::Lingua::Word::EN::ByClass::Adjective::TalkEnglish - List of words that are used as adjectives only, from talkenglish.com

=head1 VERSION

This document describes version 0.004 of TableData::Lingua::Word::EN::ByClass::Adjective::TalkEnglish (from Perl distribution TableDataBundle-Lingua-Word-EN-ByClass-Adjective), released on 2025-01-13.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Lingua::Word::EN::ByClass::Adjective::TalkEnglish;

 my $td = TableData::Lingua::Word::EN::ByClass::Adjective::TalkEnglish->new;

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
 % tabledata Lingua::Word::EN::ByClass::Adjective::TalkEnglish --page

 # Get number of rows
 % tabledata --action count_rows Lingua::Word::EN::ByClass::Adjective::TalkEnglish

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 2     |
 | num_rows    | 143   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Lingua-Word-EN-ByClass-Adjective>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Lingua-Word-EN-ByClass-Adjective>.

=head1 SEE ALSO

L<https://www.talkenglish.com/vocabulary/top-500-adjectives.aspx>

L<TableData::Lingua::Word::EN::ByClass::Noun::TalkEnglish>,
L<TableData::Lingua::Word::EN::ByClass::Adverb::TalkEnglish>

Other C<TableData::Lingua::Word::EN::ByClass::Adjective::*> modules.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Lingua-Word-EN-ByClass-Adjective>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
word,frequency
different,215
used,204
important,160
every,95
large,95
available,94
popular,81
able,74
basic,61
known,60
various,59
difficult,58
several,55
united,55
historical,52
hot,50
useful,49
mental,47
scared,45
additional,41
emotional,35
old,34
political,34
similar,32
healthy,30
financial,29
medical,29
traditional,29
federal,28
entire,27
strong,27
actual,26
significant,24
successful,24
electrical,23
expensive,23
pregnant,23
intelligent,20
interesting,20
poor,20
happy,19
responsible,19
cute,18
helpful,18
recent,18
willing,18
nice,17
wonderful,17
impossible,16
serious,16
huge,15
rare,15
technical,15
typical,15
competitive,14
critical,14
electronic,14
immediate,14
aware,13
educational,13
environmental,13
global,13
legal,13
relevant,13
accurate,12
capable,12
dangerous,12
dramatic,11
efficient,11
powerful,11
foreign,10
hungry,10
practical,10
psychological,10
severe,10
suitable,10
numerous,9
sufficient,9
unusual,9
consistent,8
cultural,8
existing,8
famous,8
pure,8
afraid,7
obvious,7
careful,6
latter,6
unhappy,6
acceptable,5
aggressive,5
boring,5
distinct,5
eastern,5
logical,5
reasonable,5
strict,5
administrative,4
automatic,4
civil,4
former,4
massive,4
southern,4
unfair,4
visible,4
alive,3
angry,3
desperate,3
exciting,3
friendly,3
lucky,3
realistic,3
sorry,3
ugly,3
unlikely,3
anxious,2
comprehensive,2
curious,2
impressive,2
informal,2
inner,2
pleasant,2
sexual,2
sudden,2
terrible,2
unable,2
weak,2
wooden,2
asleep,1
confident,1
conscious,1
decent,1
embarrassed,1
guilty,1
lonely,1
mad,1
nervous,1
odd,1
remarkable,1
substantial,1
suspicious,1
tall,1
tiny,1
