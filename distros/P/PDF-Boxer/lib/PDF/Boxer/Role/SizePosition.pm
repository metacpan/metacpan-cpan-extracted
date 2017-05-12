package PDF::Boxer::Role::SizePosition;
{
  $PDF::Boxer::Role::SizePosition::VERSION = '0.004';
}
use Moose::Role;
# ABSTRACT: size and position stuff

use Carp qw(carp croak confess cluck);

requires qw!margin border padding children!;

has 'max_width' => ( isa => 'Int', is => 'rw' );
has 'max_height' => ( isa => 'Int', is => 'rw' );

has 'width' => ( isa => 'Maybe[Int]', is => 'rw', lazy_build => 1, );
has 'height' => ( isa => 'Maybe[Int]', is => 'rw', lazy_build => 1, );

has 'margin_left' => ( isa => 'Maybe[Int]', is => 'rw', lazy_build => 1 );
has 'margin_top'  => ( isa => 'Maybe[Int]', is => 'rw', lazy_build => 1 );

has 'margin_right' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'margin_bottom'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'border_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'content_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'content_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'content_right' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'content_bottom'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'margin_width'    => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'margin_height'   => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'border_width'    => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'padding_width'    => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'padding_height'   => ( isa => 'Int', is => 'rw', lazy_build => 1 );


has 'grow' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'attribute_rels' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );

sub _build_attribute_rels{
  return {
    max_width      => [qw! margin_right content_right margin_width border_width padding_width !],
    max_height     => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    width          => [qw! margin_right content_right margin_width border_width padding_width !],
    height         => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    margin_left    => [qw! margin_right border_left padding_left content_left !],
    margin_top     => [qw! margin_bottom border_top padding_top content_top content_bottom !],
    margin_right   => [qw! margin_left border_left padding_left content_left content_right !],
    margin_bottom  => [qw! margin_top border_top padding_top content_top content_bottom !],
    margin_width   => [qw! width margin_right content_right border_width padding_width !],
    margin_height  => [qw! height margin_bottom content_bottom border_height padding_height !],
  }
}


sub adjust{
  my ($self, $spec, $sender) = @_;

  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
    foreach ( @{$self->attribute_rels->{$attr}} ){
      next if $spec->{$_}; # don't clear anything which is in the spec
      my $clear = 'clear_'.$_;
      $self->$clear();
    }
  }

}

sub move{
  my ($self, $x, $y) = @_;
  return if 
    ($self->margin_left && $self->margin_left == $x)
    && ($self->margin_top && $self->margin_top == $y);
  warn $self->name." move $x, $y from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ margin_left => $x, margin_top => $y });
}

sub set_width{
  my ($self, $arg) = @_;
  return if $self->width && $self->width == $arg;
  warn $self->name." set width $arg from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ width => $arg });
}

sub set_margin_width{
  my ($self, $arg) = @_;
  return if $self->margin_width && $self->margin_width == $arg;
  warn $self->name." set margin_width $arg from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ margin_width => $arg });
}

sub set_height{
  my ($self, $arg) = @_;
  return if $self->height && $self->height == $arg;
  warn $self->name." set height $arg from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ height => $arg });
}

sub set_margin_height{
  my ($self, $arg) = @_;
  return if $self->margin_height && $self->margin_height == $arg;
  warn $self->name." set margin_height $arg from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ margin_height => $arg });
}

sub set_size{
  my ($self, $x, $y) = @_;
  return if 
    ($self->width && $self->width == $x)
    && ($self->height && $self->height == $y);
  warn $self->name." size $x, $y from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ width => $x, height => $y });
}

sub set_margin_size{
  my ($self, $x, $y) = @_;
  return if $self->margin_width == $x && $self->margin_height == $y;
  warn $self->name." size $x, $y from ".join('-',(caller)[0,2])."\n" if $self->debug && $self->name;
  $self->adjust({ margin_width => $x, margin_height => $y });
}

sub child_height_set{};
sub child_width_set{};

sub position_set{
  my ($self) = @_;
  return 1 if ($self->has_margin_left || $self->has_margin_right)
           && ($self->has_margin_top || $self->has_margin_bottom);
}

sub size_set{
  my ($self) = @_;
  return 1 if ($self->has_margin_width || $self->has_width)
           && ($self->has_margin_height || $self->has_height);
}

sub _build_margin_left{
  my ($self) = @_;
  if ($self->has_content_left){
    return $self->content_left - $self->padding->[3] - $self->border->[3] - $self->margin->[3];
  } elsif ($self->has_margin_right && $self->has_margin_width){
    return $self->margin_right - $self->margin_width;
  } elsif ($self->has_content_right && $self->has_content_width){
    return $self->content_right - $self->content_width;
  }
  return;
}

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
}

sub _build_margin_top{
  my ($self) = @_;
  if ($self->has_content_top){
    return $self->content_top + $self->padding->[0] + $self->border->[0] + $self->margin->[0];
  } elsif ($self->has_margin_bottom && $self->has_margin_height){
    return $self->margin_bottom - $self->margin_height;
  } elsif ($self->has_content_bottom && $self->has_content_height){
    return $self->content_bottom - $self->content_height;
  }
  return;
}

sub _build_margin_bottom{
  my ($self) = @_;
  return $self->margin_top - $self->margin_height;
}

sub _build_border_left{
  my ($self) = @_;
  return $self->margin_left + $self->margin->[3];
}

sub _build_border_top{
  my ($self) = @_;
  return $self->margin_top - $self->margin->[0];
}

sub _build_padding_left{
  my ($self) = @_;
  return $self->border_left + $self->border->[3];
}

sub _build_padding_top{
  my ($self) = @_;
  return $self->border_top - $self->border->[0];
}

sub _build_content_left{
  my ($self) = @_;
  return $self->padding_left + $self->padding->[3];
}

sub _build_content_top{
  my ($self) = @_;
  return $self->padding_top - $self->padding->[0];
}

sub _build_content_right{
  my ($self) = @_;
  return $self->content_left + $self->width;
}

sub _build_content_bottom{
  my ($self) = @_;
  return $self->content_top - $self->height;
}

sub _build_width{
  my ($self) = @_;
  if ($self->has_margin_width){
    return $self->margin_width - (
      $self->padding->[3] + $self->padding->[1]
      + $self->border->[3] + $self->border->[1]
      + $self->margin->[3] + $self->margin->[1]
    );
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left - (
      $self->padding->[3] + $self->padding->[1] 
      + $self->border->[3] + $self->border->[1] 
      + $self->margin->[3] + $self->margin->[1]
    );
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  return;
}

sub _build_height{
  my ($self) = @_;
  if ($self->has_margin_height){
    return $self->margin_height - (
      $self->padding->[0] + $self->padding->[2]
      + $self->border->[0] + $self->border->[2] 
      + $self->margin->[0] + $self->margin->[2]
    );
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left - (
      $self->padding->[0] + $self->padding->[2]
      + $self->border->[0] + $self->border->[2] 
      + $self->margin->[0] + $self->margin->[2]
    );
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  return;
}

sub content_width{ shift->width(@_) }
sub content_height{ shift->height(@_) }

sub _build_padding_width{
  my ($self) = @_;
  return $self->width + $self->padding->[1] + $self->padding->[3];
}

sub _build_padding_height{
  my ($self) = @_;
  return $self->height + $self->padding->[0] + $self->padding->[2];
}

sub _build_border_width{
  my ($self) = @_;
  return $self->padding_width + $self->border->[1] + $self->border->[3];
}

sub _build_border_height{
  my ($self) = @_;
  return $self->padding_height + $self->border->[0] + $self->border->[2];
}

sub _build_margin_width{
  my ($self) = @_;
  return $self->border_width + $self->margin->[1] + $self->margin->[3];
}

sub _build_margin_height{
  my ($self) = @_;
  return $self->border_height + $self->margin->[0] + $self->margin->[2];
}


1;



__END__
=pod

=head1 NAME

PDF::Boxer::Role::SizePosition - size and position stuff

=head1 VERSION

version 0.004

=item adjust

takes values for any of the predefined size and location attributes.
Decides what to do about it..

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

