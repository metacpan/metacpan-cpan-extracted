package Spork::S5;
use Spork::Plugin -Base;
our $VERSION = '0.05';

const class_id => 's5';

sub register {
    my $r = shift;
    $r->add(hook => 'slides:make_slides', pre => 'slides_hook');
}

sub slides_hook {
    my $hook = pop;
    $self->hub->s5->make_s5_slides;
    $hook->cancel;
}

sub make_s5_slides {
    $self->hub->template->add_path(
        $self->config->slides_directory.'/template/s5'
    );
    my @allcontent;
    my @slides = $self->hub->slides->split_slides($self->config->slides_file);
    for (my $i = 0; $i < @slides; $i++) {
        my $slide = $slides[$i];
        $self->config->add_config($slide->{config});
        my $content = $slides[$i]{slide_content};
        $self->hub->slides->image_url('');
        my $parsed = $self->formatter->text_to_parsed($content);
        my $html = $parsed->to_html;
        $slide->{image_html} = $self->hub->slides->get_image_html;
        my $output = $self->template->process('slide.html',
            %$slide,
            hub => $self->hub,
            slide_content => $html,
        );
        push @allcontent,$output;
    }
    my $output = $self->template->process(
        's5.html',
        hub => $self->hub,
        slides => \@allcontent, 
    );
    io->catfile($self->config->slides_directory,'start.html')
      ->assert->print($output);
}

__DATA__

=head1 NAME

Spork::S5 - S5 Slide Presentations (Only Really Spork)

=head1 SYNOPSIS

Edit your C<config.yaml> or C<~/.sporkrc/config.yaml>, and put
this two lines:

    plugin_classes:
    - Spork::S5
    - Spork::S5Theme

If you have more plugin_classes installed just append C<Spork::S5>
and C<Spork::S5Theme> to the end. After this just use spork as
usual.  C<Spork::S5Theme> is the basic class for different s5 theme,
it also contains the default theme inside. You must also have one
s5 theme plugin along with C<Spork::S5> in plugin_classes, otherwise
"spork" would failed find "s5.html" template file and bombs out
error messages.

=head1 DESCRIPTION

S5 stands for a simple standards-based slide show system from Eric A
Meyer. L<http://www.meyerweb.com/eric/tools/s5/>.  It is a slide show
format based entirely on XHTML, CSS, and JavaScript. With one file,
you can run a complete slide show and have a printer-friendly version
as well. The markup used for the slides is very simple, highly
semantic, and completely accessible. Anyone with even a smidgen of
familiarity with HTML or XHTML can look at the markup and figure out
how to adapt it to their particular needs. Anyone familiar with CSS
can create their own slide show theme. It's totally simple, and it's
totally standards-driven.

C<Spork::S5> makes it simpler to create S5 slides (so that people
can use S5 themes) with Spork / Kwiki syntax.

=head1 SEE ALSO

L<Kwiki>,L<Spoon>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2005. Kang-min Liu. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
