package PDF::Boxer::Content::Row;
{
  $PDF::Boxer::Content::Row::VERSION = '0.004';
}
use Moose;
# ABSTRACT: a box of boxes laid out side by side

use namespace::autoclean;
use Scalar::Util qw!weaken!;

extends 'PDF::Boxer::Content::Box';

sub get_default_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $width += $_->margin_width;
    $height = $height ? (sort { $b <=> $a } ($_->margin_height,$height))[0] : $_->margin_height;
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

sub update_kids_position{
  my ($self, $args) = @_;

  my $kids = $self->children;

  if (@$kids){

    my $top = $self->content_top;
    my $left = $self->content_left;

    foreach my $kid (@$kids){
      $kid->move($left, $top);
      $left += $kid->margin_width;
    }
  }

  return 1; 
}

sub update_kids_size{
  my ($self, $args) = @_;

  my $kids = $self->children;

  my ($kids_width, $kids_height) = $self->get_default_size;

  if (@$kids){
    my $space = $self->width - $kids_width;
    my ($has_grow,$grow,$grow_all);
    my $space_each = 0;
    foreach my $kid (@$kids){
      $has_grow++ if $kid->grow;
    }
    if (!$has_grow){
      $grow_all = 1;
      $has_grow = @$kids;
    }
    $space_each = int($space/$has_grow);

    my $kheight = $self->content_height;

    foreach my $kid (@$kids){
      my $kwidth = $kid->margin_width;
      if ($grow_all || $kid->grow){
        $kwidth += $space_each;
      }
      $kid->set_margin_size($kwidth, $kheight);
    }
  }

  return 1; 
}

sub set_kids_minimum_width{
  my ($self, $args) = @_;
  my $kids = $self->children;
  if ($args->{min_widths} && @{$args->{min_widths}}){
    if (@$kids){
      my @widths = @{$args->{min_widths}};
      foreach my $kid (@$kids){
        my $width = shift @widths;
        $kid->set_margin_width($width);
      }
    }
  }
}


sub child_adjusted_height{
  my ($self, $child) = @_;
  weaken($child) if $child;
  my $low = 5000;
  foreach(@{$self->children}){
    $low = $_->margin_bottom if defined $_->margin_bottom && $_->margin_bottom < $low;
  }
  if ($self->content_bottom != $low){
    my $height = $self->margin_height + $self->content_bottom - $low;
    $self->set_height($height);
    $self->parent->child_adjusted_height($self);
  }
}

__PACKAGE__->meta->make_immutable;

1;




__END__
=pod

=head1 NAME

PDF::Boxer::Content::Row - a box of boxes laid out side by side

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

