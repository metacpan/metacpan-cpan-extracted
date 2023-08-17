package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Acme::CPANAuthors;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::AOA';

around new => sub {
    require Acme::CPANAuthors;

    my $orig = shift;
    my ($self, %args) = @_;

    my $module = delete $args{module}
        or die "Please specify 'module' argument";
    $module =~ s/\AAcme::CPANAuthors:://;
    my $authors = Acme::CPANAuthors->new($module);

    my $aoa = [];
    my $column_names = [qw/
                              cpanid
                              name
                          /];
    for my $cpanid ($authors->id) {
        push @$aoa, [
            $cpanid,
            $authors->name($cpanid),
        ];
    }

    $orig->($self, %args, aoa => $aoa, column_names=>$column_names);
};

package TableData::Acme::CPANAuthors;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-28'; # DATE
our $DIST = 'TableData-Acme-CPANAuthors'; # DIST
our $VERSION = '0.003'; # VERSION

with 'TableDataRole::Acme::CPANAuthors';

# STATS

1;
# PODNAME: TableData::Acme::CPANAuthors
# ABSTRACT: Authors listed in an Acme::CPANAuthors::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Acme::CPANAuthors - Authors listed in an Acme::CPANAuthors::* module

=head1 VERSION

This document describes version 0.003 of TableDataRole::Acme::CPANAuthors (from Perl distribution TableData-Acme-CPANAuthors), released on 2023-07-28.

=head1 SYNOPSIS

Using from the CLI:

 % tabledata Acme/CPANAuthors=module,Indonesian

=head1 DESCRIPTION

A quick way to list the contents of an Acme::CPANAuthors::* module in table
fXSorm.

This table gets its data dynamically by querying L<Acme::CPANAuthors> (and the
specific authors module, e.g. L<Acme::CPANAuthors::Indonesian>).

=head1 METHODS

=head2 new

Usage:

 my $table = TableData::Acme::CPANAuthors->new(%args);
`
Known arguments:

=over

=item * module

Required.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Acme-CPANAuthors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Acme-CPANAuthors>.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<acme-cpanauthors> from L<App::AcmeCPANAuthors>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Acme-CPANAuthors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
