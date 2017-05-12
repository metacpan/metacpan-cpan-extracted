#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';
use File::Spec;

my $test_tree = 't/samples';
{
  # ick, I can't ship a filename with a space in it thanks to maniread()
  # might as well do them all here
  use File::Path ();
  use File::Basename ();
  my @mods = map({$test_tree . '/' . $_}
    'lib1/My/Module.pm',
    'lib1/Foo.pm',
    'lib1/Foo/Two.pm',
    'lib2/This/Module.pm',
    'lib2/My/Module/Lives/Here/o.pm',
    'lib2/My/Module/Lives.pm',
    'lib2/My/Module/Here.pm',
    'lib2/My/Mod.pm',
    'lib2/Foo/Two.pmc',
    'lib3/Foo/Bar.pmc',
    'lib4/My/Module/Lives/Here.pm',
    'lib eek/FindMe/Here.pm',
  );
  foreach my $mod (@mods) {
    File::Path::mkpath(File::Basename::dirname($mod));
    {open(my $fh, '>', $mod) or
      die "cannot create test file '$mod' ($!)";}
  }
}

BEGIN {
  use_ok('Module::Finder');
}
#{
#  my $finder = Module::Finder->new(paths => {'File' => '-'});
#  my %info = $finder->_find;
#}
{
  my $finder = Module::Finder->new(paths => {'File' => '/'});
  my @modnames = $finder->modules;
  ok(exists($finder->{_module_infos}), 'got cached');
  ok(@modnames);
  my @modnames2 = $finder->modules;
  is_deeply([sort(@modnames2)], [sort(@modnames)], 'same');
  #warn join("\n  ", 'got:', @modnames);
}

{
  my $finder = Module::Finder->new(paths => {'File' => '+'});
  my @modnames = $finder->modules;
  my @fs_mods = grep(/^File::Spec:?/, @modnames);
  is(scalar(@fs_mods), 1, 'only the top one');
  is($fs_mods[0], 'File::Spec');
}

{ # no inc
  my $finder = Module::Finder->new(
    dirs => ['t/samples/lib1', 't/samples/lib2'],
    paths => {File => '+'},
  );
  my @modnames = $finder->modules;
  is(scalar(@modnames), 0, 'none');

}

sub do_expect {
  my ($name, $args, $expect) = @_;
  my $finder = Module::Finder->new(%$args);
  my @expect = sort(@$expect);
  my @modnames = sort($finder->modules);
  is(scalar(@modnames), scalar(@expect), 'count');
  is_deeply(\@modnames, \@expect, $name);
}

do_expect(
  'one deep',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2'],
    paths => {My => '+'},
  },
  [qw(
    My::Module
    My::Mod
  )],
);
do_expect(
  'two levels',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2'],
    paths => {My => '+/'},
  },
  [qw(
    My::Module
    My::Mod
    My::Module::Here
    My::Module::Lives
  )],
);
do_expect(
  'spaces',
  {
    dirs => ['t/samples/lib eek'],
    paths => {FindMe => '+/'},
  },
  [qw(
    FindMe::Here
  )],
);

do_expect(
  'toplevel modules',
  {
    dirs => ['t/samples/lib1'],
    paths => {'' => '/'},
  },
  [qw(
    Foo::Two
    Foo
    My::Module
  )],
);
do_expect(
  'toplevel modules (implied)',
  {
    dirs => ['t/samples/lib1'],
  },
  [qw(
    Foo::Two
    Foo
    My::Module
  )],
);

do_expect(
  'pmc',
  {
    dirs => ['t/samples/lib3'],
    paths => {'Foo' => '+'},
  },
  ['Foo::Bar'],
);
do_expect(
  'pmc-recurse',
  {
    dirs => ['t/samples/lib3'],
  },
  ['Foo::Bar'],
);

do_expect(
  'pmcTwo',
  {
    dirs => ['t/samples/lib1'],
    paths => {'Foo' => '+'},
  },
  ['Foo::Two'],
);
do_expect(
  'pmcTwo2',
  {
    dirs => ['t/samples/lib2'],
    paths => {'Foo' => '+'},
  },
  ['Foo::Two'],
);
do_expect(
  'pmc-recurse-full',
  {
    dirs => ['t/samples/lib2'],
  },
  [qw(
    Foo::Two
    My::Mod
    My::Module::Here
    My::Module::Lives::Here::o
    My::Module::Lives
    This::Module
  )],
);
# GAH, I got no two-level paths here!
do_expect(
  'two-level',
  {
    dirs => ['t/samples/lib2'],
    paths => {'My::Module' => '+'}
  },
  [qw(
    My::Module::Here
    My::Module::Lives
  )],
);
do_expect(
  'two-level-recurse',
  {
    dirs => ['t/samples/lib2'],
    paths => {'My::Module' => '/'}
  },
  [qw(
    My::Module::Here
    My::Module::Lives
    My::Module::Lives::Here::o
  )],
);
do_expect(
  'three-level-spot',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2', 't/samples/lib4'],
    paths => {'My::Module::Lives' => '+'}
  },
  [qw(
    My::Module::Lives::Here
  )],
);
do_expect(
  'three-level-recurse',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2', 't/samples/lib4'],
    paths => {'My::Module::Lives' => '/'}
  },
  [qw(
    My::Module::Lives::Here
    My::Module::Lives::Here::o
  )],
);
do_expect( # sort of silly, but maybe good for something
  'explicit+path',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2', 't/samples/lib4'],
    paths => {'My::Module::Lives' => '/'},
    name => 'Here',
  },
  [qw(
    My::Module::Lives::Here
  )],
);
do_expect( # sort of silly, but maybe good for something
  'explicit+path2',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2', 't/samples/lib4'],
    paths => {'My::Module::Lives' => '+'},
    name => 'Here',
  },
  [qw(
    My::Module::Lives::Here
  )],
);
do_expect( # ah, here's where you need this
  'explicit+path (sensible)',
  {
    dirs => ['t/samples/lib1', 't/samples/lib2', 't/samples/lib4'],
    paths => {
      'My::Module::Lives' => '+',
      'My::Module::' => '+'
    },
    name => 'Here',
  },
  [qw(
    My::Module::Lives::Here
    My::Module::Here
  )],
);

{
  my $finder = Module::Finder->new(
    dirs => ['t/samples/lib1', 't/samples/lib2'],
    paths => {My => '+'},
  );
  my %info = $finder->module_infos;
  ok(exists($info{'My::Module'}));
  ok(exists($info{'My::Mod'}));
  {
    my $inf = $info{'My::Module'};
    isa_ok($inf, 'Module::Finder::Info');
    is($inf->module_name, 'My::Module');
    is($inf->module_path, 'My/Module.pm');
    is($inf->inc_path, File::Spec->rel2abs('t/samples/lib1'));
    ok(-e $inf->filename, 'exists');
  }
  {
    my $inf = $info{'My::Mod'};
    isa_ok($inf, 'Module::Finder::Info');
    is($inf->module_name, 'My::Mod');
    is($inf->module_path, 'My/Mod.pm');
    is($inf->inc_path, File::Spec->rel2abs('t/samples/lib2'));
    ok(-e $inf->filename, 'exists');
  }
}
{ # now with the find-based approach
  my $finder = Module::Finder->new(
    dirs => ['t/samples/lib1'],
  );
  my %info = $finder->module_infos;
  ok(exists($info{'My::Module'}));
  {
    my $inf = $info{'My::Module'};
    isa_ok($inf, 'Module::Finder::Info');
    is($inf->module_name, 'My::Module');
    is($inf->module_path, File::Spec->catfile(qw(My Module.pm)));
    is($inf->inc_path, File::Spec->rel2abs('t/samples/lib1'));
    ok(-e $inf->filename, 'exists');
  }
}
{ # Explicit
  my $finder = Module::Finder->new(
    dirs => ['t/samples/lib1'],
    name => 'My::Module',
  );
  my %info = $finder->module_infos;
  ok(exists($info{'My::Module'}));
  is(scalar($finder->modules), 1);
}

File::Path::rmtree($test_tree);
# vi:ts=2:sw=2:et:sta
