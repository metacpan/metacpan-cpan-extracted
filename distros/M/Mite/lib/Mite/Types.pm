package Mite::Types;

use feature ':5.10';
use Mouse::Util::TypeConstraints;


class_type 'Path::Tiny';


subtype 'Path' =>
  as 'Path::Tiny';

coerce 'Path' =>
  from 'Str',
  via {
      require Path::Tiny;
      return Path::Tiny->new($_);
  };


subtype 'AbsPath' =>
  as 'Path::Tiny',
  where { $_->is_absolute };

coerce 'AbsPath' =>
  from 'Path::Tiny',
  via {
      return $_->absolute;
  };

coerce 'AbsPath' =>
  from 'Str',
  via {
      require Path::Tiny;
      return Path::Tiny->new($_)->absolute;
  };

no Mouse::Util::TypeConstraints;

1;
