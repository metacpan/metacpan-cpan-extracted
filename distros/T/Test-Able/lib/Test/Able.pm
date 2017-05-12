package Test::Able;

use 5.008;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use strict;
use Test::Able::Object;
use Test::Able::Role::Meta::Class;
use Test::Able::Role::Meta::Method;
use warnings;

=head1 NAME

Test::Able - xUnit with Moose

=head1 VERSION

0.10

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

 package MyTest;

 use Test::Able;
 use Test::More;

 startup         some_startup  => sub { ... };
 setup           some_setup    => sub { ... };
 test plan => 1, foo           => sub { ok( 1 ); };
 test            bar           => sub {
     my @runtime_list = 1 .. 42;
     $_[ 0 ]->meta->current_method->plan( scalar @runtime_list );
     ok( 1 ) for @runtime_list;
 };
 teardown        some_teardown => sub { ... };
 shutdown        some_shutdown => sub { ... };

 MyTest->run_tests;

=head1 DESCRIPTION

An xUnit style testing framework inspired by L<Test::Class> and built using
L<Moose>.  It can do all the important things Test::Class can do and more.
The prime advantages of using this module instead of Test::Class are
flexibility and power.  Namely, Moose.

This module was created for a few of reasons:

=over

=item *

To address perceived limitations in, and downfalls of, Test::Class.

=item *

To leverage existing Moose expertise for testing.

=item *

To bring Moose to the Perl testing game.

=back

=head1 EXPORTED FUNCTIONS

In addition to exporting for Moose, Test::Able will export a handful
of functions that can be used to declare test-related methods.

=cut

Moose::Exporter->setup_import_methods(
    with_caller => [
        qw( startup setup test teardown shutdown ),
    ],
    also => 'Moose',
);

sub init_meta {
    shift;
    my %options          = @_;
    $options{base_class} = 'Test::Able::Object';

    Moose->init_meta( %options, );

    return Moose::Util::MetaRole::apply_metaroles(
        for             => $options{for_class},
        class_metaroles => {
            class       => [ 'Test::Able::Role::Meta::Class',  ],
            method      => [ 'Test::Able::Role::Meta::Method', ],
        },
    );
}

=over

=item startup/setup/test/teardown/shutdown

A more Moose-like way to do method declaration.  The syntax is similar to
L<Moose/has> except its for test-related methods.

These start with one of startup/setup/test/teardown/shutdown depending on what
type of method you are defining.  Then comes any attribute name/value pairs to
set in the L<Test::Able::Role::Meta::Method>-based method metaclass object.
The last pair must always be the method name and the coderef.  This is to
disambiguate between the method name/code pair and any another attribute in
the method metaclass that happens to take a coderef.  See the synopsis or the
tests for examples.

=back

=cut

sub startup  { return __add_method( type => 'startup',  @_, ); }
sub setup    { return __add_method( type => 'setup',    @_, ); }
sub test     { return __add_method( type => 'test',     @_, ); }
sub teardown { return __add_method( type => 'teardown', @_, ); }
sub shutdown { return __add_method( type => 'shutdown', @_, ); }

sub __add_method {
    my $class = splice( @_, 2, 1, );
    my ( $code, $name, ) = ( pop, pop, );

    my $meta = Moose::Meta::Class->initialize( $class, );
    $meta->add_method( $name, $code, );

    if ( @_ ) {
        my $method = $meta->get_method( $name, );
        my %args = @_;
        while ( my ( $k, $v ) = each %args ) {
            $method->$k( $v );
        }
    }

    return;
}

=head1 Overview

1. Build some test classes: a, b, & c.  The classes just have to be based on
Test::Able.

2. Fire up an instance of any of them to be the runner object.  Any test
object can serve as the test_runner_object including itself.

 my $b_obj = b->new;

3. Setup the test_objects in the test_runner_object.

 $b_obj->test_objects( [
     a->new,
     $b_obj,
     c->new,
 ] );

4. Do the test run.  The test_objects will be run in order.

 $b_obj->run_tests;

=head1 SEE ALSO

=over

=item L<Test::Able::Cookbook>

=item support

 #moose on irc.perl.org

=item code

 http://github.com/jdv/test-able/tree/master

=item L<Moose>

=item L<Test::Class>

=item L<Test::Builder>

=back

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
