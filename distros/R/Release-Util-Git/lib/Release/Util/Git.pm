package Release::Util::Git;

our $DATE = '2017-02-10'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_git_release_tags} = {
    v => 1.1,
    summary => 'List git release tags',
    description => <<'_',

It's common to tag a release with something like:

    v1.2.3

This routine returns a list of them.

_
    args => {
        regex => {
            summary => 'Regex to match a release tag',
            schema => 're*',
            default => qr/\A(version|ver|v)?\d/,
        },
        detail => {
            schema => ['bool*', is=>1],
            cmdline_aliases => {l=>{}},
        },
    },
    deps => {
        prog => 'git',
    },
    examples => [
        {
            args => {detail=>1, regex=>'^release'},
            'x.doc.show_result' => 0,
            test => 0,
        },
    ],
};
sub list_git_release_tags {
    require File::Which;

    my %args = @_;

    # XXX schema
    my $regex = $args{regex} // qr/\A(version|ver|v)?\d/;

    -d ".git" or return [412, "No .git subdirectory found"];
    File::Which::which("git") or return [412, "git is not found in PATH"];

    my @res;
    my $resmeta = {};

    for my $line (`git for-each-ref --format='%(creatordate:raw) %(refname) %(objectname)' refs/tags`) {
        my ($epoch, $offset, $tag, $commit) = $line =~ m!^(\d+) ([+-]\d+) refs/tags/(.+) (.+)$! or next;
        $tag =~ $regex or next;
        push @res, {
            tag => $tag,
            date => $epoch,
            tz_offset => $offset,
            commit => $commit,
        };
    }

    if ($args{detail}) {
        $resmeta->{'table.fields'} = [qw/tag date tz_offset commit/];
    } else {
        @res = map { $_->{tag} } @res;
    }

    [200, "OK", \@res, $resmeta];
}

$SPEC{list_git_release_years} = {
    v => 1.1,
    summary => 'List git release years',
    description => <<'_',

This routine uses list_git_release_tags() to collect the release tags and their
dates, then group them by year.

_
    args => $SPEC{list_git_release_tags}{args},
    deps => $SPEC{list_git_release_tags}{deps},
    examples => [
        {
            args => {detail=>1, regex=>'^release'},
            'x.doc.show_result' => 0,
            test => 0,
        },
    ],
};
sub list_git_release_years {
    my %args = @_;
    my $res = list_git_release_tags(%args, detail=>1);
    return $res unless $res->[0] == 200;

    my %tags; # key = year, value = tags
    for my $e (@{ $res->[2] }) {
        # XXX use tz_offset? use gmtime?
        my $year = (localtime $e->{date})[5] + 1900;
        push @{ $tags{$year} }, $e->{tag};
    }

    my $resmeta = {};

    my @res;
    if ($args{detail}) {
        @res = map { +{year=>$_, tags=>$tags{$_}} }
            reverse sort keys %tags;
        $resmeta->{'table.fields'} = [qw/year tags/];
    } else {
        @res = reverse sort keys %tags;
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Utility routines related to software releases and git

__END__

=pod

=encoding UTF-8

=head1 NAME

Release::Util::Git - Utility routines related to software releases and git

=head1 VERSION

This document describes version 0.004 of Release::Util::Git (from Perl distribution Release-Util-Git), released on 2017-02-10.

=head1 FUNCTIONS


=head2 list_git_release_tags

Usage:

 list_git_release_tags(%args) -> [status, msg, result, meta]

List git release tags.

Examples:

=over

=item * Example #1:

 list_git_release_tags(detail => 1, regex => "^release");

=back

It's common to tag a release with something like:

 v1.2.3

This routine returns a list of them.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<regex> => I<re> (default: qr(\A(version|ver|v)?\d))

Regex to match a release tag.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_git_release_years

Usage:

 list_git_release_years(%args) -> [status, msg, result, meta]

List git release years.

Examples:

=over

=item * Example #1:

 list_git_release_years(detail => 1, regex => "^release");

=back

This routine uses list_git_release_tags() to collect the release tags and their
dates, then group them by year.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<regex> => I<re> (default: qr(\A(version|ver|v)?\d))

Regex to match a release tag.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Release-Util-Git>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Release-Util-Git>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Release-Util-Git>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
