package Rose::HTML::Object::WithWrapAroundChildren;

use strict;

use Carp;

our $VERSION = '0.554';

use Rose::HTML::Object::MakeMethods::Generic
(
  array =>
  [
    'pre_children'          => {},
    'shift_pre_children'    => { interface => 'shift', hash_key => 'pre_children' },
    'unshift_pre_children'  => { interface => 'unshift', hash_key => 'pre_children' },
    'pop_pre_children'      => { interface => 'pop', hash_key => 'pre_children' },
    'push_pre_children'     => { interface => 'push', hash_key => 'pre_children' },
    'delete_pre_children'   => { interface => 'clear', hash_key => 'pre_children' },

    'post_children'         => {},
    'shift_post_children'   => { interface => 'shift', hash_key => 'post_children' },
    'unshift_post_children' => { interface => 'unshift', hash_key => 'post_children' },
    'push_post_children'    => { interface => 'push', hash_key => 'post_children' },
    'pop_post_children'     => { interface => 'pop', hash_key => 'post_children' },
    'delete_post_children'  => { interface => 'clear', hash_key => 'post_children' },
  ],
);

sub children 
{
  my($self) = shift;
  Carp::croak "Cannot directly set children() for a ", ref($self), 
              ".  Use fields(), push_children(), pop_children(), etc."  if(@_);
  return wantarray ? ($self->pre_children, $self->immutable_children(), $self->post_children) : 
                     [ $self->pre_children, $self->immutable_children(), $self->post_children ];
}

sub push_children { shift->push_post_children(@_) }

sub pop_children 
{
  my($self) = shift;

  my $num = @_ ? shift : 1;
  my @children = $self->pop_post_children($num);

  if(@children < $num)
  {
    push(@children, $self->pop_pre_children($num - @children));
  }

  return @children == 1 ? $children[0] : @children;
}

sub shift_children 
{
  my($self) = shift;

  my $num = @_ ? shift : 1;
  my @children = $self->shift_pre_children($num);

  if(@children < $num)
  {
    push(@children, $self->shift_post_children($num - @children));
  }

  return @children == 1 ? $children[0] : @children;
}

sub unshift_children { shift->unshift_pre_children(@_) }

1;
