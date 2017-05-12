use Test::More tests => 25;

use lib 't/lib';
use PathTest;

my $opts = {
   style => 'PerlClass',
};

test_pathing($opts,
   [qw(
      Perl::Class
      overload::pragma
      K2P
      K2P'Foo'Bar'Baz
      K2P::Foo::Bar::Baz
      K2P'Class::Fun
   )],
   [qw(
      Perl::Class
      overload::pragma
      K2P
      K2P::Foo::Bar::Baz
      K2P::Foo::Bar::Baz
      K2P::Class::Fun
   )],
   'Basic',
);

test_pathing_failures($opts,
   [qw(
      Perl:Class
      ::pragma
      K2P::
      'K2P'Foo'Bar'Baz'
      K2P::Foo:Bar::Baz
      K2P'Class::Fun'
   ),
      '   K2P::Foo::Bar::Baz   ',
   ],
   [
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
      qr/^Found unparsable step/,
   ],
   'Fails',
);
