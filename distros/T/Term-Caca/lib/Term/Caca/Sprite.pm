package Term::Caca::Sprite;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: an OO-interface to caca_sprite
$Term::Caca::Sprite::VERSION = '3.1.0';
use strict;
use warnings;
use Term::Caca;

sub new {
  my ($class, $file) = @_;
  my $self = Term::Caca::_load_sprite($file);
  return bless($self => $class);
}

*load = \*new;

sub get_frames {
  my ($self) = @_;
  return Term::Caca::_get_sprite_frames($self);
}

sub get_width {
  my ($self, $frame) = @_;
  return Term::Caca::_get_sprite_width($self, $frame);
}

sub get_height {
  my ($self, $frame) = @_;
  return Term::Caca::_get_sprite_height($self, $frame);
}

sub get_dx {
  my ($self, $frame) = @_;
  return Term::Caca::_get_sprite_dx($self, $frame);
}

sub get_dy {
  my ($self, $frame) = @_;
  return Term::Caca::_get_sprite_dy($self, $frame);
}

sub draw {
  my ($self, $x, $y, $frame) = @_;
  Term::Caca::_draw_sprite($x, $y, $self, $frame);
}

sub DESTROY {
  my ($self) = @_;
  Term::Caca::_free_sprite($self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Sprite - an OO-interface to caca_sprite

=head1 VERSION

version 3.1.0

=head1 SYNOPSIS

Basic usage

  use Term::Caca::Sprite;
  eval {
    my $sprite = Term::Caca::Sprite->new('/tmp/sprite.txt');
    my ($x, $y, $frame) = (8, 20, 0);
    $sprite->draw($x, $y, $frame);
  };
  # The destructor will take care of releasing memory.

=head1 DESCRIPTION

a brief summary of the module written with users in mind.

=head1 METHODS

=head2 new

...

B<Example>:

=head2 load

The load() method is a synonym for new() and they
can be used interchangably.

=head2 get_frames

...

B<Example>:

=head2 get_width

...

B<Example>:

=head2 get_height

...

B<Example>:

=head2 get_dx

...

B<Example>:

=head2 get_dy

...

B<Example>:

=head2 draw

...

B<Example>:

=head2 DESTROY

...

B<Example>:

=head1 CLASS VARIABLES

cvars

=head1 DIAGNOSTICS

no errors

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

__END__



# $Id$
