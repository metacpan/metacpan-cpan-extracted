package TableData::Sample::DeNiro;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.023'; # VERSION

with 'TableDataRole::Source::CSVInDATA';

1;
# ABSTRACT: Rotten Tomato ratings of movies with Robert De Niro

=pod

=encoding UTF-8

=head1 NAME

TableData::Sample::DeNiro - Rotten Tomato ratings of movies with Robert De Niro

=head1 VERSION

This document describes version 0.023 of TableData::Sample::DeNiro (from Perl distribution TableDataRoles-Standard), released on 2024-01-15.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Sample::DeNiro;

 my $td = TableData::Sample::DeNiro->new;

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
 % tabledata Sample::DeNiro --page

 # Get number of rows
 % tabledata --action count_rows Sample::DeNiro

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<ArrayData::Sample::DeNiro>

L<HashData::Sample::DeNiro>

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

This software is copyright (c) 2024, 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
"Year","Score","Title"
1968,86,"Greetings"
1970,17,"Bloody Mama"
1970,73,"Hi,Mom!"
1971,40,"Born to Win"
1973,98,"Mean Streets"
1973,88,"Bang the Drum Slowly"
1974,97,"The Godfather,Part II"
1976,41,"The Last Tycoon"
1976,99,"Taxi Driver"
1977,47,"1900"
1977,67,"New York,New York"
1978,93,"The Deer Hunter"
1980,97,"Raging Bull"
1981,75,"True Confessions"
1983,90,"The King of Comedy"
1984,89,"Once Upon a Time in America"
1984,60,"Falling in Love"
1985,98,"Brazil"
1986,65,"The Mission"
1987,100,"Dear America: Letters Home From Vietnam"
1987,80,"The Untouchables"
1987,78,"Angel Heart"
1988,96,"Midnight Run"
1989,64,"Jacknife"
1989,47,"We're No Angels"
1990,88,"Awakenings"
1990,29,"Stanley & Iris"
1990,96,"Goodfellas"
1991,76,"Cape Fear"
1991,69,"Mistress"
1991,65,"Guilty by Suspicion"
1991,71,"Backdraft"
1992,87,"Thunderheart"
1992,67,"Night and the City"
1993,75,"This Boy's Life"
1993,78,"Mad Dog and Glory"
1993,96,"A Bronx Tale"
1994,39,"Mary Shelley's Frankenstein"
1995,80,"Casino"
1995,86,"Heat"
1996,74,"Sleepers"
1996,38,"The Fan"
1996,80,"Marvin's Room"
1997,85,"Wag the Dog"
1997,87,"Jackie Brown"
1997,72,"Cop Land"
1998,68,"Ronin"
1998,38,"Great Expectations"
1999,69,"Analyze This"
1999,43,"Flawless"
2000,43,"The Adventures of Rocky & Bullwinkle"
2000,84,"Meet the Parents"
2000,41,"Men of Honor"
2001,73,"The Score"
2001,33,"15 Minutes"
2002,48,"City by the Sea"
2002,27,"Analyze That"
2003,4,"Godsend"
2004,35,"Shark Tale"
2004,38,"Meet the Fockers"
2005,4,"The Bridge of San Luis Rey"
2005,46,"Rent"
2005,13,"Hide and Seek"
2006,54,"The Good Shepherd"
2007,21,"Arthur and the Invisibles"
2007,76,"Captain Shakespeare"
2008,19,"Righteous Kill"
2008,51,"What Just Happened?"
2009,47,"Everybody's Fine"
2010,70,"Machete"
2010,9,"Little Fockers"
2010,50,"Stone"
2011,28,"Killer Elite"
2011,7,"New Year's Eve"
2011,68,"Limitless"
2012,92,"Silver Linings Playbook"
2012,51,"Being Flynn"
2012,31,"Red Lights"
2013,46,"Last Vegas"
2013,7,"The Big Wedding"
2013,31,"Grudge Match"
2013,10,"Killing Season"
2014,11,"The Bag Man"
2015,60,"Joy"
2015,30,"Heist"
2015,59,"The Intern"
2016,10,"Dirty Grandpa"
2016,44,"Hands of Stone"
2016,24,"The Comedian"
2017,73,"The Wizard of Lies"
2019,69,"Joker"
2019,95,"The Irishman"
2020,28,"The War with Grandpa"
2020,30,"The Comeback Trail"
2022,32,"Amsterdam"
2022,-,"Savage Salvation"
2023,93,"Killers of the Flower Moon"
2023,37,"About My Father"
2023,73,"Ezra"
