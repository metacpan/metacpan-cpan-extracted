package Statocles::Plugin::VideoTag;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Change video file anchors to video elements

our $VERSION = '0.0200';

use Statocles::Base 'Class';
with 'Statocles::Plugin';


has file_type => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'mp4' },
);


sub video_tag {
    my ($self, $page) = @_;
    if ($page->has_dom) {
        if ($self->file_type eq 'youtu') {
            $page->dom->find('a[href*="'. $self->file_type .'"]')->each(sub {
                my ($el) = @_;
                my $href = $el->attr('href');
                $href =~ s/watch\?v=(.+)$/embed\/$1/;
                my $replacement = sprintf '<iframe width="560" height="315" src="%s" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>',
                    $href;
                $el->replace($replacement);
            });
        }
        else {
            $page->dom->find('a[href$=.'. $self->file_type .']')->each(sub {
                my ($el) = @_;
                my $replacement = sprintf '<video controls><source type="video/%s" src="%s"></video>',
                    $self->file_type, $el->attr('href');
                $el->replace($replacement);
            });
        }
    }
    return $page;
}


sub register {
    my ($self, $site) = @_;
    $site->on(build => sub {
        my ($event) = @_;
        for my $page (@{ $event->pages }) {
            $page = $self->video_tag($page);
        }
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Plugin::VideoTag - Change video file anchors to video elements

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

  # site.yml
  site:
    class: Statocles::Site
    args:
        plugins:
            video_tag:
                $class: Statocles::Plugin::VideoTag
                $args:
                     file_type: 'youtu'

=head1 DESCRIPTION

C<Statocles::Plugin::VideoTag> changes video file anchor elements to
video elements.

=head1 ATTRIBUTES

=head2 file_type

The file type to replace.

Default: C<mp4>

=head1 METHODS

=head2 video_tag

  $page = $plugin->video_tag($page);

Process the video bits of a L<Statocles::Page>.

If the B<file_type> is given as C<youtu>, YouTube links of this exact
form will be converted to an embedded iframe:

  https://www.youtube.com/watch?v=abcdefg1234567

Where the C<abcdefg1234567> is a placeholder for the actual video.

* Currently, including a start time (e.g. C<&t=42>) in the link is not
honored.  In fact including any argument other than C<v> will not
render the embedded video correctly at this time...

=head2 register

Register this plugin to install its event handlers. Called automatically.

=head1 SEE ALSO

L<Statocles>

L<Statocles::Plugin>

L<Statocles::Plugin::AudioTag>

L<https://ology.github.io/2020/12/06/making-a-statocles-plugin/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
