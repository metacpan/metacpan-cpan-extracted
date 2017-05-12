package Object::Remote::Connector::Local;

use Moo;

with 'Object::Remote::Role::Connector::PerlInterpreter';

no warnings 'once';

BEGIN {  }

push @Object::Remote::Connection::Guess, sub {
  if (($_[0]||'') eq '-') {
      shift(@_);
      __PACKAGE__->new(@_);
  }
};

1;
