package Spork::Slides::TKSlide;
use strict;
use Spork::Slides '-Base';

our $VERSION = '0.03';

const class_id => 'slides';

sub make_slides {
    $self->use_class('formatter');
    $self->use_class('template');

    my @slides = $self->split_slides($self->config->slides_file);

    my $allpage_html;
    for (my $i = 0; $i < @slides; $i++) {
        my $slide = $slides[$i];
        $self->config->add_config($slide->{config});
        my $content = $slides[$i]{slide_content};
        $self->slide_heading('');
        $self->image_url('');
        my $parsed = $self->formatter->text_to_parsed($content);
        my $html = $parsed->to_html;
        $slide->{slide_heading} = $self->slide_heading;
        $slide->{image_html} = $self->get_image_html;
        my $output = $self->template->process('slide.html',
            %$slide,
            slide_content => $html,
            spork_version => "Spork v$Spork::VERSION",
        );
	$allpage_html .= $output;
    }
    my $output = $self->template
	->process('start.html',
		  style_file => $self->config->style_file,
		  allpage_content => $allpage_html,
		  spork_version => "Spork v$Spork::VERSION",
		 );
    my $file_name = $self->config->slides_directory . '/start.html';
    $output > io($file_name)->assert;
    $self->make_style;
    $self->make_javascript;
}

sub make_style {
    for ('slide-zen.css', 'slide.css', 'slide-tkirby.css') {
        $self->make_file($_);
    }
}

sub make_javascript {
    $self->make_file('controls.js');
}

sub make_file {
    my ($template,$file) = @_;
    $file ||= $template;
    my $output = $self->template
	->process($template,
		  spork_version => "Spork v$Spork::VERSION",
		 );
    my $file_name = $self->config->slides_directory . "/$file";
    $output > io($file_name)->assert;
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
	while(@sub_slides) {
	    my $sub_slide = shift @sub_slides;
	    my $slide_info =
		{
		    slide_num => $slide_num,
		    slide_content => $sub_slide,
		    slide_name => "page$slide_num",
		    config => $config,
		};
	    $config = {};
	    push @slide_info, $slide_info;
	    $slide_num++;
	}
    }
    return @slide_info;
}


1;
__DATA__
__Spork.slides__
----
presentation_topic: Spork:TKSlide
presentation_title: Spork:TKSlide Generate TKSlide with Spork.
presentation_place: NO
presentation_date: NO
----
{image: http://gugod.org/imgs/spork/SporkCollection.jpg}
== What is Spork?
* Spork Stands for:
+** Slide Presentation (Only Really Kwiki)
+* Spork is a CPAN Module
+* Spork is Based on Spoon
+* Spork is an HTML Slideshow Generator
+** All slides are in one simple file
+** Run |spork -make| to make the slides
----
{image: http://gugod.org/imgs/kirby/kirby.jpg}
== What is TKSlide?
* TKSlide stands for:
+** Tkirby's slides
+* Pure JavaScript navigation
+* XML / HTML backend
+* Cross Browser
+* http://www.csie.ntu.edu.tw/~b88039/slide/
----
== Spork::TKSlide
* Use Spork/Kwiki syntax
+** Thats easy
+* Generate the tkslide effect
+** That's cool.
+* So, That's *POWERFUL*
{image: http://gugod.org/imgs/powerful/upside-down.jpg}
+* Check the source code of this slide:
** http://gugod.org/Slides/Spork-TKSlide/Spork.slides
----
= ToDo
{image: http://gugod.org/imgs/spork/SporkCollection.jpg}
+* To Support TKSlide in a better way
+** TKSlides has very fancy hide() which is currently useless.
----
== That's All

{image: http://gugod.org/imgs/thank-you/thank-you.gif}

* The END
