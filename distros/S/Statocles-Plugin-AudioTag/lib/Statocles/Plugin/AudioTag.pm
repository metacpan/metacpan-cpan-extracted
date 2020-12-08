package Statocles::Plugin::AudioTag;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Change audio file anchors to audio elements

our $VERSION = '0.0204';

use Statocles::Base 'Class';
with 'Statocles::Plugin';


has file_type => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'mp3' },
);


sub audio_tag {
    my ($self, $page) = @_;
    if ($page->has_dom) {
        $page->dom->find('a[href$=.'. $self->file_type .']')->each(sub {
            my ($el) = @_;
            my $replacement = sprintf '<audio controls><source type="audio/%s" src="%s"></audio>',
                $self->file_type, $el->attr('href');
            $el->replace($replacement);
        });
    }
    return $page;
}


sub register {
    my ($self, $site) = @_;
    $site->on(build => sub {
        my ($event) = @_;
        for my $page (@{ $event->pages }) {
            $page = $self->audio_tag($page);
        }
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Plugin::AudioTag - Change audio file anchors to audio elements

=head1 VERSION

version 0.0204

=head1 SYNOPSIS

  # site.yml
  site:
    class: Statocles::Site
    args:
        plugins:
            audio_tag:
                $class: Statocles::Plugin::AudioTag
                $args:
                     file_type: 'ogg'

=head1 DESCRIPTION

C<Statocles::Plugin::AudioTag> changes audio file anchor elements to
audio elements.

=head1 ATTRIBUTES

=head2 file_type

The file type to replace.

Default: C<mp3>

=head1 METHODS

=head2 audio_tag

  $page = $plugin->audio_tag($page);

Process the audio bits of a L<Statocles::Page>.

=head2 register

Register this plugin to install its event handlers. Called automatically.

=head1 SEE ALSO

L<Statocles>

L<Statocles::Plugin>

L<https://ology.github.io/2020/12/06/making-a-statocles-plugin/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
