package Perl6::Feeds;
    require 5.009_005;
    use strict;
    use warnings;
    use Filter::Simple;
    use re 'eval';
    our $VERSION = '0.20';

    FILTER_ONLY code => sub {
        s/(?<!\$)#.*//g;
        my $nested = qr/ (
            ( [{[(] )
              (?: [^{}[\]()]++ | (?-2) )*
            (??{ '\\'.{qw'{ } [ ] ( )'}->{$^N} })
        ) /x;
        my $expression = qr/ (?: $nested | [^;{}[\]()] )+? /x;
        1 while s{
            (?: ^ | (?<= [\{[(;] ) )
              \s*
                (?<source> $expression )
                  \s*  ==+>(?<push> >?+ )(?<merge> [<>]?+ )  \s*
                (?<action> $expression )
              \s*
            (?= ==+>+ | [\}\]);] | $ )
        }{
            'sub{@_}->(' . do {
                my ($source, $action) = @+{qw/source action/};
                $+{merge} eq '<' and "($action), ($source)" or
                $+{merge} eq '>' and "($source), ($action)" or do {
                    for ($action) {
                         $action  = "push $_,", last if $+{push};
                         $action .= '=', last        if /^(?:(?:my|our|local)\W|[$@%&*])/;
                         $source  = ",$source"       unless /^\w+\s*(?:(?=\{)$nested)?$/;
                         $source .= ')'              if s/\)$//;
                    }
                    "$action $source"
                }
            } . ')'
        }xse
    };

=head1 NAME

Perl6::Feeds - implements perl6 feed operators in perl5 via source filtering

=head1 VERSION

version 0.20

requires perl version 5.9.5 or higher

this code is currently in beta, bug reports welcome

=head1 SYNOPSIS

feed operators allow you to write expressions that flow left to right and top down,
rather than the right to left, bottom up order imposed by function nesting.

    use Perl6::Feeds;

    1..10 ==> map {$_**2} ==> grep {$_>10} ==> join " " ==> print;
    # is the same as
    print join " " => grep {$_>10} map {$_**2} 1..10;

    1 .. 3000
        ==> map [$_, $_ ** 2 ]
        ==> grep {$$_[1] =~ s/(([^0])\2{3,})/ ($1) /g}
        ==> our @list                             # assignments start with /my|our|local|[$@%&*]/
        ==> map {@$_ ==> map "[$_]"               # nesting is fine
                     ==> join '^2 ==> '}          # strings are safe
        ==>>> 'found '.@list.' numbers: '         # appends a list
        ==>>< "\nnumbers with squares that ".     # prepends a list
             "have non zero runs of 4+ digits:\n" #   both of these are not in the perl6 spec
        ==>  join ("\n")                          # closed argument lists are adjusted
        ==>>> (@list ==> map $$_[0] ==> join ' ')
      =====> print;                               # feed arrows match /==+>[<>]?/

=head1 SYNTAX

    1 .. 10 ==> join ", " ==> print;  # print join ", " => 1 .. 10;

    1 .. 10 ==> my @a;                # my @a = 1 .. 10;

    20 .. 30 ==>> @a;                 # push @a, 20 .. 30;

    @a ==>>> "appended" ==> print;    # print @a, "appended";

    @a ==>>< "prepended" ==> print;   # print "prepended", @a;

=head1 AUTHOR

Eric Strom, C<< <ejstrom at gmail.com> >>

=head1 BUGS

currently, only left to right feeds are supported, and there may be a few corner cases that
the filter will fail on.

bug reports or patches welcome, send them to C<bug-perl6-feeds at rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Feeds>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

the perl6 synopsi

=head1 COPYRIGHT & LICENSE

copyright 2009 Eric Strom.

this program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Perl6::Feeds
