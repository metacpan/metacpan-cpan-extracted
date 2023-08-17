package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Acme::CPANModules;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::AOA';

around new => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    my $ac_module = delete $args{module}
        or die "Please specify 'module' argument";
    $ac_module =~ s/\AAcme::CPANModules:://;
    my $list = do {
        my $module = "Acme::CPANModules::$ac_module";
        (my $module_pm = "$module.pm") =~ s!::!/!g;
        require $module_pm;
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        ${"$module\::LIST"};
    };

    my $aoa = [];
    my $column_names = [qw/
                              module
                              script
                              summary
                              description
                              rating
                          /];
    for my $entry (@{ $list->{entries} }) {
        push @$aoa, [
            $entry->{module},
            $entry->{script},
            $entry->{summary},
            $entry->{description},
        ];
    }

    $orig->($self, %args, aoa => $aoa, column_names=>$column_names);
};

package TableData::Acme::CPANModules;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-28'; # DATE
our $DIST = 'TableData-Acme-CPANModules'; # DIST
our $VERSION = '0.003'; # VERSION

with 'TableDataRole::Acme::CPANModules';

# STATS

1;
# PODNAME: TableData::Acme::CPANModules
# ABSTRACT: Entries from an Acme::CPANModules::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Acme::CPANModules - Entries from an Acme::CPANModules::* module

=head1 VERSION

This document describes version 0.003 of TableDataRole::Acme::CPANModules (from Perl distribution TableData-Acme-CPANModules), released on 2023-07-28.

=head1 SYNOPSIS

Using from the CLI:

 % tabledata Acme/CPANModules=module,WorkingWithCSV

=head1 DESCRIPTION

A quick way to list the entries in an C<Acme::CPANModules::*> module in table
form. For a more proper way, see L<cpanmodules> CLI.

=head1 METHODS

=head2 new

Usage:

 my $table = TableData::Acme::CPANModules->new(%args);

Known arguments:

=over

=item * module

Required.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Acme-CPANModules>.

=head1 SEE ALSO

L<Acme::CPANModules>

L<cpanmodules> from L<App::cpanmodules>

L<App::CPANModulesUtils>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
