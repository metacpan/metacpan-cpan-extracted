package Perinci::Sub::XCompletion::lcpan_authorid;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Sub::XCompletionBundle::lcpan;
use Complete::Util qw(complete_array_elem);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-02'; # DATE
our $DIST = 'Perinci-Sub-XCompletionBundle-lcpan'; # DIST
our $VERSION = '0.003'; # VERSION

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
            or return;

        my $sth;
        $sth = $dbh->prepare(
            "SELECT cpanid,fullname FROM author WHERE cpanid LIKE '$word%' ORDER BY cpanid");
        $sth->execute;
        my (@all_cpanids, @all_fullnames);
        while (my @row = $sth->fetchrow_array) {
            push @all_cpanids, $row[0];
            push @all_fullnames, $row[1];
        }
        return complete_array_elem(
            array     => \@all_cpanids,
            summaries => \@all_fullnames,
            word      => $word,
        );
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

This document describes version 0.003 of Perinci::Sub::XCompletion::lcpan_authorid (from Perl distribution Perinci-Sub-XCompletionBundle-lcpan), released on 2022-09-02.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-lcpan>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
