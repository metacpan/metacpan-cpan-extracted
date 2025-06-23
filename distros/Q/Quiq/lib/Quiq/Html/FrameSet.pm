# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::FrameSet - HTML-Frameset

=head1 BASE CLASS

L<Quiq::Html::Base>

=head1 SYNOPSIS

  use Quiq::Html::FrameSet;
  
  $h = Quiq::Html::Producer->new;
  
  $obj = Quiq::Html::FrameSet->new(
      comment => $comment,
      frames => [{
              size => $size,
              title => $title,
              url => $url,
          },
          ...
      ],
      orientation => $orientation,
      title => $title,
  );
  
  $html = $obj->html($h);

=head1 ATTRIBUTES

=over 4

=item comment => $comment (Default: undef))

]:
Kommentar am Anfang der Frameset-Seite.

=item frames => \@frames (Default: [])

Liste der Frameset-Zeilen bzw. -Kolumnen. Ein Element besitzt
folgende Attribute:

=item orientation => $orientation (Default: 'v'

Ob die Frames in Zeilen (orientation => 'v') oder Kolumnen

  (orientation => 'h') angeordnet werden sollen.
  
  [name => $name (Default: '')]:
      Bezeichnung des Frames..
  
  [size => $size]:
     Die Höhe bzw. Breite $size des Frames in Pixeln (Integer),
     in Prozent ('N%') oder variabel ('*').
  
  [url => $url]:
      Der URL $url der Seite, die initial in den Frame geladen wird.

=item title => $title (Default: '')

Titel der Frameset-Seite.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::FrameSet;
use base qw/Quiq::Html::Base/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $obj = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        border => 1,
        comment => undef,
        frames => [],
        orientation => 'v',
        title => '',
    );
    $self->set(@_);

    # Mache aus den Frame-Hashes Objekte mit den vorgegebenen Attributen

    for (@{$self->frames}) {
        $_ = Quiq::Hash->new($_,
            name => undef,
            size => undef,
            url => undef,
        );
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $obj->html($h);
  $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($border,$comment,$frameA,$orientation,$title) =
        $self->get(qw/border comment frames orientation title/);

    my $html = $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,$comment),
        $h->tag('html',
            '-',
            $h->tag('head',
                '-',
                $h->tag('title',
                    -ignoreIf => !$title,
                    '-',
                    $title,
                ),
            ),
            $h->tag('frameset',
                border => $border,
                ($orientation eq 'v'? 'rows': 'cols') =>
                    join(',',map {$_->size} @$frameA),
                '-',
                do {
                    my @arr;
                    for (@$frameA) {
                        push @arr,$h->tag('frame',
                            name => $_->name,
                            src => $_->url,
                        );
                    }
                    @arr;
                },
            ),
        ),
    );

    return $html;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
