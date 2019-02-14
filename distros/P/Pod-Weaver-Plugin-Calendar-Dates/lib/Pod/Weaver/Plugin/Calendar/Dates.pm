package Pod::Weaver::Plugin::Calendar::Dates;

our $DATE = '2019-02-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Data::Dump;
use List::Util qw(min max uniq);
use Perinci::Result::Format::Lite;

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $cur_year = (localtime)[5]+1900;
    my $min_year = $package->get_min_year;
    my $max_year = $package->get_max_year;

    my $sample_year = max($min_year, min($cur_year  , $max_year));
    my @sample_years = uniq(
        max($min_year, min($cur_year-1, $max_year)),
        max($min_year, min($cur_year  , $max_year)),
        max($min_year, min($cur_year+1, $max_year))
    );

    # add Synopsis section
    {
        my @pod;
        push @pod, "=head2 Using from Perl\n\n";
        push @pod, " use $package;\n";
        push @pod, " my \$min_year = $package->get_min_year; # => $min_year\n";
        push @pod, " my \$max_year = $package->get_max_year; # => $max_year\n";
        push @pod, " my \$entries  = $package->get_entries($sample_year);\n\n";

        my $entries = $package->get_entries($sample_year);
        my $dump = Data::Dump::dump($entries);
        $dump =~ s/^/ /gm;
        push @pod, "C<\$entries> result:\n\n", $dump, "\n\n";

        (my $modshort = $package) =~ s/\ACalendar::Dates:://;
        push @pod, "=head2 Using from CLI (requires L<list-calendar-dates> and L<calx>)\n\n";
        push @pod, " % list-calendar-dates -l -m $modshort\n";
        push @pod, " % calx -c $modshort\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    }

    # add DATES STATISTICS section
    {
        my $table = Perinci::Result::Format::Lite::format(
            [200, "OK", {
                "Earliest year" => $min_year,
                "Latest year"   => $max_year,
            }],
            "text-pretty",
        );
        $table =~ s/^/ /gm;

        my @pod = ($table, "\n\n");
        $self->add_text_to_section(
            $document, join('', @pod), 'DATES STATISTICS',
            {
                after_section => ['DESCRIPTION'],
            },
        );
    }

    # add DATES SAMPLES section
    {
        my @pod;
      YEAR:
        for my $year (@sample_years) {
            my $entries;
            eval { $entries = $package->get_entries($year) };
            do { warn "get_entries($year) died: $@"; next } if $@;

            for my $e (@$entries) {
                $e->{tags} = join(", ", @{$e->{tags}}) if $e->{tags};
            }
            my $table = Perinci::Result::Format::Lite::format(
                [200, "OK", $entries],
                "text-pretty",
            );
            $table =~ s/^/ /gm;

            push @pod, (
                "Entries for year $year:\n\n",
                $table, "\n",
            );
        }
        $self->add_text_to_section(
            $document, join('', @pod), 'DATES SAMPLES',
            {
                after_section => ['DATES STATISTICS'],
            },
        );
    }

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<Calendar::Dates>\n\n",
        "L<App::CalendarDatesUtils> contains CLIs to list dates from this module, etc.\n\n",
        "L<calx> from L<App::calx> can display calendar and highlight dates from Calendar::Dates::* modules\n\n",
    );
    $self->add_text_to_section(
        $document, join('', @pod), 'SEE ALSO',
        {
            after_section => ['DESCRIPTION', 'DATES SAMPLES'],
        },
    );

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    return unless $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;
    return unless $package =~ /\ACalendar::Dates::/;
    $self->_process_module($document, $input, $package);
}

1;
# ABSTRACT: Plugin to use when building Calendar::Dates::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Calendar::Dates - Plugin to use when building Calendar::Dates::* distribution

=head1 VERSION

This document describes version 0.002 of Pod::Weaver::Plugin::Calendar::Dates (from Perl distribution Pod-Weaver-Plugin-Calendar-Dates), released on 2019-02-14.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Calendar::Dates]

=head1 DESCRIPTION

This plugin is used when building Calendar::Dates::* distributions. It currently
does the following:

=over

=item * Create "DATES STATISTICS" POD section

=item * Create "DATES SAMPLES" POD section

=item * Mention some modules in See Also section

e.g. L<Calendar::Dates> (the convention/standard), L<App::CalendarDatesUtils>,
etc.

=back

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Calendar-Dates>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Calendar-Dates>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Calendar-Dates>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Dist::Zilla::Plugin::Calendar::Dates>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
