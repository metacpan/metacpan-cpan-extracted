package Set::IntSpan::Util;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-10'; # DATE
our $DIST = 'Set-IntSpan-Util'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(intspans2str);

sub intspans2str {
    require Set::IntSpan;

    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    $opts->{dash} //= "-";
    $opts->{comma} //= ", ";

    my @sets = Set::IntSpan->new(@_)->sets;
    my @res;
    for my $set (@sets) {
        my $min = $set->min;
        my $max = $set->max;
        my ($smin, $smax);
        if (!defined($min)) {
            $smin = "-Inf";
        }
        if (!defined($max)) {
            $smax = defined $min ? "Inf" : "+Inf";
        }
        if (defined $min && defined $max && $min == $max) {
            push @res, $min;
        } else {
            push @res, ($smin // $min) . $opts->{dash} . ($smax // $max);
        }
    }
    join($opts->{comma}, @res);
}

1;
# ABSTRACT: Utility routines related to integer spans

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::IntSpan::Util - Utility routines related to integer spans

=head1 VERSION

This document describes version 0.001 of Set::IntSpan::Util (from Perl distribution Set-IntSpan-Util), released on 2022-01-10.

=head1 SYNOPSIS

 use Set::IntSpan::Util qw(intspans2str);

 $str = intspans2str(1);           # => "1"
 $str = intspans2str(1,2,3,4,5);   # => "1-5"
 $str = intspans2str(1,3,4,6,8);   # => "1, 3-4, 6-8"

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 intspans2str

Usage:

 my $str = intspans2str([ \%opts, ] @set_spec);

Given set specification, return a canonical string representation of the set.

This function passes the arguments to L<Set::IntSpan>'s constructor and then
return a canonical string representation of the set, which is a comma-separated
representation of each contiguous ranges. A single-integer range is represented
as the integer. A multiple-integers range from A to B is represented as "A-B".
Examples:

 1
 1-3
 1-3, 5-8
 -Inf-2, 5-8
 5-8, 10-Inf
 -Inf-+Inf

An optional hashref can be given in the first argument for options. Known
options:

=over

=item * dash

Default C<->.

=item * comma

Default C<, >.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Set-IntSpan-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Set-IntSpan-Util>.

=head1 SEE ALSO

L<Set::IntSpan>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set-IntSpan-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
