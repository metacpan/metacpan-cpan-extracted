package Pod::Weaver::Plugin::TableData;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::RequireFromBuild';
with 'Pod::Weaver::Role::Section';

use File::Slurper qw(write_text);
use File::Temp qw(tempfile);
use List::Util qw(first);
use Perinci::Result::Format::Lite;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-06'; # DATE
our $DIST = 'Pod-Weaver-Plugin-TableData'; # DIST
our $VERSION = '0.003'; # VERSION

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_module {
    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    $self->require_from_build({reload=>1}, $input, $package);

    my $td_name = $package;
    $td_name =~ s/\ATableData:://;

  ADD_SYNOPSIS_SECTION:
    {
        my @pod;
        push @pod, "To use from Perl code:\n";
        push @pod, "\n";

        push @pod, " use $package;\n\n";
        push @pod, " my \$td = $package->new;\n";
        push @pod, "\n";

        push @pod, " # Iterate rows of the table\n";
        push @pod, " \$td->each_row_arrayref(sub { my \$row = shift; ... });\n";
        push @pod, " \$td->each_row_hashref (sub { my \$row = shift; ... });\n";
        push @pod, "\n";

        push @pod, " # Get the list of column names\n";
        push @pod, " my \@columns = \$td->get_column_names;\n";
        push @pod, "\n";

        push @pod, " # Get the number of rows\n";
        push @pod, " my \$row_count = \$td->get_row_count;\n";
        push @pod, "\n";

        push @pod, "See also L<TableDataRole::Spec::Basic> for other methods.\n";
        push @pod, "\n";

        push @pod, "To use from command-line (using L<tabledata> CLI):\n";
        push @pod, "\n";

        push @pod, " # Display as ASCII table and view with pager\n";
        push @pod, " % tabledata $td_name --page\n";
        push @pod, "\n";

        push @pod, " # Get number of rows\n";
        push @pod, " % tabledata --action count_rows $td_name\n";
        push @pod, "\n";

        push @pod, "See the L<tabledata> CLI's documentation for other available actions and options.\n";
        push @pod, "\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_SYNOPSIS_SECTION

  ADD_STATISTICS_SECTION:
    {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        my @pod;
        my $no_stats = ${"$package\::NO_STATS"};
        if ($no_stats) {
            $self->log_debug("Package $package sets \$NO_STATS, skip generating TABLEDATA STATISTICS POD section");
            last;
        }
        my $stats = \%{"$package\::STATS"};
        unless (keys %$stats) {
            $self->log_debug("Package $package does not define keys in \%STATS, skip generating TABLEDATA STATISTICS POD section");
            #use Package::MoreUtil; use DDC; dd( Package::MoreUtil::list_package_contents($package) );
            #use DDC; dd \%INC;
            last;
        }
        my $str = Perinci::Result::Format::Lite::format(
            [200,"OK",$stats], "text-pretty");
        $str =~ s/^/ /gm;
        push @pod, $str, "\n";

        push @pod, "The statistics is available in the C<\%STATS> package variable.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'TABLEDATA STATISTICS',
            {
                after_section => ['SYNOPSIS'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_STATISTICS_SECTION

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(TableData/.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building TableData::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::TableData - Plugin to use when building TableData::* distribution

=head1 VERSION

This document describes version 0.003 of Pod::Weaver::Plugin::TableData (from Perl distribution Pod-Weaver-Plugin-TableData), released on 2023-02-06.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-TableData]

=head1 DESCRIPTION

This plugin is to be used when building C<TableData::*> distribution. Currently
it does the following:

=over

=item * Add a Synopsis section (if doesn't already exist) showing how to use the module

=item * Add TableData Statistics section showing statistics from C<%STATS> (which can be generated by Dist::Zilla::Plugin:TableData)

=back

=for Pod::Coverage ^(weave_section)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-TableData>.

=head1 SEE ALSO

L<TableData>

L<Dist::Zilla::Plugin::TableData>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
