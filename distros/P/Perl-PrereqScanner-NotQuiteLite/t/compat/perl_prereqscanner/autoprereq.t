use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../";
use Test::More;
use t::Util;

our $TEST_SEPARATE_VERSION = 0;
our $TEST_NOREQUIRE = 0;

test('empty string', '', {});
test("line ".__LINE__, 'use Use::NoVersion;', { 'Use::NoVersion' => 0 });
test("line ".__LINE__, 'use Use::Version 0.50;', { 'Use::Version' => '0.50' });
test("line ".__LINE__, 'use Errno 0.50;', { 'Errno' => '0.50' });
test("line ".__LINE__, 'require Require;', { Require => 0 });

test("line ".__LINE__,
  'use Use::Version 0.50; use Use::Version 1.00;',
  {
    'Use::Version' => '1.00',
  },
);

test("line ".__LINE__,
  'use Use::Version 1.00; use Use::Version 0.50;',
  {
    'Use::Version' => '1.00',
  },
);

test("line ".__LINE__,
  'use Import::IgnoreAPI require => 1;',
  { 'Import::IgnoreAPI' => 0 },
);

test("line ".__LINE__,
  'no Import::IgnoreAPI require => 1;',
  undef, undef, undef,
  { 'Import::IgnoreAPI' => 0 },
);

test("line ".__LINE__, 'require Require; Require->VERSION(0.50);', { Require => '0.50' });

test("line ".__LINE__, 'use Require; Require->VERSION(0.50);', { Require => '0.50' });

test("line ".__LINE__, 'require Require; Require->VERSION(+0.50);', { Require => 0 });

test("line ".__LINE__, 'require Require; foo(); Require->VERSION(1.00);', { Require => 0 }) if $TEST_SEPARATE_VERSION;

test("line ".__LINE__,
  'require Require; Require->VERSION(v1.0.50);',
  { Require => 'v1.0.50' }
);

test("line ".__LINE__,
  q{require Require; Require->VERSION('v1.0.50');},
  { Require => 'v1.0.50' }
);

test("line ".__LINE__,
  'require Require; Require->VERSION(q[1.00]);',
  { Require => '1.00' }
);

test("line ".__LINE__,
  'require Require; Require::Other->VERSION(1.00);',
  { Require => 0 }
);

test('require with comment', 
  <<'END REQUIRE WITH COMMENT',
require Require::This; # this comment shouldn't matter
Require::This->VERSION(0.450);
END REQUIRE WITH COMMENT
  { 'Require::This' => '0.450' }
);

test("line ".__LINE__,
  'require Require; Require->VERSION(0.450) if some_condition; ',
  { 'Require' => 0 }
);

# Moose features
# (added 'use Moose;' to everything to trigger Moose parsers)
test("line ".__LINE__,
  'use Moose; extends "Foo::Bar";',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar"; extends "Foo::Baz";',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
    'Foo::Baz' => 0,
  },
);
test("line ".__LINE__, "use Moose; with 'With::Single';", { 'Moose' => 0, 'With::Single' => 0 });
test("line ".__LINE__,
  "use Moose; extends 'Extends::List1', 'Extends::List2';",
  {
    'Moose' => 0,
    'Extends::List1' => 0,
    'Extends::List2' => 0,
  },
);

test("line ".__LINE__, "use Moose; within('With::Single');", { Moose => 0 });

test("line ".__LINE__,
  "use Moose; with 'With::Single', 'With::Double';",
  {
    'Moose' => 0,
    'With::Single' => 0,
    'With::Double' => 0,
  },
);

test("line ".__LINE__,
  "use Moose; with 'With::Single' => { -excludes => 'method'}, 'With::Double';",
  {
    'Moose' => 0,
    'With::Single' => 0,
    'With::Double' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with ("With::QW1", "With::QW2");',
  {
    'Moose' => 0,
    'With::QW1' => 0,
    'With::QW2' => 0,
  },
);

test("line ".__LINE__,
  "use Moose; with('Paren::Role');",
  {
    'Moose' => 0,
    'Paren::Role' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with("With::QW1", "With::QW2");',
  {
    'Moose' => 0,
    'With::QW1' => 0,
    'With::QW2' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with qw(With::QW1 With::QW2);',
  {
    'Moose' => 0,
    'With::QW1' => 0,
    'With::QW2' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with "::Foo"',
  { Moose => 0 },
);

test("line ".__LINE__,
  'use Moose; extends qw(Extends::QW1 Extends::QW2);',
  {
    'Moose' => 0,
    'Extends::QW1' => 0,
    'Extends::QW2' => 0,
  },
);

test("line ".__LINE__,
  'use base "Base::QQ1";',
  {
    'Base::QQ1' => 0,
    base => 0,
  },
);

test("line ".__LINE__,
  'use base 10 "Base::QQ1";',
  {
    'Base::QQ1' => 0,
    base => 10,
  },
);
test("line ".__LINE__,
  'use base qw{ Base::QW1 Base::QW2 };',
  { 'Base::QW1' => 0, 'Base::QW2' => 0, base => 0 },
);

test("line ".__LINE__,
  'use parent "Parent::QQ1";',
  {
    'Parent::QQ1' => 0,
    parent => 0,
  },
);

test("line ".__LINE__,
  'use parent 10 "Parent::QQ1";',
  {
    'Parent::QQ1' => 0,
    parent => 10,
  },
);

test("line ".__LINE__,
  'use parent 2 "Parent::QQ1"; use parent 2 "Parent::QQ2"',
  {
    'Parent::QQ1' => 0,
    'Parent::QQ2' => 0,
    parent => 2,
  },
);

test("line ".__LINE__,
  'use parent 2 "Parent::QQ1"; use parent 1 "Parent::QQ2"',
  {
    'Parent::QQ1' => 0,
    'Parent::QQ2' => 0,
    parent => 2,
  },
);

test("line ".__LINE__,
  'use parent qw{ Parent::QW1 Parent::QW2 };',
  {
    'Parent::QW1' => 0,
    'Parent::QW2' => 0,
    parent => 0,
  },
);

# test case for #55713: support for use parent -norequire
# ...but is this ok???
test("line ".__LINE__,
  'use parent -norequire, qw{ Parent::QW1 Parent::QW2 };',
  {
    'Parent::QW1' => 0,
    'Parent::QW2' => 0,
    parent => 0,
  },
) if $TEST_NOREQUIRE;

test("line ".__LINE__,
  'use superclass "superclass::QQ1";',
  {
    'superclass::QQ1' => 0,
    superclass => 0,
  },
);

test("line ".__LINE__,
  'use superclass 10 "superclass::QQ1", 1.23;',
  {
    'superclass::QQ1' => 1.23,
    superclass => 10,
  },
);

test("line ".__LINE__,
  'use superclass 2 "superclass::QQ1"; use superclass 2 "superclass::QQ2"',
  {
    'superclass::QQ1' => 0,
    'superclass::QQ2' => 0,
    superclass => 2,
  },
);

test("line ".__LINE__,
  'use superclass 2 "superclass::QQ1", "v1.2.3"; use superclass 1 "superclass::QQ1", "v1.2.4"',
  {
    'superclass::QQ1' => "v1.2.4",
    superclass => 2,
  },
);

test("line ".__LINE__,
  'use superclass qw{ superclass::QW1 1.23 };',
  {
    'superclass::QW1' => 1.23,
    superclass => 0,
  },
);

# test case for #55713: support for use superclass -norequire
test("line ".__LINE__,
  'use superclass -norequire, qw{ superclass::QW1 superclass::QW2 };',
  {
    'superclass::QW1' => 0,
    'superclass::QW2' => 0,
    superclass => 0,
  },
) if $TEST_NOREQUIRE;

test("line ".__LINE__,
  'use superclass -norequire, "superclass::QW1" => 1.23,  "superclass::QW2";',
  {
    'superclass::QW1' => 1.23,
    'superclass::QW2' => 0,
    superclass => 0,
  },
) if $TEST_NOREQUIRE;

# test case for #55851: require $foo
test("line ".__LINE__,
  'my $foo = "Carp"; require $foo',
  {},
);

test("line ".__LINE__,
  q{use strict; use warnings; use lib '.'; use feature ':5.10';},
  { strict => 0, warnings => 0, lib => 0, feature => 0 },
);

test("line ".__LINE__,
  q{use Test::More; is 0, 1; done_testing},
  {
    'Test::More' => '0.88',
  },
);

# test cases for Moose 1.03 -version extension
test("line ".__LINE__,
  'use Moose; extends "Foo::Bar"=>{-version=>"1.1"};',
  {
    'Moose' => 0,
    'Foo::Bar' => '1.1',
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar" => { -version => \'1.1\' };',
  {
    'Moose' => 0,
    'Foo::Bar' => '1.1',
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar" => { -version => 13.3 };',
  {
    'Moose' => 0,
    'Foo::Bar' => '13.3',
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar" => { -version => \'1.1\' }; extends "Foo::Baz" => { -version => 5 };',
  {
    'Moose' => 0,
    'Foo::Bar' => '1.1',
    'Foo::Baz' => 5,
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar"=>{-version=>1},"Foo::Baz"=>{-version=>2};',
  {
    'Moose' => 0,
    'Foo::Bar' => 1,
    'Foo::Baz' => 2,
  },
);

test("line ".__LINE__,
  'use Moose; extends "Foo::Bar" => { -version => "4.3.2" }, "Foo::Baz" => { -version => 2.44894 };',
  {
    'Moose' => 0,
    'Foo::Bar' => 'v4.3.2',
    'Foo::Baz' => 2.44894,
  },
);

test("line ".__LINE__,
  'use Moose; with "With::Single" => { -excludes => "method", -version => "1.1.1" }, "With::Double";',
  {
    'Moose' => 0,
    'With::Single' => 'v1.1.1',
    'With::Double' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with "With::Single" => { -wow => { -wow => { a => b } }, -version => "1.1.1" }, "With::Double";',
  {
    'Moose' => 0,
    'With::Single' => 'v1.1.1',
    'With::Double' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with "With::Single" => { -exclude => "method", -version => "1.1.1" },
  "With::Double" => { -exclude => "foo" };',
  {
    'Moose' => 0,
    'With::Single' => 'v1.1.1',
    'With::Double' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with("Foo::Bar");',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with( "Foo::Bar" );',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with( "Foo::Bar", "Bar::Baz" );',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; with( "Foo::Bar" => { -version => "1.1" },
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; with( "Blam::Blam", "Foo::Bar" => { -version => "1.1" },
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; with("Blam::Blam","Foo::Bar"=>{-version=>"1.1"},
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; with("Blam::Blam","Foo::Bar"=>{-version=>"1.1"},
  "Bar::Baz",
  "Hoopla" => { -version => 1 } );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
    'Hoopla' => 1,
  }
);

test("line ".__LINE__,
  'use Moose; extends("Foo::Bar");',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; extends( "Foo::Bar" );',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; extends( "Foo::Bar", "Bar::Baz" );',
  {
    'Moose' => 0,
    'Foo::Bar' => 0,
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; extends( "Foo::Bar" => { -version => "1.1" },
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; extends( "Blam::Blam", "Foo::Bar" => { -version => "1.1" },
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; extends("Blam::Blam","Foo::Bar"=>{-version=>"1.1"},
  "Bar::Baz" );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
  }
);

test("line ".__LINE__,
  'use Moose; extends("Blam::Blam","Foo::Bar"=>{-version=>"1.1"},
  "Bar::Baz",
  "Hoopla" => { -version => 1 } );',
  {
    'Moose' => 0,
    'Blam::Blam' => 0,
    'Foo::Bar' => '1.1',
    'Bar::Baz' => 0,
    'Hoopla' => 1,
  }
);

test("line ".__LINE__,
  'use Moose ;with(
	\'AAA\' => { -version => \'1\' },
	\'BBB\' => { -version => \'2.1\' },
	\'CCC\' => {
		-version => \'4.012345\',
		default_finders => [ \':InstallModules\', \':ExecFiles\' ],
	},
);',
  {
    'Moose' => 0,
    'AAA' => 1,
    'BBB' => '2.1',
    'CCC' => '4.012345',
  },
);

test("line ".__LINE__,
  'use Moose; with(
    "AAA"
      =>
        {
          -version
            =>
              1
        },
  );',
  {
    'Moose' => 0,
    'AAA' => 1,
  },
);

test("line ".__LINE__,
  'use Moose; with
    "AAA"
      =>
        {
          -version
            =>
              1
        };',
  {
    'Moose' => 0,
    'AAA' => 1,
  },
);

test("line ".__LINE__,
  'use Moose; with(

"Bar"

);',
  {
    'Moose' => 0,
    'Bar' => 0,
  },
);

test("line ".__LINE__,
  'use Moose; with

\'Bar\'

;',
  {
    'Moose' => 0,
    'Bar' => 0,
  },
);

# invalid code tests
test("line ".__LINE__,  'use Moose; with;', {Moose => 0}, );
test("line ".__LINE__,  'use Moose; with foo;', {Moose => 0} );

# test cases for aliased.pm
test("line ".__LINE__,
  q{use aliased 'Long::Custom::Class::Name'},
  {
    'aliased' => 0,
    'Long::Custom::Class::Name' => 0,
  },
);

test("line ".__LINE__,
  q{use aliased 0.30 'Long::Custom::Class::Name'},
  {
    'aliased' => '0.30',
    'Long::Custom::Class::Name' => 0,
  },
);


test("line ".__LINE__,
  q{use aliased 'Long::Custom::Class::Name' => 'Name'},
  {
    'aliased' => 0,
    'Long::Custom::Class::Name' => 0,
  },
);

test("line ".__LINE__,
  q{use aliased;},
  {
    'aliased' => 0,
  },
);

# rolsky says this is a problem case
test("line ".__LINE__,
  q{use Test::Requires 'Foo'},
  {
    'Test::Requires' => 0,
  },
);

# test cases for POE
test("line ".__LINE__,
  q{use POE 'Component::IRC'},
  {
    'POE' => 0,
    'POE::Component::IRC' => 0,
  },
);

test("line ".__LINE__,
  q{use POE qw/Component::IRC Component::Server::NNTP/},
  {
    'POE' => 0,
    'POE::Component::IRC' => 0,
    'POE::Component::Server::NNTP' => 0,
  },
);

done_testing;
