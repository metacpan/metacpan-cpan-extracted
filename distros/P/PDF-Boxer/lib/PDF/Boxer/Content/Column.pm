package PDF::Boxer::Content::Column;
{
  $PDF::Boxer::Content::Column::VERSION = '0.004';
}
use Moose;
# ABSTRACT: a box of boxes stack one above the other

use namespace::autoclean;
use Scalar::Util qw!weaken!;

extends 'PDF::Boxer::Content::Box';

sub get_default_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $height+= $_->margin_height;
    $width = $width ? (sort { $b <=> $a } ($_->margin_width,$width))[0] : $_->margin_width;
  }
  return ($width, $height);
}

sub update_children{
  my ($self) = @_;
  $self->update_kids_size     if $self->size_set;
  $self->update_kids_position if $self->position_set;
  foreach my $kid (@{$self->children}){
    $kid->update;
  }
  return 1;
}

sub update_kids_size{
  my ($self) = @_;
  my ($kids_width, $kids_height) = $self->get_default_size;
  my $kids = $self->children;
  if (@$kids){
    my $space = $self->height - $kids_height;
    my ($has_grow,$grow,$grow_all);
    my $space_each = 0;
    foreach my $kid (@$kids){
      $has_grow++ if $kid->grow;
    }
    $space_each = int($space/$has_grow) if $has_grow;

    my $kwidth = $self->content_width;

    foreach my $kid (@$kids){
      my $kheight = $kid->margin_height;
      if ($grow_all || $kid->grow){
        $kheight += $space_each;
      }
      $kid->set_margin_size($kwidth, $kheight);
    }

  }
}

sub update_kids_position{
  my ($self) = @_;
  my $kids = $self->children;

  if (@$kids){
    my $top = $self->content_top;
    my $left = $self->content_left;
    foreach my $kid (@$kids){
      $kid->move($left, $top);
      $top -= $kid->margin_height;
    }
  }

}

sub child_adjusted_height{
  my ($self, $child) = @_;
  weaken($child) if $child;
  $self->update_kids_position;
  unless($self->grow){
    my $kid = $self->children->[-1];
    my $kid_mb = $kid->margin_bottom;
    if ($self->content_bottom != $kid_mb){
      my $height = $self->margin_height + $self->content_bottom - $kid_mb;
      if ($height > $self->boxer->max_height){
        $self->update_kids_size;
      } else {
        $self->set_margin_height($height);
        $self->parent->child_adjusted_height($self) if $self->parent;
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

PDF::Boxer::Content::Column - a box of boxes stack one above the other

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

