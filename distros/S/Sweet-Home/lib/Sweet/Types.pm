package Sweet::Types;
use strict;
use warnings;

use MooseX::Types;
use MooseX::Types::Moose qw(Str ArrayRef);

class_type('Sweet::File');

coerce 'Sweet::File', from Str,
  via { Sweet::File->new(path=>$_) };

class_type('Sweet::Dir');

coerce 'Sweet::Dir',
  from Str,      via { Sweet::Dir->new(path => $_) },
  from ArrayRef, via { Sweet::Dir->new(path => $_) };

1;

