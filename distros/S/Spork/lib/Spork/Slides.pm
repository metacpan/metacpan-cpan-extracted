package Spork::Slides;
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
        $output > io($file_name)->assert;
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
    $output > io($file_name)->assert;
}

sub make_start {
    my $output = $self->hub->template->process('start.html',
        spork_version => "Spork v$Spork::VERSION",
        index_slide => 'index.html',
        next_slide => $self->first_slide->{slide_name},
    );
    $output > io($self->start_name)->assert;
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

__DATA__

=head1 NAME

Spork::Slides - Slide Presentations (Only Really Kwiki)

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
