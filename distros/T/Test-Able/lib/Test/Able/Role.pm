package Test::Able::Role;

use Moose::Role;
use Moose::Exporter;
use Moose::Util::MetaRole;
use strict;
use Test::Able::Role::Meta::Method;
use warnings;

=head1 NAME

Test::Able::Role -The Test::Able Role

=head1 SYNOPSIS

 package MyTest::SomeRole;

 use Test::Able::Role;

 test some_test => sub {};

=head1 DESCRIPTION

This is the Test::Able Role.  It is an extension of Moose::Role in the same
way as Test::Able is an extension of Moose for the purpose of handling
test-related methods.

=head1 EXPORTED FUNCTIONS

In addition to exporting for Moose::Role, Test::Able::Role will export a
handful of functions that can be used to declare test-related methods.
These functions are the same functions that Test::Able exports.

=cut

Moose::Exporter->setup_import_methods(
    with_caller => [
        qw( startup setup test teardown shutdown ),
    ],
    also => 'Moose::Role',
);

sub init_meta {
    shift;
    my %options = @_;

    my $m = Moose::Role->init_meta( %options, );

    return Moose::Util::MetaRole::apply_metaroles(
        for            => $options{for_class},
        role_metaroles => {
            method     => [ 'Test::Able::Role::Meta::Method', ],
        },
    );
}

=over

=item startup/setup/test/teardown/shutdown

A more Moose-like way to do method declaration.  The syntax is similar to
L<Moose/has> except its for test-related methods.

These start with one of startup/setup/test/teardown/shutdown depending on what
type of method you are defining.  Then comes any attribute name/value pairs to
set in the L<Test::Able::Role::Meta::Method>-based mehod metaclass object.
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

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
