use Test::More;

if ($^V < v5.14) { plan skip_all => 'Perl 5.14 or higher required'; }
else             { plan tests => 28; }

use lib 't/lib';
use PathTest;

use utf8;

my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

my $opts = {
   style => 'PerlClassUTF8',
};

test_pathing($opts,
   [qw(
      Perl::Class
      overload::pragma
      K2P
      K2P'Foo'Bar'Baz
      K2P::Foo::Bar::Baz
      K2P'Class::Fun
      ʻNIGHTMäREʼ::ʺ'ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ
   )],
   [qw(
      Perl::Class
      overload::pragma
      K2P
      K2P::Foo::Bar::Baz
      K2P::Foo::Bar::Baz
      K2P::Class::Fun
      ʻNIGHTMäREʼ::ʺ::ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ
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
