package Sort::Sub;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.121'; # VERSION

our $re_spec = qr/\A(\$)?(\w+)(?:<(\w*)>)?\z/;

our %argsopt_sortsub = (
    sort_sub => {
        summary => 'Name of a Sort::Sub::* module (without the prefix)',
        schema => ['sortsub::spec*'],
    },
    sort_args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'sort_arg',
        summary => 'Arguments to pass to the Sort::Sub::* routine',
        schema => ['array*', of=>'str*'],
        element_completion => sub {
            my %cargs = @_;

            # do we have the routine already? if yes, extract the metadata
            my $rname = $cargs{args}{sort_sub};
            return [] unless defined $rname;

            my $mod = "Sort::Sub::$rname";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            eval { require $mod_pm };
            return {message=>"Cannot load $mod: $@"} if $@;
            my $meta;
            eval { $meta = $mod->meta };
            return [] unless $meta;

            require Complete::Sequence;
            return Complete::Sequence::complete_sequence(
                word => $cargs{word},
                sequence => [
                    sub {
                        [$meta->{args} ? keys(%{ $meta->{args} }) : ()];
                    },
                    '=',
                    sub {
                        my $stash = shift;
                        my $argname = $stash->{completed_item_words}[0];
                        return [] unless defined $argname;

                        my $argspec = $meta->{args}{$argname};
                        return [] unless $argspec->{schema};

                        require Complete::Sah;
                        require Complete::Util;
                        Complete::Util::arrayify_answer(
                            Complete::Sah::complete_from_schema(
                                word => $stash->{cur_word},
                                schema => $argspec->{schema},
                            )
                          );

                    },
                ],
            );
        },
    },
);

sub get_sorter {
    my ($spec, $args, $with_meta) = @_;

    my ($is_var, $name, $opts) = $spec =~ $re_spec
        or die "Invalid sorter spec '$spec', please use: ".
        '[$]NAME [ <OPTS> ]';
    my $modpm = "Sort/Sub/$name.pm";
    require $modpm;
    $opts //= "";
    my $is_reverse = $opts =~ /r/;
    my $is_ci      = $opts =~ /i/;
    my $gen_sorter = \&{"Sort::Sub::$name\::gen_sorter"};
    my $sorter = $gen_sorter->($is_reverse, $is_ci, $args // {});
    if ($with_meta) {
        my $meta = {};
        eval { $meta = &{"Sort::Sub::$name\::meta"}() };
        warn if $@;
        return ($sorter, $meta);
    } else {
        return $sorter;
    }
}

sub import {
    my $class = shift;
    my $caller = caller;

    my $i = -1;
    while (1) {
        $i++;
        last if $i >= @_;
        my $import = $_[$i];
        my $args = {};
        if (ref $_[$i+1] eq 'HASH') {
            $args = $_[$i+1];
            $i++;
        }
        my $sorter = get_sorter($import, $args);
        my ($is_var, $name) = $import =~ $re_spec; # XXX double matching
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

This document describes version 0.121 of Sort::Sub (from Perl distribution Sort-Sub), released on 2024-07-17.

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

Pass arguments to sort generator routine:

 use Sort::Sub '$by_num_of_colons', {pattern=>':'};

 my @sorted = sort $by_num_of_colons ('a::','b:','c::::','d:::');
 => ('b:','a::','d:::','c::::')

Request a coderef directly, without using the import interface:

 use Sort::Sub;

 my $naturally = Sort::Sub::get_sorter('naturally');
 my $naturally = Sort::Sub::get_sorter('$naturally');
 my $rev_naturally = Sort::Sub::get_sorter('naturally<r>');

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

 ($is_reverse, $is_ci, $args)

Where C<$is_reserve> will be set to true if user requests a reverse sort,
C<$is_ci> will be set to true if user requests a case-insensitive sort. C<$args>
is hashref to pass additional arguments to the C<gen_sorter()> routine. The
subroutine should return a code reference.

The module should also contain a C<meta> subroutine which returns a metadata
L<DefHash>. Known properties (keys) include: C<v> (currently at 1), C<summary>,
C<compares_record> (bool, if set to true then sorter will be fed records C<<
[$data, $order] >> instead of just C<$data>; C<$order> is a number that can be
line number of array index; this allows sorter to sort by additional information
instead of just the data items). Other metadata properties will be added in the
future.

=head1 FUNCTIONS

=head2 get_sorter

Usage:

 my $coderef = Sort::Sub::get_sorter('SPEC' [ , \%args [ , $with_meta ] ]);

Example:

 my $rev_naturally = Sort::Sub::get_sorter('naturally<r>');

This is an alternative to using the import interface. This function is not
imported.

If C<$with_meta> is set to true, will return this:

 ($sorter, $meta)

instead of just the C<$sorter> subroutine.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

=head1 SEE ALSO

Other additional C<Sort::Sub::*> not bundled in this distribution.

Supporting CLI's: L<sortsub> (from L<App::sortsub>), L<sorted> (from
L<App::sorted>), CLI's from L<App::SortSubUtils>.

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
