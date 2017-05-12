use strict;
use warnings;
use Test::More;

use Path::Tiny;
use FindBin;
use lib path($FindBin::Bin)->parent->child('lib')->stringify;

use Test::Fatal::Assert;

use Scalar::Util qw( refaddr );

nofatals "require String::Sections::Result" => sub {
  require String::Sections::Result;
};

my $instance;

nofatals "new()" => sub {
  $instance = String::Sections::Result->new();
};

nofatals "sections()" => sub {
  my $sections = $instance->sections;
  is_deeply( $sections, {}, 'sections() == {}' );
};
nofatals "has_current()" => sub {
  ok( !$instance->has_current, 'has_current() == false' );
};
fatals(
  "_current()" => sub {
    my $result = $instance->_current;
  },
  and_fatal_is => sub {
    like( $_, qr/current never set, but tried to use it/, "execption mentions current" );
  }
);
fatals(
  "_current() x2" => sub {
    my $result = $instance->_current;
  },
  and_fatal_is => sub {
    like( $_, qr/current never set, but tried to use it/, "exception mentions current" );
  }
);
nofatals "section(q{DOES NOT EXIST})" => sub {
  is( $instance->section('DOES NOT EXIST'), undef, 'section(q{DOES NOT EXIST}) == undef' );
};
nofatals "section_names()" => sub {
  is_deeply( [ $instance->section_names ], [], '[section_names()] == []' );
};
nofatals "has_section(q{DOES NOT EXIST})" => sub {
  ok( !$instance->has_section(q{DOES NOT EXIST}), 'has_section(q{DOES NOT EXIST}_) == undef' );
};
nofatals "shallow_clone()" => sub {
  my $clone = $instance->shallow_clone;
  isnt( refaddr $instance, refaddr $clone, "refaddr a != refaddr a->shallow_clone()" );
};
nofatals "shallow_merge(other)" => sub {
  my $merged = $instance->shallow_merge( String::Sections::Result->new() );
  isnt( refaddr $instance, refaddr $merged, "refaddr a != refaddr a->shallow_merge(b)" );
};

nofatals "set_current(q[Foo])" => sub {
  $instance->set_current('Foo');
  pass('set_current(q[Foo])');
};

nofatals "_current()" => sub {
  my $current = $instance->_current();
  is( $current, 'Foo', 'current() == Foo' );
};

my $content = "hello";

nofatals "set_section(q{bar})" => sub {
  $instance->set_section( q{bar}, \$content );
  pass("set_section(q{bar}, \\\$content)");
};
nofatals "has_section(q{bar})" => sub {
  ok( $instance->has_section('bar'), 'has_section(q{bar}) == true' );
};
nofatals "section_names()" => sub {
  is_deeply( [ $instance->section_names() ], ['bar'], '[ section_names() ] == [ q[bar] ]' );
};
nofatals "section(q{bar})" => sub {
  my $section = $instance->section('bar');
  is( refaddr $section, refaddr \$content, "refaddr section(q{bar}) == refaddr \\\$content" );
};
nofatals "append_data_to_section(q{bar}, \\q{world})" => sub {
  $instance->append_data_to_section( 'bar', \q{world} );
  pass('append_data_to_section(q{bar}, \q{world})');

};
nofatals "section('bar')" => sub {
  my $section = $instance->section('bar');
  is( refaddr $section, refaddr \$content, "refaddr section(q{bar}) == refaddr \\\$content" );
  is( $$section,        "helloworld",      "\${section(q{bar})} == \"helloworld\"" );
};
nofatals "append_data_to_current_section( \\q{world})" => sub {
  $instance->append_data_to_current_section( \q{world} );
  pass('append_data_to_current_section(\q{world})');

};
nofatals "has_section(q{Foo})" => sub {
  ok( $instance->has_section('Foo'), 'has_section(q{Foo}) == true' );
};
nofatals "section_names()" => sub {
  is_deeply( [ sort $instance->section_names() ], [ sort 'bar', 'Foo' ], '[ sort section_names() ] == [ sort q[bar], q[Foo] ]' );
};
nofatals "section('Foo')" => sub {
  my $section = $instance->section('Foo');
  is( $$section, "world", "\${section(q{Foo})} == \"world\"" );
};
nofatals "append_data_to_section(q{quux})" => sub {
  $instance->append_data_to_section('quux');
  pass('append_data_to_section(q{quux})');
};
nofatals "has_section(q{quux})" => sub {
  ok( $instance->has_section('quux'), 'has_section(q{quux}) == true' );
};
nofatals "section_names()" => sub {
  is_deeply(
    [ sort $instance->section_names() ],
    [ sort 'bar', 'Foo', 'quux' ],
    '[ sort section_names() ] == [ sort q[bar], q[Foo],q[quux] ]'
  );
};
nofatals "section('quux')" => sub {
  my $section = $instance->section('quux');
  is( $$section, q{}, "\${section(q{quux})} == \"\"" );
};
nofatals "set_current(q[doo])" => sub {
  $instance->set_current('doo');
  pass('set_current(q[doo])');
};
nofatals "append_data_to_current_section()" => sub {
  $instance->append_data_to_current_section();
  pass('append_data_to_current_section()');

};
nofatals "has_section(q{doo})" => sub {
  ok( $instance->has_section('doo'), 'has_section(q{doo}) == true' );
};
nofatals "section_names()" => sub {
  is_deeply(
    [ sort $instance->section_names() ],
    [ sort 'doo', 'bar', 'Foo', 'quux' ],
    '[ sort section_names() ] == [ sort q[doo],q[bar], q[Foo],q[quux] ]'
  );
};
my $expected = {
  'Foo'  => qq{__[Foo]__\nworld},
  'bar'  => qq{__[bar]__\nhelloworld},
  'doo'  => qq{__[doo]__\n},
  'quux' => qq{__[quux]__\n},
};
nofatals "_compose_section(name)" => sub {
  for my $key ( sort keys %{$expected} ) {
    my $result = $instance->_compose_section($key);
    is( $result, $expected->{$key}, '_compose_section(' . $key . ') == expected' );
  }
};
nofatals "_to_s()" => sub {
  my $result = $instance->to_s;
  like( $result, qr/__\[/, 'to_s() matches regexp' );
};

done_testing;
1;
