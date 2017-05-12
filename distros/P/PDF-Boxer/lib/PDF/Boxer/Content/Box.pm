package PDF::Boxer::Content::Box;
{
  $PDF::Boxer::Content::Box::VERSION = '0.004';
}
use Moose;
# ABSTRACT: a box

use Scalar::Util qw/weaken/;

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );
has 'margin'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'border'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'padding'  => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'children'  => ( isa => 'ArrayRef', is => 'rw', default => sub{ [] } );

with 'PDF::Boxer::Role::SizePosition'; #, 'PDF::Boxer::Role::BoxDev';

has 'boxer' => ( isa => 'PDF::Boxer', is => 'ro' );
has 'parent'  => ( isa => 'Object', is => 'ro' );
has 'name' => ( isa => 'Str', is => 'ro' );
has 'type' => ( isa => 'Str', is => 'ro', default => 'Box' );
has 'background' => ( isa => 'Str', is => 'ro' );
has 'border_color' => ( isa => 'Str', is => 'ro' );
has 'font' => ( isa => 'Str', is => 'ro', default => 'Helvetica' );
has 'align' => ( isa => 'Str', is => 'ro', default => '' );
has 'valign' => ( isa => 'Str', is => 'ro', default => '' );


sub BUILDARGS{
  my ($class, $args) = @_;

  foreach my $attr (qw! margin border padding !){
    next unless exists $args->{$attr};
    my $arg = $args->{$attr};
    if (ref($arg)){
      unless (ref($arg) eq 'ARRAY'){
        die "Arg to $attr must be string or array reference";
      }
    } else {
      $arg = [split(/\s+/, $arg)];
    }
    my $val = [$arg->[0]];
    $val->[1] = defined $arg->[1] ? $arg->[1] : $val->[0];
    $val->[2] = defined $arg->[2] ? $arg->[2] : $val->[0];
    $val->[3] = defined $arg->[3] ? $arg->[3] : $val->[1];

    $args->{$attr} = $val;
  }

  return $args;
}

sub BUILD{
  my ($self) = @_;
  unless($self->parent){
    $self->adjust({
      margin_top => $self->boxer->max_height,
      margin_left => 0,
      margin_width => $self->boxer->max_width,
      margin_height => $self->boxer->max_height,
    },'self');
  }

  foreach my $child (@{$self->children}){
    $child->{boxer} = $self->boxer;
    $child->{debug} = $self->debug;
    $child->{font} ||= $self->font;
    $child->{align} ||= $self->align;
    my $weak_me = $self;
    weaken($weak_me);
    $child->{parent} = $weak_me;
    my $class = 'PDF::Boxer::Content::'.$child->{type};
    $child = $class->new($child);
    $self->boxer->register_box($child);
  }

}

sub propagate{
  my ($self, $method, $args) = @_;
  return unless $method;
  my @kids = @{$self->children};
  if (@kids){
    foreach my $kid (@kids){
      $kid->$method($args);
    }
  }
  return @kids;
}

# initialize objects with default sizes
#  - text gets width of widest line and height of all lines (wrapped at page width)
#  - images get their scaled size
#  - rows get the height of their tallest child and the width of all of them
#  - columns get the width of their widest child and the height of all of them
#  - grids (same as columns)
#  - box gets the width of all it's kids (wrapped at page width) and the height of the line of kids

# if text or box are too wide they need to be resized and they're contents re-wrapped.
# this may result in their height increasing which needs to be communicated to their parent.
# the parent can then adjust itself accordingly.


sub initialize{
  my ($self) = @_;

  my @kids = $self->propagate('initialize');

  $self->update unless $self->parent;

  # the main box should stay wide open.
  return unless $self->parent;

  my ($width, $height) = $self->get_default_size;

  $self->set_width($width);
  $self->set_height($height);

  return 1;
}


# we get our size from the children
sub get_default_size{
  my ($self) = @_;
  my ($width, $height) = (0,0);
  my $kids = $self->children;
  if (@$kids){
    my ($widest, $highest, $x, $y) = (0, 0, 0); 
    foreach(@$kids){
      $highest = $_->margin_height if $_->margin_height > $highest;
      if ($width + $_->margin_width > $self->boxer->max_width){
        $height += $highest;
        $highest = 0;
        $widest = $width if $width > $widest;
      } else {
        $width += $_->margin_width;
      }
      $width = $width ? (sort($_->margin_width,$width))[1] : $_->margin_width;
    }
    $height += $highest;
  }
  return ($width, $height);
}

sub update{
  my ($self) = @_;
  $self->update_children;
  return 1;
}

sub child_adjusted_height{}

sub update_children{
  my ($self) = @_;
  if ($self->position_set){
    my $kids = $self->children;
    if (@$kids){
      my ($highest, $x, $y) = (0, $self->content_left, $self->content_top); 
      foreach my $kid (@$kids){
        $highest = $kid->margin_height if $kid->margin_height > $highest;
        if ($x + $kid->margin_width > $self->width){
          $kid->move($x,$y);
          $y -= $highest;
          $highest = 0;
          $x = $self->content_left;
        } else {
          $kid->move($x,$y);
          $x += $kid->margin_width;
        }
      }
    }
  }
}

sub render{
  my ($self) = @_;

  my $gfx = $self->boxer->doc->gfx;

  if ($self->background){
    $gfx->fillcolor($self->background);
    $gfx->rect($self->border_left, $self->border_top, $self->border_width, -$self->border_height);
    $gfx->fill;
  }

  if ($self->border){

    my $left = $self->border_left;
    my $top = $self->border_top;
    my $right = $left + $self->border_width;
    my $bottom = $top - $self->border_height;

    $gfx->strokecolor($self->border_color || 'black');

    if ($self->border->[0]){
      $gfx->linewidth($self->border->[0]);
      $gfx->move($left, $top);
      $gfx->line($right, $top);
      $gfx->stroke;
    }

    if ($self->border->[1]){
      $gfx->linewidth($self->border->[1]);
      $gfx->move($right, $top);
      $gfx->line($right, $bottom);
      $gfx->stroke;
    }

    if ($self->border->[2]){
      $gfx->linewidth($self->border->[2]);
      $gfx->move($right, $bottom);
      $gfx->line($left, $bottom);
      $gfx->stroke;
    }

    if ($self->border->[3]){
      $gfx->linewidth($self->border->[3]);
      $gfx->move($left, $bottom);
      $gfx->line($left, $top);
      $gfx->stroke;
    }
  }

  if ($self->debug && $self->name && 
       ( $self->name eq 'Head'
         || $self->name eq 'Header' 
         || $self->name eq 'Details' 
         || $self->name eq 'ContentGrid' )){
    warn "Name: ".$self->name."\n";
    warn sprintf "Top: %s\tRight: %s\tBottom: %s\tLeft: %s\n",
      $self->margin_top, $self->margin_right, $self->margin_bottom, $self->margin_left;
  }

  foreach(@{$self->children}){
    $_->render;
  }

}


__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

PDF::Boxer::Content::Box - a box

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 debug

set true to turn on debugging

=head2 margin

Arrayref containing the size of the margin on each side of the box.
(top, right, bottom, left)

=head2 border

Arrayref containing the size of the border on each side of the box.
(top, right, bottom, left)

=head2 padding

Arrayref containing the size of the padding on each side of the box.
(top, right, bottom, left)

=head2 children

Arrayref of boxes contained in this box.

=head2 boxer

the Boxer object.

=head2 parent

The box we are in.

=head2 name

The name of this box. Access boxes through the box register using this.

=head2 type

The type of this box. eg text, row, column

=head2 background

The background color of this box. (hex string or name)

=head2 border_color

The border color of this box. (hex string or name)

=head2 font

Non-text boxes will pass this to their children.

=head2 align

The alignment of this box (text string; right or center)
No align means left.

=head2 valign

The vertical alignment of this box (text string; bottom or center)
No align means top.

=head1 METHODS

=head2 initialize

Set the width & height for the box and call initialize on children

=head2 get_default_size

Returns the default width and height for this box.

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

