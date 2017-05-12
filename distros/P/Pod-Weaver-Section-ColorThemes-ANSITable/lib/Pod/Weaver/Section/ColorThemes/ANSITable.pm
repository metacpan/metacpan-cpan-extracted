package Pod::Weaver::Section::ColorThemes::ANSITable;

our $DATE = '2015-04-01'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    my $pkg_p;
    my $pkg;
    my $short_pkg;
    if ($filename =~ m!^lib/(.+/ColorTheme/.+)$!) {
        $pkg_p = $1;
        $pkg = $1; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
        $short_pkg = $pkg; $short_pkg =~ s/.+::ColorTheme:://;
    } else {
        $self->log_debug(["skipped file %s (not a ColorTheme module)", $filename]);
        return;
    }

    local @INC = @INC;
    unshift @INC, 'lib';
    require $pkg_p;
    #require Text::ANSITable;

    my $text = "Below are the color themes included in this package:\n\n";
    {
        no strict 'refs';
        my $color_themes = \%{"$pkg\::color_themes"};
        for my $style (sort keys %$color_themes) {
            my $spec = $color_themes->{$style};
            $text .= "=head2 $short_pkg\::$style\n\n";
            $text .= "$spec->{summary}.\n\n" if $spec->{summary};
            $text .= "$spec->{description}\n\n" if $spec->{description};
        }
    }

    $self->add_text_to_section($document, $text, 'COLOR THEMES');
}

no Moose;
1;
# ABSTRACT: Add a COLOR THEMES section for ANSITable ColorTheme module

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::ColorThemes::ANSITable - Add a COLOR THEMES section for ANSITable ColorTheme module

=head1 VERSION

This document describes version 0.04 of Pod::Weaver::Section::ColorThemes::ANSITable (from Perl distribution Pod-Weaver-Section-ColorThemes-ANSITable), released on 2015-04-01.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [ColorThemes::ANSITable]

=head1 DESCRIPTION

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-ColorThemes-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-ColorThemes-ANSITable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-ColorThemes-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.
=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
