package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Perl::CPAN::Release::Dynamic;

use 5.010001;
use strict;
use warnings;

use App::MetaCPANUtils;
use DateTime::Format::ISO8601;

use Role::Tiny;
with 'TableDataRole::Source::AOH';
with 'TableDataRole::Util::CSV';

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_meth => 1,
    is_func => 0,
    args => {
        from_date => {
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
            req => 1,
            pos => 0,
        },
        to_date => {
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
            req => 1,
            pos => 1,
        },
    },
};

around new => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    my $from_date = $args{from_date};
    if (!ref($from_date)) {
        $from_date = DateTime::Format::ISO8601->parse_datetime($from_date);
    }
    my $to_date = $args{to_date};
    if (!ref($to_date)) {
        $to_date = DateTime::Format::ISO8601->parse_datetime($to_date);
    }
    my $res = App::MetaCPANUtils::list_metacpan_releases(
        from_date => $from_date,
        to_date => $to_date,
        fields => [map {$_->[0]} @$App::MetaCPANUtils::release_fields],
    );

    my $aoh = $res->[2];
    $orig->($self, aoh=>$aoh);
};

package TableData::Perl::CPAN::Release::Dynamic;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-06'; # DATE
our $DIST = 'TableData-Perl-CPAN-Release-Dynamic'; # DIST
our $VERSION = '0.003'; # VERSION

with 'TableDataRole::Perl::CPAN::Release::Dynamic';

1;
# ABSTRACT: CPAN releases

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Perl::CPAN::Release::Dynamic - CPAN releases

=head1 VERSION

This document describes version 0.003 of TableDataRole::Perl::CPAN::Release::Dynamic (from Perl distribution TableData-Perl-CPAN-Release-Dynamic), released on 2024-01-06.

=head1 SYNOPSIS

From the command-line (requires the CLI L<tabledata> from L<App::tabledata>):

 # Show 2023-12-28 releases:
 % tabledata Perl::CPAN::Release::Dynamic=from_date,2023-12-28,to_date,2023-12-28

=head1 TABLEDATA NOTES

The data is retrieved dynamically from MetaCPAN.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Perl-CPAN-Release-Dynamic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Perl-CPAN-Release-Dynamic>.

=head1 SEE ALSO

L<TableData::Perl::CPAN::Release::Static>

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Perl-CPAN-Release-Dynamic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
