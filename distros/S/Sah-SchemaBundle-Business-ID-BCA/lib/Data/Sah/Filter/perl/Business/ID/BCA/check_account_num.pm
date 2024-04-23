package Data::Sah::Filter::perl::Business::ID::BCA::check_account_num;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-03'; # DATE
our $DIST = 'Sah-SchemaBundle-Business-ID-BCA'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Check that string is a well-formed BCA account number',
        description => <<'MARKDOWN',

Note that this does not check whether a well-formed 10 digit actually has an
associated account number. This does not contact a BCA API or online database of
any form.

MARKDOWN
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{"Business::ID::BCA"} //= 0;

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; my \$res = Business::ID::BCA::parse_bca_account(account => \$tmp); \$res->[0] == 200 ? [undef,\$tmp] : [\$res->[1], \$tmp] }",
    );

    $res;
}

1;
# ABSTRACT: Check that string is a well-formed BCA account number

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Business::ID::BCA::check_account_num - Check that string is a well-formed BCA account number

=head1 VERSION

This document describes version 0.002 of Data::Sah::Filter::perl::Business::ID::BCA::check_account_num (from Perl distribution Sah-SchemaBundle-Business-ID-BCA), released on 2024-04-03.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Business-ID-BCA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Business-ID-BCA>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Business-ID-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
