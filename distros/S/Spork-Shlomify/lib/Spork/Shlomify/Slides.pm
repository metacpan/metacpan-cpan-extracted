package Spork::Shlomify::Slides;

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

=head1 NAME

Spork::Shlomif::Slides - the slides generation class for Spork::Shlomify

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

