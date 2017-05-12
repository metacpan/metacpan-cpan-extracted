package Rose::DB::Object::Metadata::Object;

use strict;

use Clone();
use Scalar::Util();

use Rose::Object;
our @ISA = qw(Rose::Object);

our $VERSION = '0.722';

sub parent
{
  my($self) = shift; 
  return Scalar::Util::weaken($self->{'parent'} = shift)  if(@_);
  return $self->{'parent'};
}

sub clone
{
  my($self) = shift;

  my $clone = Clone::clone($self);
  Scalar::Util::weaken($clone->{'parent'});

  return $clone;
}

1;
