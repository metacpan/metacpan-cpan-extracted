#!/usr/bin/perl -c

package Test::Builder::Mock::Class;

=head1 NAME

Test::Builder::Mock::Class - Simulating other classes for Test::Builder

=head1 SYNOPSIS

  use Test::Builder::Mock::Class ':all';
  use Test::More 'no_plan';

  # concrete mock class
  mock_class 'Net::FTP' => 'Net::FTP::Mock';
  my $mock_object1 = Net::FTP::Mock->new;
  $mock_object1->mock_tally;

  # anonymous mocked class
  my $metamock2 = mock_anon_class 'Net::FTP';
  my $mock_object2 = $metamock2->new_object;
  $mock_object2->mock_tally;

  # anonymous class with role applied
  my $metamock3 = Test::Builder::Mock::Class->create_mock_anon_class(
      class => 'Net::FTP',
      roles => [ 'My::Handler::Role' ],
  );
  my $mock_object3 = $metamock3->new_object;
  $mock_object3->mock_tally;

=head1 DESCRIPTION

This module adds support for standard L<Test::Builder> framework
(L<Test::Simple> or L<Test::More>) to L<Test::Mock::Class>.

Mock class can be used to create mock objects which can simulate the behavior
of complex, real (non-mock) objects and are therefore useful when a real
object is impractical or impossible to incorporate into a unit test.

See L<Test::Mock::Class> for more detailed documentation.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0203';

use Moose;



=head1 INHERITANCE

=over 2

=item *

extends L<Moose::Meta::Class>

=cut

extends 'Moose::Meta::Class';

=item *

with L<Test::Builder::Mock::Class::Role::Meta::Class>

=back

=cut

with 'Test::Builder::Mock::Class::Role::Meta::Class';


use namespace::clean -except => 'meta';


=head1 FUNCTIONS

=over

=cut

BEGIN {
    my %exports = ();

=item B<mock_class>( I<class> : Str, I<mock_class> : Str = undef ) : Moose::Meta::Class

Creates the concrete mock class based on original I<class>.  If the name of
I<mock_class> is undefined, its name is created based on name of original
I<class> with added C<::Mock> suffix.

The function returns the metaclass object of new I<mock_class>.

=cut

    $exports{mock_class} = sub {
        sub ($;$) {
            return __PACKAGE__->create_mock_class(
                defined $_[1] ? $_[1] : $_[0] . '::Mock',
                class => $_[0],
            );
        };
    };

=item B<mock_anon_class>( I<class> : Str = undef ) : Moose::Meta::Class

Creates an anonymous mock class based on original I<class>.  The name of this
class is automatically generated.  If I<class> argument not defined, the empty
mock class is created.

The function returns the metaobject of new mock class.

=back

=cut

    $exports{mock_anon_class} = sub {
        sub (;$) {
            return __PACKAGE__->create_mock_anon_class(
                defined $_[0] ? (class => $_[0]) : (),
            );
        };
    };

=head1 IMPORTS

=over

=cut

    my %groups = ();

=item Test::Builder::Mock::Class ':all';

Imports all functions into caller's namespace.

=back

=cut

    $groups{all} = [ keys %exports ];

    require Sub::Exporter;
    Sub::Exporter->import(
        -setup => {
            exports => [ %exports ],
            groups => \%groups,
        },
    );
};


1;


=begin umlwiki

= Class Diagram =

[                           Test::Builder::Mock::Class
 ------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------
 <<utility>> mock_class( class : Str, mock_class : Str = undef ) : Moose::Meta::Class
 <<utility>> mock_anon_class( class : Str ) : Moose::Meta::Class
                                                                                     ]

[Test::Builder::Mock::Class] ---|> [Moose::Meta::Class] [<<role>> Test::Builder::Mock::Class::Role::Meta::Class]

=end umlwiki

=head1 EXAMPLE

The C<Test::Builder::Mock::Class> fits perfectly to L<Test::Builder>
(L<Test::Simple> or L<Test::More>) tests. It adds automatically the tests for
each C<mock_invoke> (which is called implicitly by all mock methods) and
C<mock_tally>.  It means that you need to add these tests to your test plan.

Example code:

  package My::ExampleTest;

  use Test::More 'no_plan';
  use Test::Builder::Mock::Class ':all';

  require 'IO::File';
  my $mock = mock_anon_class 'IO::File';
  my $io = $mock->new_object;
  $io->mock_return( open => 1, args => [qr//, 'r'] );

  ok( $io->open('/etc/passwd', 'r'), '$io->open' );
  $io->mock_tally;

=head1 BUGS

L<Moose> after version 1.05 calls C<BUILDALL> method automatically, so this
is one more test to whole plan.

L<Test::More> needs an exact count of all tests and it will be different for
L<Moose> before and after version 1.05.  There are following workarounds:

  # No plan at all
  use Test::More 'no_plan';

  # Different plans depend on Moose version
  use Test::More;
  require Moose;
  plan tests => (Moose->VERSION >= 1.05 ? 10 : 8);

  # Require Moose >= 1.05
  use Moose 1.05 ();
  use Test::More tests => 10;

=head1 SEE ALSO

Mock metaclass API: L<Test::Builder::Mock::Class::Role::Meta::Class>,
L<Moose::Meta::Class>.

Mock object methods: L<Test::Builder::Mock::Class::Role::Object>.

Perl standard testing: L<Test::Builder>, L<Test::Simple>, L<Test::More>.

Mock classes for xUnit-like testing (L<Test::Unit::Lite>):
L<Test::Mock::Class>.

Other implementations: L<Test::MockObject>, L<Test::MockClass>.

=for readme continue

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Based on SimpleTest, an open source unit test framework for the PHP
programming language, created by Marcus Baker, Jason Sweat, Travis Swicegood,
Perrick Penet and Edward Z. Yang.

Copyright (c) 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under GNU Lesser General Public License.
