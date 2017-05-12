package Spork::Config::TKSlide;
use strict;

use Spork::Config '-base';
our $VERSION = '0.01';

const class_id => 'config';

sub default_configs {
    my $self = shift;
    my @configs;
    push @configs, "$ENV{HOME}/.sporkrc/config.yaml"
      if defined $ENV{HOME} and -f "$ENV{HOME}/.sporkrc/config.yaml";
    push @configs, "config.yaml"
      if -f "config.yaml";
    return @configs;
}

sub default_config {
    {
        config_class => 'Spork::Config::TKSlide',
        hub_class => 'Spork::Hub',
        formatter_class => 'Spork::Formatter::TKSlide',
        template_class => 'Spork::Template::TKSlide',
        command_class => 'Spork::Command',
        slides_class => 'Spork::Slides::TKSlide',
        slides_file => 'Spork.slides',
        template_directory => 'template/tkslide',
        template_path => [ 'template/tkslide' ],
	style_file => 'slide.css'
    }
}

1;

=head1 NAME

Spork::Config - Spork Configuration Class

=head1 SETTINGS

To use TKSlide as Spork front end, add the following
setting into your ~/.sporkrc/config.yaml :

  config_class: Spork::Config::TKSlide
  template_class: Spork::Template::TKSlide
  formatter_class: Spork::Formatter::TKSlide
  slides_class: Spork::Slides::TKSlide

And use spork as usual.

=head1 EXTRA OPTIONS

Here's a list of additional config options:

=over 4

=item style_file

The css file under template path that is used.
By default, it is "slide.css", and you may choose
to use "slide-zen.css", which looks like csszen-garden
layout. Or you can write your own one, just save it
under templtae/tkslide.

=back

=head1 SEE ALSO

L<Spork>, L<Spork::Config>

=cut

__DATA__
__config.yaml__
################################################################################
# See C<perldoc Spork::Config> for details on settings.
################################################################################
author_name: Kang-min Liu
author_email: gugod@gugod.org
author_webpage: http://gugod.org/
copyright_string: Copyright &copy; 2004 Kang-min Liu

banner_bgcolor: hotpink
show_controls: 1
image_width: 350
auto_scrolldown: 1
logo_image: logo.png
file_base: .

slides_file: Spork.slides
template_directory: template/tkslide
template_path:
- ./template/tkslide
slides_directory: slides
download_method: wget
character_encoding: utf-8
link_previous: &lt; &lt; Previous
link_next: Next &gt;&gt;
link_index: Index

start_command: open slides/start.html

template_class: Spork::Template::TKSlide
formatter_class: Spork::Formatter::TKSlide
slides_class: Spork::Slides::TKSlide
config_class: Spork::Config::TKSlide

style_file: slide.css

