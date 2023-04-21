package TableData::Lingua::Word::EN::Noun::TalkEnglish;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-07'; # DATE
our $DIST = 'TableDataBundle-Lingua-Word-EN-Noun'; # DIST
our $VERSION = '0.003'; # VERSION

our %STATS = ("num_rows",484,"num_columns",2); # STATS

1;
# ABSTRACT: List of words that are used as nouns only, from talkenglish.com

=pod

=encoding UTF-8

=head1 NAME

TableData::Lingua::Word::EN::Noun::TalkEnglish - List of words that are used as nouns only, from talkenglish.com

=head1 VERSION

This document describes version 0.003 of TableData::Lingua::Word::EN::Noun::TalkEnglish (from Perl distribution TableDataBundle-Lingua-Word-EN-Noun), released on 2023-02-07.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Lingua::Word::EN::Noun::TalkEnglish;

 my $td = TableData::Lingua::Word::EN::Noun::TalkEnglish->new;

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
 % tabledata Lingua::Word::EN::Noun::TalkEnglish --page

 # Get number of rows
 % tabledata --action count_rows Lingua::Word::EN::Noun::TalkEnglish

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 2     |
 | num_rows    | 484   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Lingua-Word-EN-Noun>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Lingua-Word-EN-Noun>.

=head1 SEE ALSO

L<https://www.talkenglish.com/vocabulary/top-1500-nouns.aspx>

L<TableData::Lingua::Word::EN::Adverb::TalkEnglish>,
L<TableData::Lingua::Word::EN::Adjective::TalkEnglish>

Other C<TableData::Lingua::Word::EN::Noun::*> modules.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Lingua-Word-EN-Noun>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
word,frequency
people,372
history,187
way,185
art,183
world,169
information,168
map,167
two,164
family,159
government,143
health,122
system,111
computer,109
meat,99
year,96
thanks,84
music,80
person,80
reading,77
method,76
data,74
food,73
understanding,73
theory,71
law,70
bird,68
literature,67
problem,66
software,63
control,62
knowledge,62
power,62
ability,61
economics,61
love,60
internet,59
television,59
science,58
library,57
nature,57
fact,56
product,56
idea,55
temperature,55
investment,52
area,50
society,50
activity,48
story,48
industry,47
media,47
thing,47
oven,45
community,44
definition,44
safety,44
quality,43
development,42
language,42
management,41
player,41
variety,41
video,41
week,41
security,38
country,37
exam,37
movie,37
organization,37
equipment,35
physics,35
analysis,34
policy,34
series,34
thought,34
basis,33
boyfriend,33
direction,33
strategy,33
technology,33
army,32
camera,32
freedom,32
paper,32
environment,31
child,30
instance,30
month,30
truth,30
marketing,29
university,29
writing,29
article,28
department,28
difference,28
goal,28
news,28
audience,27
fishing,27
growth,27
income,27
marriage,27
user,27
combination,26
failure,26
meaning,26
medicine,26
philosophy,26
teacher,25
communication,24
night,24
chemistry,23
disease,23
disk,23
energy,23
nation,23
road,23
role,23
soup,23
advertising,22
location,22
success,22
addition,21
apartment,21
education,21
math,21
moment,21
painting,21
politics,21
attention,20
decision,20
event,20
property,20
shopping,20
student,20
wood,20
competition,19
distribution,19
entertainment,19
office,19
population,19
president,19
unit,19
category,18
cigarette,18
context,18
introduction,18
opportunity,18
performance,18
driver,17
flight,17
length,17
magazine,17
newspaper,17
relationship,17
teaching,17
cell,16
dealer,16
finding,16
lake,16
member,16
message,16
phone,16
scene,16
appearance,15
association,15
concept,15
customer,15
death,15
discussion,15
housing,15
inflation,15
insurance,15
mood,15
woman,15
advice,14
blood,14
effort,14
expression,14
importance,14
opinion,14
payment,14
reality,14
responsibility,14
situation,14
skill,14
statement,14
wealth,14
application,13
city,13
county,13
depth,13
estate,13
foundation,13
grandmother,13
heart,13
perspective,13
photo,13
recipe,13
studio,13
topic,13
collection,12
depression,12
imagination,12
passion,12
percentage,12
resource,12
setting,12
ad,11
agency,11
college,11
connection,11
criticism,11
debt,11
description,11
memory,11
patience,11
secretary,11
solution,11
administration,10
aspect,10
attitude,10
director,10
personality,10
psychology,10
recommendation,10
response,10
selection,10
storage,10
version,10
alcohol,9
argument,9
complaint,9
contract,9
emphasis,9
highway,9
loss,9
membership,9
possession,9
preparation,9
steak,9
union,9
agreement,8
cancer,8
currency,8
employment,8
engineering,8
entry,8
interaction,8
mixture,8
preference,8
region,8
republic,8
tradition,8
virus,8
actor,7
classroom,7
delivery,7
device,7
difficulty,7
drama,7
election,7
engine,7
football,7
guidance,7
hotel,7
owner,7
priority,7
protection,7
suggestion,7
tension,7
variation,7
anxiety,6
atmosphere,6
awareness,6
bath,6
bread,6
candidate,6
climate,6
comparison,6
confusion,6
construction,6
elevator,6
emotion,6
employee,6
employer,6
guest,6
height,6
leadership,6
mall,6
manager,6
operation,6
recording,6
sample,6
transportation,6
charity,5
cousin,5
disaster,5
editor,5
efficiency,5
excitement,5
extent,5
feedback,5
guitar,5
homework,5
leader,5
mom,5
outcome,5
permission,5
presentation,5
promotion,5
reflection,5
refrigerator,5
resolution,5
revenue,5
session,5
singer,5
tennis,5
basket,4
bonus,4
cabinet,4
childhood,4
church,4
clothes,4
coffee,4
dinner,4
drawing,4
hair,4
hearing,4
initiative,4
judgment,4
lab,4
measurement,4
mode,4
mud,4
orange,4
poetry,4
police,4
possibility,4
procedure,4
queen,4
ratio,4
relation,4
restaurant,4
satisfaction,4
sector,4
signature,4
significance,4
song,4
tooth,4
town,4
vehicle,4
volume,4
wife,4
accident,3
airport,3
appointment,3
arrival,3
assumption,3
baseball,3
chapter,3
committee,3
conversation,3
database,3
enthusiasm,3
error,3
explanation,3
farmer,3
gate,3
girl,3
hall,3
historian,3
hospital,3
injury,3
instruction,3
maintenance,3
manufacturer,3
meal,3
perception,3
pie,3
poem,3
presence,3
proposal,3
reception,3
replacement,3
revolution,3
river,3
son,3
speech,3
tea,3
village,3
warning,3
winner,3
worker,3
writer,3
assistance,2
breath,2
buyer,2
chest,2
chocolate,2
conclusion,2
contribution,2
cookie,2
courage,2
dad,2
desk,2
drawer,2
establishment,2
examination,2
garbage,2
grocery,2
honey,2
impression,2
improvement,2
independence,2
insect,2
inspection,2
inspector,2
king,2
ladder,2
menu,2
penalty,2
piano,2
potato,2
profession,2
professor,2
quantity,2
reaction,2
requirement,2
salad,2
sister,2
supermarket,2
tongue,2
weakness,2
wedding,2
affair,1
ambition,1
analyst,1
apple,1
assignment,1
assistant,1
bathroom,1
bedroom,1
beer,1
birthday,1
celebration,1
championship,1
cheek,1
client,1
consequence,1
departure,1
diamond,1
dirt,1
ear,1
fortune,1
friendship,1
funeral,1
gene,1
girlfriend,1
hat,1
indication,1
intention,1
lady,1
midnight,1
negotiation,1
obligation,1
passenger,1
pizza,1
platform,1
poet,1
pollution,1
recognition,1
reputation,1
shirt,1
sir,1
speaker,1
stranger,1
surgery,1
sympathy,1
tale,1
throat,1
trainer,1
uncle,1
youth,1
