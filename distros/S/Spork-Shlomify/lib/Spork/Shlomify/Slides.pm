package Spork::Shlomify::Slides;
$Spork::Shlomify::Slides::VERSION = '0.0204';
use strict;
use warnings;
use Spork;

use Spork::Slides -Base;

sub make_css_file {
    my $output = $self->hub->template->process('slide.css',
        %{$self->top_config},
        slides => $self->slide_index,
        spork_version => "Spork v$Spork::VERSION",
        next_slide => 'start.html',
    );
    my $file_name = $self->config->slides_directory . '/slide.css';
    $output > io($file_name)->assert;
}

sub make_slides {
    $self->SUPER::make_slides();
    $self->make_css_file();
}

sub get_image_html {
    my $image_url = $self->image_url
      or return '';
    my $image_width;
    ($image_url, $image_width) = split /\s+/, $image_url;
    $image_width ||= $self->config->image_width;
    my $image_file = $image_url;
    $image_file =~ s/.*\///;
    my $images_directory = $self->config->slides_directory . '/images';
    io->dir($images_directory)->assert->open;
    my $image_html =
      qq{<img src="images/$image_file" alt="myimage" />};
    return $image_html if -f "$images_directory/$image_file";
    require Cwd;
    my $home = Cwd::cwd();
    chdir($images_directory) or die;
    my $method = $self->config->download_method . '_download';
    warn "- Downloading $image_url\n";
    $self->$method($image_url, $image_file);
    chdir($home) or die;
    return -f "$images_directory/$image_file" ? $image_html : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spork::Shlomif::Slides - the slides generation class for Spork::Shlomify

=head1 VERSION

version 0.0204

=head1 VERSION

version 0.0204

=head1 FUNCTIONS

=head2 $self->make_slides()

Overrides Spork's make_slides to generate a slide.css file.

=head2 $self->make_css_file()

Generates the CSS file.

=head2 $self->get_image_html()

Generates the HTML Image - conforms to XHTML 1.1.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 LICENSE

MIT X11 License.

=head1 SEE ALSO

L<Spork::Shlomify>

=head1 AUTHOR

Shlomi Fish

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Spork-Shlomify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Spork::Shlomify::Slides

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Spork-Shlomify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Spork-Shlomify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Spork-Shlomify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Spork-Shlomify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Spork-Shlomify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Spork-Shlomify>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/Spork-Shlomify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Spork-Shlomify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Spork::Shlomify>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-spork-shlomify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Spork-Shlomify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Spork-Shlomify>

  git clone http://github.com/shlomif/perl-Spork-Shlomify

=cut
