package MooseX::Aliases;
BEGIN {
  $MooseX::Aliases::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Aliases::VERSION = '0.11';
}
use Moose 2.0000 ();
use Moose::Exporter;
use Scalar::Util qw(blessed);
# ABSTRACT: easy aliasing of methods and attributes in Moose


my %metaroles = (
    class_metaroles => {
        class     => ['MooseX::Aliases::Meta::Trait::Class'],
        attribute => ['MooseX::Aliases::Meta::Trait::Attribute'],
    },
    role_metaroles => {
        role =>
            ['MooseX::Aliases::Meta::Trait::Role'],
        application_to_class =>
            ['MooseX::Aliases::Meta::Trait::Role::ApplicationToClass'],
        application_to_role =>
            ['MooseX::Aliases::Meta::Trait::Role::ApplicationToRole'],
        applied_attribute =>
            ['MooseX::Aliases::Meta::Trait::Attribute'],
    },
);

Moose::Exporter->setup_import_methods(
    with_meta => ['alias'],
    %metaroles,
);

sub _get_method_metaclass {
    my ($method) = @_;

    my $meta = Class::MOP::class_of($method);
    if ($meta->can('does_role')
     && $meta->does_role('MooseX::Aliases::Meta::Trait::Method')) {
        return blessed($method);
    }
    else {
        return Moose::Meta::Class->create_anon_class(
            superclasses => [blessed($method)],
            roles        => ['MooseX::Aliases::Meta::Trait::Method'],
            cache        => 1,
        )->name;
    }
}


sub alias {
    my ( $meta, $alias, $orig ) = @_;
    my $method = $meta->find_method_by_name($orig);
    if (!$method) {
        $method = $meta->find_method_by_name($alias);
        if ($method) {
            Carp::cluck(
                q["alias $from => $to" is deprecated, please use ]
              . q["alias $to => $from"]
            );
            ($alias, $orig) = ($orig, $alias);
        }
    }
    Moose->throw_error("Cannot find method $orig to alias") unless $method;
    $meta->add_method(
        $alias => _get_method_metaclass($method)->wrap(
            sub { shift->$orig(@_) }, # goto $_[0]->can($orig) ?
            package_name => $meta->name,
            name         => $alias,
            aliased_from => $orig
        )
    );
}


1;

__END__

=pod

=head1 NAME

MooseX::Aliases - easy aliasing of methods and attributes in Moose

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use MooseX::Aliases;

    has this => (
        isa   => 'Str',
        is    => 'rw',
        alias => 'that',
    );

    sub foo { my $self = shift; print $self->that }
    alias bar => 'foo';

    my $o = MyApp->new();
    $o->this('Hello World');
    $o->bar; # prints 'Hello World'

or

    package MyApp::Role;
    use Moose::Role;
    use MooseX::Aliases;

    has this => (
        isa   => 'Str',
        is    => 'rw',
        alias => 'that',
    );

    sub foo { my $self = shift; print $self->that }
    alias bar => 'foo';

=head1 DESCRIPTION

The MooseX::Aliases module will allow you to quickly alias methods in Moose. It
provides an alias parameter for C<has()> to generate aliased accessors as well
as the standard ones. Attributes can also be initialized in the constructor via
their aliased names.

You can create more than one alias at once by passing a arrayref:

    has ip_addr => (
        alias => [ qw(ipAddr ip) ],
    );

=head1 FUNCTIONS

=head2 alias ALIAS METHODNAME

Installs ALIAS as a method that is aliased to the method METHODNAME.

=head1 ALIASING VERSUS OTHER MOOSE FEATURES

=head2 Aliasing versus inheritance

    {
        package Parent;
        use Moose;
        use MooseX::Aliases;
        sub method1 { "A" }
        alias method2 => "method1";
    }

    {
        package Child1;
        use Moose;
        extends "Parent";
        sub method1 { "B" }
    }

    {
        package Child2;
        use Moose;
        extends "Parent";
        sub method2 { "C" }
    }

In the example above, Child1 overrides the method using its
original name (C<method1>). As a result, calling C<method1> or
C<method2> returns "B". Child2 overrides the method using its
alias (C<method2>). As a result, calling C<method2> returns "C",
but calling C<method1> falls through to the parent class, so
returns "A".

=head2 Aliasing versus method modifiers

    {
        package Class1;
        use Moose;
        use MooseX::Aliases;
        sub method1 { "A" }
        alias method2 => "method1";
        around method1 => sub { "B" };
    }

    {
        package Class2;
        use Moose;
        use MooseX::Aliases;
        sub method1 { "A" }
        alias method2 => "method1";
        around method2 => sub { "B" };
    }

In the example above, Class1's around modifier modifies the
method using its original name. As a result, both C<method1>
and C<method2> return "B". Class2's around modifier modifies
the alias, so C<method2> returns "B", but C<method1> continues
to return "A".

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/moosex-aliases/issues>.

=head1 SEE ALSO

L<Method::Alias>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Aliases

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/MooseX-Aliases>

=item * Github

L<https://github.com/doy/moosex-aliases>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Aliases>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Aliases>

=back

=head1 AUTHORS

=over 4

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Chris Prather <chris@prather.org>

=item *

Justin Hunter <justin.d.hunter@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
