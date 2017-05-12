package Test::Able::Runner;
{
  $Test::Able::Runner::VERSION = '1.002';
}
use Moose;
use Test::Able ();
use Moose::Exporter;
use Moose::Util::MetaRole;

=head1 NAME

Test::Able::Runner - use Test::Able without a bunch of boilerplate

=head1 VERSION

version 1.002

=head1 SYNOPSIS

  use Test::Able::Runner;

  use_test_packages
      -base_package => 'My::Project::Test';

  run;

=head1 DESCRIPTION

I like L<Test::Able>. I really don't like having to copy my boilerplate test runner and modify it when I use it in a new project. This provides a basic test runner for your testable tests that takes care of the basics for you. You can extend it a bit to customize things if you like as well. Let me know if you want this to do something else.

This mostly assumes that you want to run several tests as a group within a single Perl interpreter. If this is not what you want, then you probably don't want this module.

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ 'run', 'use_test_packages' ],
    also      => 'Test::Able',
);

=head1 METHODS

=head2 use_test_packages

The first thing your test runner needs to do is call this method to tell it what packages need to be included in your test. 

=head2 COMMON CASES

Before describing the options, here are some examples of how to use this subroutine.

=head3 EXAMPLE 1

  use_test_packages
      -base_package => 'My::Project::Test',
      -test_path    => 't/lib';

This is pretty much the simplest case. This will load and run all the packages starting with the name "My::Project::Test" found in the project's F<t/lib> directory. I show the C<< -test_path >> option here, but in this case it's redundant. Your test path is assumed to be F<t/lib> in the usual case.

=head3 EXAMPLE 2

  use_test_packages
      -test_packages => [ qw(
          My::Project::Test::One
          My::Project::Test::Two
          My::Project::Test::Three
      ) ];

Rather than searching for any test packages you might have in your test folder, you might prefer to explicitly list them.

=head3 OPTIONS

=over

=item C<< -base_package >>

This is the package namespace to search for classes within. Any class found under this namespace (within any directory included in C<< -test_path >>) will be run in your tests. If you want to include classes under this base package namespace that are not tests (test roles or base classes or whatever), you may place a global package variable within the package named C<< $NOT_A_TEST >> and set it to a true value:

  package My::Project::Test::Base;
  use Test::Able;

  our $NOT_A_TEST = 1;

You may use this option or the C<< -test_packages >> option. This may be a single scalar package name

=item C<< -test_packages >>

This is the list of test packages to load and run. It is always given as an array of package names.

=item C<< -test_path >>

This is the search path for test classes. This lists additional paths that should be added to C<< @INC >> to search for tests before loading the tests. These paths are added to the front of C<< @INC >>.

It can be given as a single scalar or as an array of paths:

  use_test_packages
      -base_package => 'My::Project::Test',
      -test_path    => [ 't/online', 't/offline' ];

=back

=cut

sub use_test_packages {
    my $meta    = shift;
    my %options = @_;

    $meta->base_package( $options{-base_package} )
        if $options{-base_package};
    $meta->test_packages( $options{-test_packages} )
        if $options{-test_packages};
    $meta->test_path( $options{-test_path} )
        if $options{-test_path};
}

=head2 init_meta

Sets up your test runner package.

=cut

sub init_meta {
    my $class   = shift;
    my %options = @_;

    my $meta = Test::Able->init_meta(@_);

    Moose::Util::MetaRole::apply_metaroles(
        for             => $options{for_class},
        class_metaroles => {
            class => [ 'Test::Able::Runner::Role::Meta::Class' ],
        },
    );

    return $options{for_class}->meta;
}

=head2 run

This invokes the test runner for all the tests you've requested.

=cut

sub run {
    my $meta = shift;

    my $runner = $meta->name->new;
    $runner->meta->setup_test_objects;
    $runner->meta->run_tests;
}

=head1 COOKBOOK

Here are some other things you might like to try.

=head2 Test Runner Tests

The test runner itself may have tests if you want. The test runner classes uses the usual L<Test::Able> bits, so this works. Similarly, you can do setup, teardown, and all the rest in your runner.

  use Test::Able::Runner;

  use_test_packages
      -base_package => 'Foo::Test';

  test plan => 1, test_something => sub {
      ok(1);
  };

  run;

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Qubling Software LLC.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
