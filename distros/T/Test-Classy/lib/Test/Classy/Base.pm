package Test::Classy::Base;

use strict;
use warnings;
use base qw( Class::Data::Inheritable );
use Test::More ();
use Data::Dump;
use Class::Inspector;
use Encode;
use Term::Encoding;
use Test::Classy::Util;

my $ENCODE = eval { find_encoding(Term::Encoding::get_encoding()) };

sub import {
  my ($class, @flags)  = @_;
  my $caller = caller;

  if ( $class ne __PACKAGE__ ) {
    return unless grep { $_ eq 'base' } @flags;
  }

  no strict 'refs';
  push @{"$caller\::ISA"}, $class;

  Test::Stream::Toolset::init_tester($caller) if $INC{'Test/Stream/Toolset.pm'};

  # XXX: not sure why but $TODO refused to be exported well
  *{"$caller\::TODO"} = \$Test::More::TODO;

  foreach my $export ( @Test::More::EXPORT ) {
    next if $export =~ /^\W/;
    *{"$caller\::$export"} = \&{"Test::More\::$export"};
  }

  if ( grep { $_ eq 'ignore' or $_ eq 'ignore_me' } @flags ) {
    ${"$caller\::_ignore_me"} = 1;
  }

  if ( $class eq __PACKAGE__ ) {
    $caller->mk_classdata( _tests => {} );
    $caller->mk_classdata( _plan => 0 );
    $caller->mk_classdata( test_name => '' );
  }
}

sub MODIFY_CODE_ATTRIBUTES {
  my ($class, $code, @attrs) = @_;

  my %stash;
  foreach my $attr ( @attrs ) {
    if ( $attr eq 'Test' ) {
      $stash{plan} = 1;
    }
    elsif ( my ($dummy, $plan) = $attr =~ /^Tests?\((['"]?)(\d+|no_plan)\1\)$/ ) {
      $stash{plan} = $plan;
    }
    elsif ( my ($type, $dummy2, $reason) = $attr =~ /^(Skip|TODO)(?:\((['"]?)(.+)\)\2)?$/ ) {
      $stash{$type} = $reason;
    }
    else {
      $stash{$attr} = 1;
    }
  }
  return unless $stash{plan};

  if ( $stash{plan} eq 'no_plan' ) {
    Test::More::plan 'no_plan' unless Test::Classy::Util::_planned();
    $stash{plan} = 0;
  }

  $class->_plan( $class->_plan + $stash{plan} );

  $stash{code} = $code;

  # At this point, the name looks like CODE(...)
  # we'll make it human-readable later, with class inspection
  $class->_tests->{$code} = \%stash;

  return;
}

sub _limit {
  my ($class, @monikers) = @_;

  my $tests = $class->_tests;
  my $reason = 'limited by attributes';

LOOP:
  foreach my $name ( keys %{ $tests } ) {
    foreach my $moniker ( @monikers ) {
      next LOOP if exists $tests->{$name}->{$moniker};
    }
    $tests->{$name}->{Skip} = $reason;
  }
}

sub _should_be_ignored {
  my $class = shift;

  { no strict 'refs';
    if ( ${"$class\::_ignore_me"} ) {
      SKIP: {
        Test::More::skip 'a base class, not to test', $class->_plan;
      }
      return 1;
    }
  }
}

sub _find_symbols {
  my $class = shift;

  # to allow multibyte method names
  local $Class::Inspector::RE_IDENTIFIER = qr/.+/s;

  my $methods = Class::Inspector->methods($class, 'expanded');

  my %symbols;
  foreach my $entry ( @{ $methods } ) {
    $symbols{$entry->[3]} = $entry->[2];  # coderef to sub name
  }
  return %symbols;
}

sub _run_tests {
  my ($class, @args) = @_;

  return if $class->_should_be_ignored;

  my %sym = $class->_find_symbols;

  $class->test_name( undef );

  $class->initialize(@args);

  my $tests = $class->_tests;

  foreach my $name ( sort { $sym{$a} cmp $sym{$b} } grep { $sym{$_} } keys %{ $tests } ) {
    next if $sym{$name} =~ /^(?:initialize|finalize)$/;

    if ( my $reason = $class->_should_skip_this_class ) {
      SKIP: { Test::More::skip $class->message($reason), $tests->{$name}->{plan}; }
      next;
    }

    $class->_run_test( $tests->{$name}, $sym{$name}, @args );
  }

  $class->finalize(@args);
}

sub _run_test {
  my ($class, $test, $name, @args) = @_;

  $class->test_name( $name );
  $class->_clear_skip_flag;

  if ( exists $test->{TODO} ) {
    my $reason = defined $test->{TODO}
      ? $test->{TODO}
      : "$name is not implemented";

    if ( exists $test->{Skip} ) {  # todo skip
      TODO: {
        Test::More::todo_skip $class->message($reason), $test->{plan};
      }
    }
    else {
      TODO: {
        no strict 'refs';
        local ${"$class\::TODO"} = $class->message($reason); # perl 5.6.2 hates this

        $class->__run_test($test, @args);
      }
    }
    return;
  }
  elsif ( exists $test->{Skip} ) {
    my $reason = defined $test->{Skip}
      ? $test->{Skip}
      : "skipped $name";
    SKIP: { Test::More::skip $class->message($reason), $test->{plan}; }
    return;
  }

  $class->__run_test($test, @args);
}

sub __run_test {
  my ($class, $test, @args) = @_;

  my $current = Test::Classy::Util::_current_test();

  local $@;
  eval { $test->{code}($class, @args); };
  if ( $@ ) {
    my $done = Test::Classy::Util::_current_test() - $current;
    my $rest = $test->{plan} - $done;
    if ( $rest ) {
      if ( exists $test->{TODO} ) {
        my $reason = defined $test->{TODO}
          ? $test->{TODO}
          : 'not implemented';
        TODO: {
          Test::More::todo_skip( $class->message("$reason: $@"), $rest );
        }
      }
      else {
        for ( 1 .. $rest ) {
          Test::More::ok( 0, $class->message($@) );
        }
      }
    }
  }

  if ( my $reason = $class->_is_skipped ) {
    my $done = Test::Classy::Util::_current_test() - $current;
    my $rest = $test->{plan} - $done;
    if ( $rest ) {
      for ( 1 .. $rest ) {
        Test::More->builder->skip( $class->message($reason) );
      }
    }
  }
}

sub skip_this_class {
  my ($class, $reason) = @_;

  no strict 'refs';
  ${"$class\::_skip_this_class"} = $reason || 'for some reason';
}

*skip_the_rest = \&skip_this_class;

sub _should_skip_this_class {
  my $class = shift;

  no strict 'refs';
  return ${"$class\::_skip_this_class"};
}

sub skip_this_test {
  my ($class, $reason) = @_;

  no strict 'refs';
  ${"$class\::_skip_this_test"} = $reason || 'for some reason';
}

*abort_this_test = \&skip_this_test;

sub _clear_skip_flag {
  my $class = shift;

  no strict 'refs';
  ${"$class\::_skip_this_test"} = '';
}

sub _is_skipped {
  my $class = shift;

  no strict 'refs';
  return ${"$class\::_skip_this_test"};
}

sub dump {
  my $class = shift;
  Test::More::diag( Data::Dump::dump( @_ ) );
}

sub message {
  my ($class, $message) = @_;

  $message = $class->_prepend_class_name( $class->_prepend_test_name( $message ) );

  $message = $ENCODE->encode($message) if $ENCODE && Encode::is_utf8($message);

  return $message;
}

sub _prepend_test_name {
  my ($class, $message) = @_;

  $message = '' unless defined $message;

  if ( my $name = $class->test_name ) {
    $message = "$name: $message" unless $message =~ /\b$name\b/;
  }

  return $message;
}

sub _prepend_class_name {
  my ($class, $message) = @_;

  $message = '' unless defined $message;

  if ( my ($name) = $class =~ /(\w+)$/ ) {
    $message = "$name: $message" unless $message =~ /\b$name\b/;
  }

  return $message;
}

sub initialize {}
sub finalize {}

1;

__END__

=head1 NAME

Test::Classy::Base

=head1 SYNOPSIS

  package MyApp::Test::ForSomething;
  use Test::Classy::Base;

  __PACKAGE__->mk_classdata('model');

  sub initialize {
    my $class = shift;

    eval { require 'Some::Model'; };
    $class->skip_this_class('Some::Model is required') if $@;

    my $model = Some::Model->connect;

    $class->model($model);
  }

  sub mytest : Test {
    my $class = shift;
    ok $class->model->find('something'), $class->message('works');
  }

  sub half_baked : Tests(2) {
    my $class = shift;

    pass $class->message('this test');

    return $class->abort_this_test('for some reason');

    fail $class->message('this test');
  }

  sub finalize {
    my $class = shift;
    $class->model->disconnect if $class->model;
    $class->model(undef);
  }

=head1 DESCRIPTION

This is a base class for actual tests. See L<Test::Classy> for basic usage.

=head1 CLASS METHODS

=head2 skip_this_class ( skip_the_rest -- deprecated )

If you called this with a reason why you want to skip (unsupported OS or lack of modules, for example), all the tests in the package will be skipped. Note that this is only useful in the initialize phase. You need to use good old 'skip' and 'Skip:' block when you want to skip some of the tests in a test unit.

  sub some_test : Tests(2) {
    my $class = shift;

    pass 'this test passes';

    Skip: {
      eval "require something";

      skip $@, 1 if $@;

      fail 'this may fail sometimes';
    }
  }

=head2 skip_this_test, abort_this_test

That said, 'skip' and 'Skip:' block may be a bit cumbersome especially when you just want to skip the rest of a test (as this is a unit test, you usually don't need to continue to test the rest of the unit test when you skip).

With 'skip_this_test' or 'abort_this_test', you can rewrite the above example like this:

  sub some_test : Tests(2) {
    my $class = shift;

    pass 'this test passes';

    eval "require something";

    return $class->abort_this_test($@) if $@;

    fail 'this may fail sometimes';
  }

Note that you need to 'return' actually to abort.

=head2 initialize

This is called before the tests run. You might want to set up database or something like that here. You can store initialized thingy as a class data (via Class::Data::Inheritable), or as a package-wide variable, maybe. Note that you can set up thingy in a test script and pass it as an argument for each of the tests instead.

=head2 finalize

This method is (hopefully) called when all the tests in the package are done. You might also want provide END/DESTROY to clean up thingy when the tests should be bailed out.

=head2 test_name

returns the name of the test running currently. Handy to write a meaningful test message.

=head2 message

prepends the last bit of the class name, and the test name currently running if any, to a message.

=head2 dump

dumps the content of arguments with Data::Dump::dump as a diagnostic message.

=head1 NOTES FOR INHERITING TESTS

You may want to let tests inherit some base class (especially to reuse common initialization/finalization). You can use good old base.pm (or parent.pm) to do this, though you'll need to use Test::More and the likes explicitly as base.pm doesn't export things:

  package MyApp::Test::Base;
  use Test::Classy::Base;
  use MyApp::Model;

  __PACKAGE__->mk_classdata('model');

  sub initialize {
    my $class = shift;

    $class->model( MyApp::Model->new );
  }

  package MyApp::Test::Specific;
  use base qw( MyApp::Test::Base );
  use Test::More;  # you'll need this.

  sub test : Test { ok shift->model->does_fine; }

You also can add 'base' option while using your base class. In this case, all the methods will be exported.

  package MyApp::Test::Specific;
  use MyApp::Test::Base 'base';

  sub test : Test { ok shift->model->does_fine; }

When your base class has some common tests to be inherited, and you don't want them to be tested in the base class, add 'ignore_me' (or 'ignore') option when you use Test::Classy::Base:

  package MyApp::Test::AnotherBase;
  use Test::Classy::Base 'ignore_me';

  sub not_for_base : Test { pass 'for children only' };

=head1 CAVEATS

Beware if you want to inherit only some of the tests from a base class (to remove or replace others). All the tests with a C<Test(s)> attribute will be counted while calculating the test plan (i.e. both the ones to replace and the ones to be replaced will be counted). The simplest remedy to avoid a plan error is to use C<no_plan> obviously, but you may find it better to split the class into the mandatory one, and the one which may be skipped while initializing.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
