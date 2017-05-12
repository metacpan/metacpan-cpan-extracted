package MooseX::Test::Role;

our $VERSION = '0.07';

use strict;
use warnings;

use Carp qw( confess );
use Class::Load qw( try_load_class );
use List::Util qw( first );
use Test::Builder;

use Exporter qw( import unimport );
our @EXPORT = qw( requires_ok consumer_of consuming_object consuming_class );

sub requires_ok {
    my ( $role, @required ) = @_;
    my $msg = "$role requires " . join( ', ', @required );

    my $role_type = _derive_role_type($role);
    if (!$role_type) {
        ok( 0, $msg );
        return;
    }

    foreach my $req (@required) {
        unless ( first { $_ eq $req } _required_methods($role_type, $role) ) {
            ok( 0, $msg );
            return;
        }
    }
    ok( 1, $msg );
}

sub consuming_class {
    my ( $role, %args ) = @_;

    my %methods = exists $args{methods} ? %{ $args{methods} } : ();

    my $role_type = _derive_role_type($role);
    confess 'first argument should be a role' unless $role_type;

    my $package = _package_name();
    _add_methods(
        package   => $package,
        role_type => $role_type,
        role      => $role,
        methods   => \%methods,
    );

    _apply_role(
        package   => $package,
        role_type => $role_type,
        role      => $role,
    );

    return $package;
}

sub consuming_object {
    my $class = consuming_class(@_);

    # Moose and Moo can be instantiated and should be. Role::Tiny however isn't
    # a full OO implementation and so doesn't provide a "new" method.
    return $class->can('new') ? $class->new() : $class;
}

sub consumer_of {
    my ( $role, %methods ) = @_;

    confess 'first argument to consumer_of should be a role' unless _derive_role_type($role);

    return consuming_object( $role, methods => \%methods );
}

sub _required_methods {
    my ($role_type, $role) = @_;
    my @methods;

    if ($role_type eq 'Moose::Role') {
        @methods = $role->meta->get_required_method_list();
    }
    elsif ($role_type eq 'Role::Tiny') {
        my $info = _role_tiny_info($role);
        if ($info && ref($info->{requires}) eq 'ARRAY') {
            @methods = @{$info->{requires}};
        }
    }

    return wantarray ? @methods : \@methods;
}

sub _derive_role_type {
    my $role = shift;

    try_load_class($role);

    if ($role->can('meta') && $role->meta()->isa('Moose::Meta::Role')) {
        # Also covers newer Moo::Roles
        return 'Moose::Role';
    }

    if (try_load_class('Role::Tiny') && _role_tiny_info($role)) {
        # Also covers older Moo::Roles
        return 'Role::Tiny';
    }

    return;
}

my $package_counter = 0;
sub _package_name {
    return 'MooseX::Test::Role::Consumer' . $package_counter++;
}

sub _apply_role {
    my %args = @_;

    my $package   = $args{package};
    my $role_type = $args{role_type};
    my $role      = $args{role};

    # We'll need a thing that exports a "with" sub
    my $with_exporter;
    if ($role_type eq 'Moose::Role') {
        $with_exporter = 'Moose';
    }
    elsif ($role_type eq 'Role::Tiny') {
        $with_exporter = 'Role::Tiny::With';
    }
    else {
        confess "Unknown role type $role_type";
    }

    my $source = qq{
        package $package;

        use $with_exporter;
        with('$role');
    };

    #warn $source;

    eval($source);
    die $@ if $@;

    return $package;
}

sub _add_methods {
    my %args = @_;

    my $role_type = $args{role_type};
    my $package   = $args{package};
    my $role      = $args{role};
    my $methods   = $args{methods};

    $methods->{$_} ||= sub { undef } for _required_methods( $role_type, $role );

    my $meta;
    $meta = Moose::Meta::Class->create($package) if $role_type eq 'Moose::Role';

    while ( my ( $method, $subref ) = each(%{$methods}) ) {
        # This allows us to have scalar values without an anonymous sub in the
        # definition, similar to Moose's default values. We need to make a lexical
        # copy of $subref so we do not build a circle where we return itself as a
        # coderef later on.
        if ( !ref $subref ) {
            my $value = $subref;
            $subref = sub { $value };
        }

        if ($meta) {
            $meta->add_method($method => $subref);
        }
        else {
            no strict 'refs';
            #no warnings 'redefine';
            *{ $package . '::' . $method } = $subref;
        }
    }

    return;
}

sub _role_tiny_info {
    # This seems brittle, but there aren't many options to get this data.
    # Moo relies on %INFO too, so it seems like it would be a hard thing
    # for to move away from.

    my $role = shift;
    return $Role::Tiny::INFO{$role};
}

my $Test = Test::Builder->new();

# Done this way for easier testing
our $ok = sub { $Test->ok(@_) };
sub ok { $ok->(@_) }

1;

=pod

=head1 NAME

MooseX::Test::Role - Test functions for Moose roles

=head1 SYNOPSIS

    use MooseX::Test::Role;
    use Test::More tests => 3;

    requires_ok('MyRole', qw/method1 method2/);

    my $consumer = consuming_object(
        'MyRole',
        methods => {
            method1 => 1,
            method2 => sub { shift->method1() },
        }
    );
    ok( $consumer->myrole_method );
    is( $consumer->method1, 1 );
    is( $consumer->method2, 1 );

    my $consuming_class = consuming_class('MyRole');
    ok( $consuming_class->class_method() );

=head1 DESCRIPTION

Provides functions for testing roles. Supports roles created with
L<Moose::Role>, L<Moo::Role> or L<Role::Tiny>.

=head1 BACKGROUND

Unit testing a role can be hard. A major problem is creating classes that
consume the role.

One could side-step the problem entirely and just call the subroutines in the
role's package directly. For example,

  Fooable->bar();

That only works until C<Fooable> calls another method in the consuming class
though. Mock objects are a tempting way to solve that problem:

  my $consumer = Test::MockObject->new();
  $consumer->set_always('baz', 1);
  Fooable::bar($consumer);

But if C<Fooable::bar> happens to call another method in the role then
the mock consumer will have to mock that method too.

A better way is to create a class to consume the role:

  package FooableTest;

  use Moose;
  with 'Fooable';

  sub required_method {}

  package main;

  my $consumer = FooableTest->new();
  $consumer->bar();

This can work well for some roles. Unfortunately, if several variations have to
be tested, it may be necessary to create several consuming test classes, which
gets tedious.

Moose can create anonymous classes which consume roles:

    my $consumer = Moose::Meta::Class->create_anon_class(
        roles   => ['Fooable'],
        methods => {
            required_method => sub {},
        }
    )->new_object();
    $consumer->bar();

This can still be tedious, especially for roles that require lots of methods.
C<MooseX::Test::Role> simply makes this easier to do.

=head1 EXPORTED FUNCTIONS

=over 4

=item C<consuming_class($role, methods => \%methods)>

Creates a class which consumes the role, and returns it's package name.

C<$role> must be the package name of a role. L<Moose::Role>, L<Moo::Role> and
L<Role::Tiny> are supported.

Any method required by the role will be stubbed. To override the default stub
methods, or to add additional methods, specify the name and a coderef:

    consuming_class('MyRole',
        method1 => sub { 'one' },
        method2 => sub { 'two' },
        required_method => sub { 'required' },
    );

For methods that should just return a fixed scalar value, you can ommit the
coderef.

    consuming_class('MyRole',
        method1    => 'one',
        method_uc1 => sub {
            my ($self) = @_;
            lc $self->one;
        },
    );

=item C<consuming_object($role, methods => \%methods)>

Creates a class which consumes the role, and returns an instance of it.

If the class does not have a C<new()> method (which is commonly the case for
L<Role::Tiny>), then the package name will be returned instead.

See C<consuming_class> for arguments. C<consuming_object> is essentially
equivalent to:

    consuming_class(@_)->new();

=item C<consumer_of ($role, %methods)>

Alias of C<consuming_object>, without named arguments. This is left in for
compatibility, new code should use C<consuming_object>.

=item C<requires_ok ($role, @methods)>

Tests if role requires one or more methods.

=back

=head1 GITHUB

Patches, comments or mean-spirited code reviews are all welcomed on GitHub:

L<https://github.com/pboyd/MooseX-Test-Role>

=head1 AUTHOR

Paul Boyd <boyd.paul2@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
