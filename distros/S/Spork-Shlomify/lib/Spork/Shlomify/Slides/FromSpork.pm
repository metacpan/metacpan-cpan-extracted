package Spork::Shlomify::Slides::FromSpork;
$Spork::Shlomify::Slides::FromSpork::VERSION = '0.0400';
use Spork -Base;
use mixin 'Spoon::Installer';
require CGI;

const class_id => 'slides';
field image_url => '';
field slide_heading => '';
field slide_index => [];
field 'first_slide';
field top_config => {};
field config => -init => '$self->hub->config';

sub make_slides {
    my @slides = $self->split_slides($self->config->slides_file);
    $self->first_slide($slides[0]);
    $self->config->add_config($slides[0]->{config});
    $self->top_config({$self->config->all});
    $self->make_start;
    for (my $i = 0; $i < @slides; $i++) {
        my $slide = $slides[$i];
        $self->config->add_config($slide->{config});
        my $content = $slides[$i]{slide_content};
        $slide->{first_slide} = $slides[0]->{slide_name};
        $slide->{prev_slide} = $i
          ? $self->make_link($slides[$i - 1]{slide_name}) : 'start.html';
        $slide->{next_slide} = $slides[$i + 1]
          ? $self->make_link($slides[$i + 1]{slide_name}) : '';
        $self->slide_heading('');
        $self->image_url('');
        my $parsed = $self->hub->formatter->text_to_parsed($content);
        my $html = $parsed->to_html;
        $slide->{slide_heading} = $self->slide_heading;
        $slide->{image_html} = $self->get_image_html;
        my $output = $self->hub->template->process('slide.html',
            %$slide,
            hub => $self->hub,
            index_slide => 'index.html',
            slide_content => $html,
            spork_version => "Spork v$Spork::VERSION",
        );
        my $file_name = $self->config->slides_directory . '/' .
                        $slide->{slide_name};
        io->file($file_name)->encoding($self->config->character_encoding)->assert->print($output);
        push @{$self->slide_index}, $slide
          if $slide->{slide_name} =~ /^slide\d+a?\.html$/;
    }
    $self->make_index;
}

sub make_link {
    my $link = shift;
    return $link unless $self->config->auto_scrolldown;
    return $link if $link =~ /^slide\d+a?\.html$/;
    return "$link#end";
}

sub make_index {
    my $output = $self->hub->template->process('index.html',
        %{$self->top_config},
        slides => $self->slide_index,
        spork_version => "Spork v$Spork::VERSION",
        next_slide => 'start.html',
    );
    my $file_name = $self->config->slides_directory . '/index.html';
    io->file($file_name)->encoding($self->config->character_encoding)->assert->print($output);
}

sub make_start {
    my $output = $self->hub->template->process('start.html',
        spork_version => "Spork v$Spork::VERSION",
        index_slide => 'index.html',
        next_slide => $self->first_slide->{slide_name},
    );
    io->file($self->start_name)->encoding($self->config->character_encoding)->assert->print($output);
}

sub start_name {
    $self->config->slides_directory . '/start.html';
}

sub split_slides {
    my $slides_file = shift;
    my @slide_info;
    my @slides = grep $_, split /^-{4,}\s*\n/m, io($slides_file)->slurp;
    my $slide_num = 1;
    my $config = {};
    for my $slide (@slides) {
        if ($slide =~ /\A(^(---|\w+\s*:.*|-\s+.*|#.*)\n)+\z/m) {
            $config = $self->hub->config->parse_yaml($slide);
            next;
        }
        my @sub_slides = $self->sub_slides($slide);
        my $sub_num = @sub_slides > 1 ? 'a' : '';
        while (@sub_slides) {
            my $sub_slide = shift @sub_slides;
            my $slide_info = {
                slide_num => $slide_num,
                slide_content => $sub_slide,
                slide_name => "slide$slide_num$sub_num.html",
                last => @sub_slides ? 0 : 1,
                config => $config,
                sub_num => $sub_num
            };
            $config = {};
            push @slide_info, $slide_info;
            $sub_num++;
        }
        $slide_num++;
    }
    return @slide_info;
}

sub sub_slides {
    my $raw_slide = shift;
    my (@slides, $slide);
    for (split /^\+/m, $raw_slide) {
        push @slides, $slide .= $_;
    }
    return @slides;
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
      qq{<img name="img" id="img" width="$image_width" src="images/$image_file" align=right>};
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

sub wget_download {
    my ($image_url, $image_file) = @_;
    system "wget $image_url 2> /dev/null";
}

sub curl_download {
    my ($image_url, $image_file) = @_;
    system "curl -o $image_file $image_url 2> /dev/null";
}

sub lwp_download {
    my ($image_url, $image_file) = @_;
    system "lwp-download $image_url > /dev/null";
}

=pod

=encoding UTF-8

=head1 VERSION

version 0.0400

=head1 AUTHOR

Shlomi Fish

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

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

  perldoc Spork::Shlomify::Slides::FromSpork

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

__DATA__

=head1 NAME

Spork::Slides - Slide Presentations (Only Really Kwiki)

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004, 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__Spork.slides__
----
presentation_topic: Spork
presentation_title: Spork - The Kwiki Way To Do Slideshows
presentation_place: Portland, Oregon
presentation_date: March 25nd, 2004
----
== What is Spork?
* Spork Stands for:
+** Slide Presentation (Only Really Kwiki)
+* Spork is an HTML Slideshow Generator
** All slides are in one simple file
** Run |spork -make| to make the slides
+* Spork is a CPAN Module
+* Spork is Based on Spoon
----
== Using Spork

Spork makes setting up a slide presentation very easy. Just follow these easy
steps:

* mkdir myslides
* cd myslides
* spork -new
* vim config.yaml Spork.slides
* spork -make
* spork -start
----
show_controls: 0
----
== Moving About
* To Advance Slide:
** Click /Next/ or Click Mouse or
** Hit /Enter/ or /ctl-n/ or /spacebar/
* To Move Backwards:
** Click /Previous/ or
** Hit /Delete/ or /ctl-p/
* Other Movements
** Starting Slide - /ctl-s/
** Index Slide - /ctl-i/
* Notice The Control Links Have Disappeared
----
== Creating Slides
Slides are all done in *Kwiki* markup language. Simple stuff.

* Example Slide:

    == Sample Slide
    My point is, it's as easy as:
    * One
    +* Two
    +* Three

Putting a plus (+) at the start of a line creates a subslide effect.
----
== Using Images
* Hey Look. A picture!
{image: http://search.cpan.org/s/img/cpan_banner.png}
+* Woah, it changed!
{image: http://cpan.org/misc/jpg/cpan.jpg}
+* Images are cached locally
----
== Linking to Files
* Often Times You Want to Show a File
* {file: ./Spork.slides This} is the Slide Show Text!
* Just Write a Line Like This

    * {file: ./Spork.slides This} is the Slide Show Text!

* {file: ./Spork.slides This} is the Slide Show Text!

* For Relative Paths, Set This in the |config.yaml|

    file_base: /Users/ingy/dev/cpan/Spork
----
banner_bgcolor: lightblue
----
== That's All

* The END
