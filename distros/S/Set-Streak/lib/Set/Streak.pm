package Set::Streak;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-24'; # DATE
our $DIST = 'Set-Streak'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(gen_longest_streaks_table);

our %SPEC;

$SPEC{gen_longest_streaks_table} = {
    v => 1.1,
    summary => 'Generate ranking table of longest streaks',
    description => <<'MARKDOWN',

This routine can be used to generate a ranking table of longest streaks,
represented by sets. You supply a list (arrayref) of `sets`, each set
representing a period. The routine will rank the items that appear the longest
in consecutive sets (periods).

For example, let's generate a table for longest daily CPAN releases for November
2023 up until today (assume today is the Nov 5th), the input will be:

    [
      [qw/PERLANCAR DART JJATRIA NERDVANA LEEJO CUKEBOT RSCHUPP JOYREX TANIGUCHI OODLER OLIVER JV/],     # period 1 (first): list of CPAN authors releasing something on Nov 1, 2023
      [qw/SKIM PERLANCAR BURAK BDFOY SUKRIA AJNN YANGAK CCELSO SREZIC/],                                 # period 2: list of CPAN authors releasing something on Nov 2, 2023
      [qw/JGNI DTUCKWELL SREZIC WOUTER LSKATZ SVW RAWLEYFOW DJERIUS PERLANCAR CRORAA EINHVERFR ASPOSE/], # period 3: list of CPAN authors releasing something on Nov 3, 2023
      [qw/JGNI LEONT LANCEW NKH MDOOTSON SREZIC PERLANCAR DROLSKY JOYREX JRM DAMI PRBRENAN DCHURCH/],    # period 4: list of CPAN authors releasing something on Nov 4, 2023
      [qw/JGNI JRM TEAM LICHTKIND JJATRIA JDEGUEST PERLANCAR SVW DRCLAW PLAIN SUKRIA RSCHUPP/],          # period 5 (current): list of CPAN authors releasing something on Nov 5, 2023
    ]

The result of the routine will be like:

    [
      { item => "PERLANCAR", len => 5, start => 1, status => "ongoing" },
      { item => "SREZIC", len => 3, start => 2, status => "might-break" },
      { item => "JGNI", len => 3, start => 3, status => "ongoing" },
      { item => "JRM", len => 2, start => 4, status => "ongoing" },
      { item => "CUKEBOT", len => 1, start => 1, status => "broken" },
      { item => "DART", len => 1, start => 1, status => "broken" },
      { item => "JJATRIA", len => 1, start => 1, status => "broken" },
      ...
    ]

Sorting is done by `len` (descending) first, then by `start` (ascending), then
by `item` (ascending).

MARKDOWN
    args => {
        sets => {
            schema => 'aoaos*',
            req => 1,
        },
        exclude_broken => {
            summary => 'Whether to exclude broken streaks',
            schema => 'bool*',
            description => <<'MARKDOWN',

Streak status is either: `ongoing` (item still appear in current period),
`might-break` (does not yet appear in current period, but current period is
assumed to have not ended yet, later update might still see item appearing), or
`broken` (no longer appear after its beginning period sometime in the past
periods).

If you set this option to true, streaks that have the status of `broken` are not
returned.

MARKDOWN
        },
    },
    args_rels => [
    ],
    result_naked => 1,
};
sub gen_longest_streaks_table {
    my %args = @_;

    my $sets = $args{sets};

    my %streaks; # list of all streaks, key="<starting period>.<item name>", value=[length, broken in which period]
  FIND_STREAKS: {
        my $period = 0;
        my %current_items; # items with streaks currently going, key=item, val=starting period
        for my $set (@$sets) {
            $period++;
            my %items_this_period; $items_this_period{$_}++ for @$set;

            # find new streaks: items that just appear in this period
          FIND_NEW: {
                for my $item (@$set) {
                    next if $current_items{$item};
                    $current_items{$item} = $period;
                    $streaks{ $period . "." . $item } = [0, undef];
                }
            } # FIND_NEW


            # find broken streaks: items that no longer appear in this period
          FIND_BROKEN: {
                for my $item (keys %current_items) {
                    my $key = $current_items{$item} . "." . $item;
                    if ($items_this_period{$item}) {
                        # streak keeps going
                        $streaks{$key}[0]++;
                    } else {
                        # streak broken (but for current period, it might not
                        # just yet, the item might still appear later before the
                        # end of the current period. you just need to check if
                        # period number recorded is the current period
                        $streaks{$key}[1] = $period;
                        delete $current_items{$item};
                    }
                }
            } # FIND_BROKEN
        } # for $set
    } # FIND_STREAKS

    my $cur_period = @$sets;
  FILTER_STREAKS: {
        last unless $args{exclude_broken};
        for my $key (keys %streaks) {
            my $streak = $streaks{$key};
            next unless defined $streak->[1];
            next if $streak->[1] == $cur_period;
            delete $streaks{$key};
        }
    } # FILTER_STREAKS

    my @res;
  RANK_STREAKS: {
        require List::Rank;
        my @rankres = List::Rank::sortrankby(
            sub {
                my $streak_a = $streaks{$a};
                my $streak_b = $streaks{$b};
                my ($start_a, $item_a) = $a =~ /\A(\d+)\.(.*)\z/ or die;
                my ($start_b, $item_b) = $b =~ /\A(\d+)\.(.*)\z/ or die;
                ($streak_b->[0] <=> $streak_a->[0]) || # longer streaks first
                    ($start_a <=> $start_b) ||         # earlier streaks first
                    ($item_a cmp $item_b);             # asciibetically
            },
            keys %streaks
        );

        while (my ($key, $rank) = splice @rankres, 0, 2) {
            my ($start, $item) = $key =~ /\A(\d+)\.(.*)\z/ or die;
            my $streak = $streaks{$key};
            my $status = !defined($streak->[1]) ? "ongoing" :
                ($streak->[1] < $cur_period) ? "broken" : "might-break";
            push @res, {
                item => $item,
                start => $start,
                len => $streak->[0],
                status => $status,
            };
        }
    } # RANK_STREAKS

    \@res;
}

1;
# ABSTRACT: Routines related to streaks (longest item appearance in consecutive sets)

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Streak - Routines related to streaks (longest item appearance in consecutive sets)

=head1 VERSION

This document describes version 0.003 of Set::Streak (from Perl distribution Set-Streak), released on 2023-11-24.

=head1 FUNCTIONS


=head2 gen_longest_streaks_table

Usage:

 gen_longest_streaks_table(%args) -> any

Generate ranking table of longest streaks.

This routine can be used to generate a ranking table of longest streaks,
represented by sets. You supply a list (arrayref) of C<sets>, each set
representing a period. The routine will rank the items that appear the longest
in consecutive sets (periods).

For example, let's generate a table for longest daily CPAN releases for November
2023 up until today (assume today is the Nov 5th), the input will be:

 [
   [qw/PERLANCAR DART JJATRIA NERDVANA LEEJO CUKEBOT RSCHUPP JOYREX TANIGUCHI OODLER OLIVER JV/],     # period 1 (first): list of CPAN authors releasing something on Nov 1, 2023
   [qw/SKIM PERLANCAR BURAK BDFOY SUKRIA AJNN YANGAK CCELSO SREZIC/],                                 # period 2: list of CPAN authors releasing something on Nov 2, 2023
   [qw/JGNI DTUCKWELL SREZIC WOUTER LSKATZ SVW RAWLEYFOW DJERIUS PERLANCAR CRORAA EINHVERFR ASPOSE/], # period 3: list of CPAN authors releasing something on Nov 3, 2023
   [qw/JGNI LEONT LANCEW NKH MDOOTSON SREZIC PERLANCAR DROLSKY JOYREX JRM DAMI PRBRENAN DCHURCH/],    # period 4: list of CPAN authors releasing something on Nov 4, 2023
   [qw/JGNI JRM TEAM LICHTKIND JJATRIA JDEGUEST PERLANCAR SVW DRCLAW PLAIN SUKRIA RSCHUPP/],          # period 5 (current): list of CPAN authors releasing something on Nov 5, 2023
 ]

The result of the routine will be like:

 [
   { item => "PERLANCAR", len => 5, start => 1, status => "ongoing" },
   { item => "SREZIC", len => 3, start => 2, status => "might-break" },
   { item => "JGNI", len => 3, start => 3, status => "ongoing" },
   { item => "JRM", len => 2, start => 4, status => "ongoing" },
   { item => "CUKEBOT", len => 1, start => 1, status => "broken" },
   { item => "DART", len => 1, start => 1, status => "broken" },
   { item => "JJATRIA", len => 1, start => 1, status => "broken" },
   ...
 ]

Sorting is done by C<len> (descending) first, then by C<start> (ascending), then
by C<item> (ascending).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_broken> => I<bool>

Whether to exclude broken streaks.

Streak status is either: C<ongoing> (item still appear in current period),
C<might-break> (does not yet appear in current period, but current period is
assumed to have not ended yet, later update might still see item appearing), or
C<broken> (no longer appear after its beginning period sometime in the past
periods).

If you set this option to true, streaks that have the status of C<broken> are not
returned.

=item * B<sets>* => I<aoaos>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Set-Streak>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Set-Streak>.

=head1 SEE ALSO

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set-Streak>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
