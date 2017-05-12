package Test::Classy;

use strict;
use warnings;
use Test::More ();
use Test::Classy::Util;
use Sub::Install qw( install_sub );

our $VERSION = '0.10';

my @tests;
my $caller = caller;

install_sub({
  as   => 'load_tests_from',
  into => $caller,
  code => sub (@) {
    my @monikers = @_;

    require Module::Find;

    @tests = Test::Classy::_look_for_tests(@monikers);
    foreach my $moniker ( @monikers ) {
      push @tests, grep { $_->isa('Test::Classy::Base') }
                   Module::Find::useall( $moniker );
    }
  },
});

install_sub({
  as   => 'load_test',
  into => $caller,
  code => sub ($) {
    my $moniker = shift;
    unless ($moniker->can('import')) {
      eval "require $moniker" or die $@;
    }
    push @tests, $moniker;
  },
});

install_sub({
  as   => 'limit_tests_by',
  into => $caller,
  code => sub (@) {
    my @monikers = @_;

    foreach my $class ( @tests ) {
      $class->_limit( @monikers );
    }
  },
});

install_sub({
  as   => 'run_tests',
  into => $caller,
  code => sub (;@) {
    my @args = @_;

    unless (@tests) {
      @tests = Test::Classy::_look_for_tests();
    }

    unless (Test::Classy::Util::_planned()) {
      Test::More::plan tests => __PACKAGE__->plan;
    }

    foreach my $class ( @tests ) {
      $class->_run_tests( @args );
    }
  },
});

sub _look_for_tests {
  my @queue = @_;

  require Class::Inspector;

  unless (@queue) {
    @queue = grep { $_ ne 'main' }
             Class::Inspector->_subnames('');
  }

  my @found;
  while (my $moniker = shift @queue) {
    my @subnames = Class::Inspector->_subnames($moniker);
    foreach my $subname (@subnames) {
      my $class = $moniker.'::'.$subname;
      push @found, $class if $class ne 'Test::Classy::Base'
                         and $class->isa('Test::Classy::Base');
      unshift @queue, $class;
    }
  }
  return @found;
}

sub plan {
  my $plan = 0;
  foreach my $test ( @tests ) {
    $plan += $test->_plan;
  }
  return $plan;
}

sub reset { @tests = () }  # for test

1;

__END__

=head1 NAME

Test::Classy - write your unit tests in other modules than *.t

=head1 SYNOPSIS

in your test file (t/some_test.t):

    use lib 't/lib';
    use Test::Classy;
    use MyApp::Model::DB;

    # prepare things you want to use in the tests (if you prefer)
    my $db = MyApp::Model::DB->connect;

    # load every test packages found under MyApp::Test::
    load_tests_from 'MyApp::Test';

    # or load it explicitly
    load_test 'MyApp::OtherTest::ForSomething';

    # you can limit tests only with Model attribute
    limit_tests_by 'Model';

    # run each of the tests ($db will be passed as an argument)
    # usually you don't need to declare plan of the tests here.
    run_tests( $db );

    # let's do some cleanings
    END { $db->disconnect; }

in your unit test class:

    package MyApp::Test::Something;
    use Test::Classy::Base;

    # write 'Test' attribute to test
    sub for_some : Test {
      my ($class, @args) = @_;

      # some unit test
      ok 1, "you can use Test::More's functions by default";
    }

    # you can declare the number of tests in a unit
    sub for_others : Tests(2) {
      my ($class, @args) = @_;

      pass 'first';
      pass 'second';
    }

    # tests will be skipped with 'Skip' attribute
    sub yet_another : Tests(2) Skip(for some reason) {
      my ($class, @args) = @_;

      pass 'but this test will be skipped';
      fail 'but this test will be skipped, either';
    }

    # TODO should work as you expect, too.
    sub may_fail : Tests TODO(for some reason) {
      my ($class, @args) = @_;

      fail 'until something is implemented';
    }

    # you can add any attributes to limit
    sub test_for_model : Test Model {
      my ($class, @args) = @_;

      # you can use $class->test_name to show the name of the test
      pass $class->test_name;  # "test_for_model"
    }

=head1 DESCRIPTION

This is yet another L<Test::Class>-like unit testing framework. As stated in L<Test::Class> pod, you don't need to care if your tests are small and working correctly. If not, this may be one of your options.

Unlike L<Test::Class>, Test::Classy (actually Test::Classy::Base) is based on L<Test::More> and exports everything L<Test::More> exports. Test::Classy doesn't control test flow as fully as L<Test::Class>, but it may be easier to skip and limit tests.

=head1 FLOW CONTROL FUNCTIONS

=head2 load_tests_from

takes a namespace as an argument and loads all the classes found under that (so, you may want to 'use lib' first). If you have some base test classes there, you may want to add 'ignore_me' (or 'ignore') option to 'use Test::Classy::Base' to be ignored while testing.

  (in your .t file)
    use Test::Classy;
    use lib 't/lib';

    load_tests_from 'MyApp::Test';
    run_tests;

  (in your test base class)
    package MyApp::Test::Base;
    use Test::Classy::Base;

    # not only children but base class itself will test this
    # (probably with different settings)
    sub for_both : Test {}

  (in other base class)
    package MyApp::Test::AnotherBase;
    use Test::Classy::Base 'ignore_me';

    # only children will test this.
    sub for_children_only : Test {}

=head2 load_test

takes a complete class name and loads it to test.

=head2 limit_tests_by

takes attribute names to limit tests that will be executed. You may want to specify test targets while debugging.

=head2 run_tests

may take optional arguments and runs each of the loaded tests with those arguments.

=head1 CLASS METHODS

=head2 plan

returns the number of declared test. You usually don't need to declare test plan in .t files, but if you really want to add extra tests there (especially 'use_ok' or 'isa_ok' tests for context class/objects to share), use this to calculate the real plan.

  (in your .t file)
    use Test::Classy;

    load_tests_from 'MyApp::Test';

    Test::More::plan(tests => Test::Classy->plan + 1);
    run_tests;

    pass 'the extra tests';

If you want to use 'no_plan', declare it (plan "no_plan") beforehand by yourself, or use 'Test(no_plan)' attribute somewhere in your test classes.

=head2 reset

removes loaded tests. mainly for the tests of Test::Classy itself.

=head1 SEE ALSO

L<Test::Class>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
