package Pod::Weaver::Section::BorderStyles::ANSITable;

our $DATE = '2015-04-01'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    my $pkg_p;
    my $pkg;
    my $short_pkg;
    if ($filename =~ m!^lib/(.+/BorderStyle/.+)$!) {
        $pkg_p = $1;
        $pkg = $1; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
        $short_pkg = $pkg; $short_pkg =~ s/.+::BorderStyle:://;
    } else {
        $self->log_debug(["skipped file %s (not a BorderStyle module)", $filename]);
        return;
    }

    local @INC = @INC;
    unshift @INC, 'lib';
    require $pkg_p;
    require Text::ANSITable;

    my $text = "Below are the border styles included in this package:\n\n";
    {
        no strict 'refs';
        my $border_styles = \%{"$pkg\::border_styles"};
        for my $style (sort keys %$border_styles) {
            my $spec = $border_styles->{$style};
            $text .= "=head2 $short_pkg\::$style\n\n";
            $text .= "$spec->{summary} " if $spec->{summary};
            $text .= join(
                "",
                "(utf8: ", ($spec->{utf8} ? "yes":"no"), ", ",
                "box_chars: ", ($spec->{box_chars} ? "yes":"no"),
                ").\n\n",
            );
            $text .= "$spec->{description}\n\n" if $spec->{description};
            next if $spec->{box_chars};
            # show sample table
            local $ENV{COLUMNS} = 80;
            my $t = Text::ANSITable->new(
                use_color => 0,
                use_utf8  => 1,
                use_box_chars => 0,
                columns   => [qw/column1 column2/],
            );
            $t->border_style("$short_pkg\::$style");
            $t->add_row(['row1.1', 'row1.2']);
            $t->add_row(['row2.1', 'row3.2']);
            $t->add_row_separator;
            $t->add_row(['row3.1', 'row3.2']);
            my $t_text = $t->draw;
            $t_text =~ s/^/ /gm;
            $text .= $t_text . "\n\n";
        }
    }

    $self->add_text_to_section($document, $text, 'BORDER STYLES');
}

no Moose;
1;
# ABSTRACT: Add a BORDER STYLES section for ANSITable BorderStyle module

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::BorderStyles::ANSITable - Add a BORDER STYLES section for ANSITable BorderStyle module

=head1 VERSION

This document describes version 0.03 of Pod::Weaver::Section::BorderStyles::ANSITable (from Perl distribution Pod-Weaver-Section-BorderStyles-ANSITable), released on 2015-04-01.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [BorderStyles::ANSITable]

=head1 DESCRIPTION

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-BorderStyles-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-BorderStyles-ANSITable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-BorderStyles-ANSITable>

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
