package Rose::DB::Object::Exception;

use strict;

use Rose::Object;
our @ISA = qw(Rose::Object);

our $VERSION = '0.01';

use overload
(
  '""' => sub { shift->message },
   fallback => 1,
);

use Rose::Object::MakeMethods::Generic
(
  scalar =>
  [
    'message',
    'code',
  ],
);

sub init
{
  my($self) = shift;
  @_ = (message => @_)  if(@_ == 1);
  $self->SUPER::init(@_);
}

package Rose::DB::Object::Exception::ClassNotReady;

our @ISA = qw(Rose::DB::Object::Exception);

1;
