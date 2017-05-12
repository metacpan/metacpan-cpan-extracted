package Sort::Sub;

our $DATE = '2016-12-18'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

sub import {
    my $class = shift;
    my $caller = caller;

    for my $import (@_) {
        my ($is_var, $name, $opts) = $import =~ /\A(\$)?(\w+)(?:<(\w*)>)?\z/
            or die "Invalid import request '$import', please use: ".
            '[$]NAME [ <OPTS> ]';
        require "Sort/Sub/$name.pm";
        $opts //= "";
        my $is_reverse = $opts =~ /r/;
        my $is_ci      = $opts =~ /i/;
        my $gen_sorter = \&{"Sort::Sub::$name\::gen_sorter"};
        my $sorter = $gen_sorter->($is_reverse, $is_ci);
        if ($is_var) {
            ${"$caller\::$name"} = \&$sorter;
        } else {
            no warnings 'redefine';
            *{"$caller\::$name"} = \&$sorter;
        }
    }
}

1;
# ABSTRACT: Collection of sort subroutines

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub - Collection of sort subroutines

=head1 VERSION

This document describes version 0.10 of Sort::Sub (from Perl distribution Sort-Sub), released on 2016-12-18.

=head1 SYNOPSIS

 use Sort::Sub qw($naturally);

 my @sorted = sort $naturally ('track1.mp3', 'track10.mp3', 'track2.mp3', 'track1b.mp3', 'track1a.mp3');
 # => ('track1.mp3', 'track1a.mp3', 'track1b.mp3', 'track2.mp3', 'track10.mp3')

Request as subroutine:

 use Sort::Sub qw(naturally);

 my @sorted = sort {naturally} (...);

Request a reverse sort:

 use Sort::Sub qw($naturally<r>);

 my @sorted = sort $naturally (...);
 # => ('track10.mp3', 'track2.mp3', 'track1b.mp3', 'track1a.mp3', 'track1.mp3')

Request a case-insensitive sort:

 use Sort::Sub qw($naturally<i>);

 my @sorted = sort $naturally (...);

Request a case-insensitive, reverse sort:

 use Sort::Sub qw($naturally<ir>);

 my @sorted = sort $naturally ('track2.mp3', 'Track1.mp3', 'Track10.mp3');
 => ('Track10.mp3', 'track2.mp3', 'Track1.mp3')

Use with

=head1 DESCRIPTION

L<Sort::Sub> and C<Sort::Sub::*> are a convenient packaging of any kind of
subroutine which you can use for C<sort()>.

To use Sort::Sub, you import a list of:

 ["$"]NAME [ "<" [i][r] ">" ]

Where NAME is actually searched under C<Sort::Sub::*> namespace. For example:

 naturally

will attempt to load C<Sort::Sub::naturally> module and call its C<gen_sorter>
subroutine.

You can either request a subroutine name like the above or a variable name (e.g.
C<$naturally>).

After the name, you can add some options, enclosed with angle brackets C<< <>
>>. There are some known options, e.g. C<i> (for case-insensitive sort) or C<r>
(for reverse sort). Some examples:

 naturally<i>
 naturally<r>
 naturally<ri>

=head1 GUIDELINES FOR WRITING A SORT::SUB::* MODULE

The name should be in lowercase. It should be an adverb (e.g. C<naturally>) or a
phrase with words separated by underscore (C<_>) and the phrase begins with
C<by> (e.g. C<by_num_and_non_num_parts>).

The module must contain a C<gen_sorter> subroutine. It will be called with:

 ($is_reverse, $is_ci)

Where C<$is_reserve> will be set to true if user requests a reverse sort, and
C<$is_ci> will be set to true if user requests a case-insensitive sort. The
subroutine should return a code reference.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
