package Test::Able::Cookbook;

use strict;
use warnings;

=head1 NAME

Test::Able::Cookbook

=head1 Recipes

=head2 Basics

=over

=item Dumping execution plan

 $ENV{ 'TEST_VERBOSE' } = 1;
 $t->meta->dry_run( 1 );
 $t->run_tests;

Does everything but call the test (startup/setup/test/teardown/shutdown)
methods and validate method plans.  And part of "everything" is logging the
execution plan with $t->meta->log.

=back

=head2 Altering Method Lists

Its not recommended to do any of this while a test run is in progress.
The BUILD method in the test class is the best place.

=over

=item Remove superclass methods

 use Test::Able::Helpers qw( prune_super_methods );
 $t->prune_super_methods;

Unlike Test::Class its very easy to shed the methods from superclasses.

=item Explicit set

 my @meth = sort { $a->name cmp $b->name } $t->meta->get_all_methods;
 $t->meta->startup_methods(  [ grep { $_->name =~ /^shutdown_/ } @meth ] );
 $t->meta->setup_methods(    [ grep { $_->name =~ /^teardown_/ } @meth ] );
 $t->meta->test_methods(     [ grep { $_->name =~ /^test_bar[14]/ } @meth ] );
 $t->meta->teardown_methods( [ grep { $_->name =~ /^setup_/ } @meth ] );
 $t->meta->shutdown_methods( [ grep { $_->name =~ /^startup_/ } @meth ] );

=item Ordering

 use Test::Able::Helpers qw( shuffle_methods );
 for ( 1 .. 10 ) {
     $t->shuffle_methods;
    $t->run_tests;
 }

Simple xUnit purity test.

=item Filtering

 $t->meta->test_methods(
     [ grep { $_->name !~ /bar/; } @{ $t->meta->test_methods } ]
 );

=back

=head2 Test Planning

=over

=item Setting method plan during test run

 test plan => "no_plan", new_test_method => sub {
     $_[ 0 ]->meta->current_method->plan( 7 );
     ok( 1 ) for 1 .. 7;
 };

This will force the whole plan to be recalculated.

=back

=head2 Advanced

=over

=item Explicit setup & teardown for "Loop-Driven testing"

 use Test::Able::Helpers qw( get_loop_plan );

 test do_setup => 0, do_teardown => 0, test_on_x_and_y_and_z => sub {
     my ( $self, ) = @_;

     my @x = qw( 1 2 3 );
     my @y = qw( a b c );
     my @z = qw( foo bar baz );

     $self->meta->current_method->plan(
         $self->get_loop_plan( 'test_bar1', @x * @y * @x, ),
     );

     for my $x ( @x ) {
         for my $y ( @y ) {
             for my $z ( @z ) {
                 $self->meta->run_methods( 'setup' );
                 $self->{ 'args' } = { x => $x, y => $y, z => $z, };
                 $self->test_bar1;
                 $self->meta->run_methods( 'teardown' );
             }
         }
     }

     return;
 };

Since we're running the setup and teardown method lists explicitly in the loop
it would be nice to have the option of not running them implicitly (the normal
behavior - see L<Test::Able::Role::Meta::Class/run_methods> ).  Setting
do_setup the do_teardown above to false is an easy way to accomplish just
that.

=back

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
