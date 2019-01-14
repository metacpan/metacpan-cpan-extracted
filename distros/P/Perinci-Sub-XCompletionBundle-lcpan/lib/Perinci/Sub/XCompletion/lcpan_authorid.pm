package Perinci::Sub::XCompletion::lcpan_authorid;

our $DATE = '2019-01-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Sub::XCompletionBundle::lcpan;
use Complete::Util qw(complete_array_elem);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {

    my %fargs = @_;

    sub {
        my %cargs = @_;
        my $word    = $cargs{word} // '';
        my $r       = $cargs{r};

        my $dbh = Perinci::Sub::XCompletionBundle::lcpan::_connect_lcpan()
            or return undef;

        my $sth;
        $sth = $dbh->prepare(
            "SELECT cpanid FROM author WHERE cpanid LIKE '$word%' ORDER BY cpanid");
        $sth->execute;
        my @all_authors;
        while (my @row = $sth->fetchrow_array) {
            push @all_authors, $row[0];
        }
        return complete_array_elem(array=>\@all_authors, word=>$word);
    }
}

1;
# ABSTRACT: Generate completion of CPAN author IDs from local CPAN index

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::lcpan_authorid - Generate completion of CPAN author IDs from local CPAN index

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::XCompletion::lcpan_authorid (from Perl distribution Perinci-Sub-XCompletionBundle-lcpan), released on 2019-01-13.

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
