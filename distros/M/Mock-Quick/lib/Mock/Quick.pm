package Mock::Quick;
use strict;
use warnings;
use Exporter::Declare;
use Mock::Quick::Class;
use Mock::Quick::Object;
use Mock::Quick::Object::Control;
use Mock::Quick::Method;
use Mock::Quick::Util;
use Carp qw/carp/;

our $VERSION = '1.111';

import_arguments qw/intercept/;

sub after_import {
    my $class = shift;
    my ( $importer, $specs ) = @_;

    return unless $specs->config->{intercept};

    my $intercept = $specs->config->{intercept};
    no strict 'refs';
    *{"$importer\::QINTERCEPT"} = sub { $intercept };
}

my %CLASS_RELATED = (
    qclass     => 'new',
    qtakeover  => 'takeover',
    qimplement => 'implement',
);

for my $operation ( keys %CLASS_RELATED ) {
    my $meth = $CLASS_RELATED{$operation};

    default_export $operation => sub {
        my @args = @_;

        return Mock::Quick::Class->$meth(@args)
            if defined wantarray;

        my $caller = caller;
        return $caller->QINTERCEPT->(sub { Mock::Quick::Class->$meth(@args) })
            if $caller->can( 'QINTERCEPT' );

        carp "Return value is ignored, your mock is destroyed as soon as it is created.";
    };
}

default_export qcontrol => sub { Mock::Quick::Object::Control->new(@_) };

default_export qobj => sub {
    my $obj     = Mock::Quick::Object->new(@_);
    my $control = Mock::Quick::Object::Control->new($obj);
    $control->strict(0);
    return $obj;
};

default_export qobjc => sub {
    my $obj     = Mock::Quick::Object->new(@_);
    my $control = Mock::Quick::Object::Control->new($obj);
    $control->strict(0);
    return ( $obj, $control );
};

default_export qstrict => sub {
    my $obj     = Mock::Quick::Object->new(@_);
    my $control = Mock::Quick::Object::Control->new($obj);
    $control->strict(1);
    return $obj;
};

default_export qstrictc => sub {
    my $obj     = Mock::Quick::Object->new(@_);
    my $control = Mock::Quick::Object::Control->new($obj);
    $control->strict(1);
    return ( $obj, $control );
};

default_export qclear => sub    { \$Mock::Quick::Util::CLEAR };
default_export qmeth  => sub(&) { Mock::Quick::Method->new(@_) };

purge_util();

1;

__END__

=pod

=head1 NAME

Mock::Quick - Quickly mock objects and classes, even temporarily replace them,
side-effect free.

=head1 DESCRIPTION

Mock-Quick is here to solve the current problems with Mocking libraries.

There are a couple Mocking libraries available on CPAN. The primary problems
with these libraries include verbose syntax, and most importantly side-effects.
Some Mocking libraries expect you to mock a specific class, and will unload it
then redefine it. This is particularly a problem if you only want to override
a class on a lexical level.

Mock-Quick provides a declarative mocking interface that results in a very
concise, but clear syntax. There are separate facilities for mocking object
instances, and classes. You can quickly create an instance of an object with
custom attributes and methods. You can also quickly create an anonymous class,
optionally inheriting from another, with whatever methods you desire.

Mock-Quick also provides a tool that provides an OO interface to overriding
methods in existing classes. This tool also allows for the restoration of the
original class methods. Best of all this is a localized tool, when your control
object falls out of scope the original class is restored.

=head1 SYNOPSIS

=head2 MOCKING OBJECTS

    use Mock::Quick;

    my $obj = qobj(
        foo => 'bar',            # define attribute
        do_it => qmeth { ... },  # define method
        ...
    );

    is( $obj->foo, 'bar' );
    $obj->foo( 'baz' );
    is( $obj->foo, 'baz' );

    $obj->do_it();

    # define the new attribute automatically
    $obj->bar( 'xxx' );

    # define a new method on the fly
    $obj->baz( qmeth { ... });

    # remove an attribute or method
    $obj->baz( qclear() );

=head2 STRICTER MOCK

    use Mock::Quick;

    my $obj = qstrict(
        foo => 'bar',            # define attribute
        do_it => qmeth { ... },  # define method
        ...
    );

    is( $obj->foo, 'bar' );
    $obj->foo( 'baz' );
    is( $obj->foo, 'baz' );

    $obj->do_it();

    # remove an attribute or method
    $obj->baz( qclear() );

You can no longer auto-vivify accessors and methods in strict mode:

    # Cannot define the new attribute automatically
    dies_ok { $obj->bar( 'xxx' ) };

    # Cannot define a new method on the fly
    dies_ok { $obj->baz( qmeth { ... }) };

In order to add methods/accessors you need to create a control object.

=head2 CONTROL OBJECTS

Control objects are objects that let you interface a mocked object. They let
you add attributes and methods, or even clear them. This is unnecessary unless
you use strict mocking, or choose not to import qmeth() and qclear().

=over 4

=item Take Control

    my $control = qcontrol( $obj );

=item Add Attributes

    $control->set_attributes(
        foo => 'bar',
        ...
    );

=item Add Methods

    $control->set_methods(
        do_it => sub { ... }, # No need to use qmeth()
        ...
    );

=item Clear Attributes/Methods

    $control->clear( qw/foo do_it .../ );

=item Toggle strict

    $control->strict( $BOOL );

=item Create With Control

    my $obj = qobj ...;
    my $obj = qstrict ...;
    my ( $obj,  $control  ) = qobjc ...;
    my ( $sobj, $scontrol ) = qstrictc ...;

=back

=head2 MOCKING CLASSES

B<Note:> the control object returned here is of type L<Mock::Quick::Class>,
whereas control objects for qobj style objects are of
L<Mock::Quick::Object::Control>.

=head3 IMPLEMENT A CLASS

This will implement a class at the namespace provided via the -implement
argument. The class must not already be loaded. Once complete the real class
will be prevented from loading until you call undefine() on the control object.

    use Mock::Quick;

    my $control = qclass(
        -implement => 'My::Package',

        # Insert a generic new() method (blessed hash)
        -with_new => 1,

        # Inheritance
        -subclass => 'Some::Class',
        # Can also do
        -subclass => [ 'Class::A', 'Class::B' ],

        # generic get/set attribute methods.
        -attributes => [ qw/a b c d/ ],

        # Method that simply returns a value.
        simple => 'value',

        # Custom method.
        method => sub { ... },
    );

    my $obj = $control->package->new;
    # OR
    my $obj = My::Package->new;

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Remove the namespace we created, which would allow the real thing to load
    # in a require or use statement.
    $control->undefine();

You can also use the qimplement() method instead of qclass:

    use Mock::Quick;

    my $control = qimplement 'Some::Package' => ( %args );

=head3 ANONYMOUS MOCKED CLASS

This is if you just need to generate a class where the package name does not
matter. This is done when the -takeover and -implement arguments are both
omitted.

    use Mock::Quick;

    my $control = qclass(
        # Insert a generic new() method (blessed hash)
        -with_new => 1,

        # Inheritance
        -subclass => 'Some::Class',
        # Can also do
        -subclass => [ 'Class::A', 'Class::B' ],

        # generic get/set attribute methods.
        -attributes => [ qw/a b c d/ ],

        # Method that simply returns a value.
        simple => 'value',

        # Custom method.
        method => sub { ... },
    );

    my $obj = $control->package->new;

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Remove the anonymous namespace we created.
    $control->undefine();

=head3 TAKING OVER EXISTING/LOADED CLASSES

    use Mock::Quick;

    my $control = qtakeover 'Some::Package' => ( %overrides );

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Destroy the control object and completely restore the original class
    # Some::Package.
    $control = undef;

You can also do this through qclass():

    use Mock::Quick;

    my $control = qclass(
        -takeover => 'Some::Package',
        %overrides
    );

=head1 METRICS

All control objects have a 'metrics' method. The metrics method returns a hash
where keys are method names, and values are the number of times the method has
been called. When a method is altered or removed the key is deleted.

Metrics only apply to mocked methods. When you takeover an already loaded class
metrics will only track overridden methods.

=head1 EXPORTS

Mock-Quick uses L<Exporter::Declare>. This allows for exports to be prefixed or renamed.
See L<Exporter::Declare/RENAMING IMPORTED ITEMS> for more information.

=over 4

=item $obj = qobj( attribute => value, ... )

=item ( $obj, $control ) = qobjc( attribute => value, ... )

Create an object. Every possible attribute works fine as a get/set accessor.
You can define other methods using qmeth {...} and assigning that to an
attribute. You can clear a method using qclear() as an argument.

See L<Mock::Quick::Object> for more.

=item $obj = qstrict( attribute => value, ... )

=item ( $obj, $control ) = qstrictc( attribute => value, ... )

Create a stricter object, get/set accessors will not autovivify into existence
for undefined attributes.

=item $control = qclass( -config => ..., name => $value || sub { ... }, ... )

Define an anonymous package with the desired methods and specifications.

See L<Mock::Quick::Class> for more.

=item $control = qclass( -takeover => $package, %overrides )

=item $control = qtakeover( $package, %overrides );

Take over an existing class.

See L<Mock::Quick::Class> for more.

=item $control = qimplement( $package, -config => ..., name => $value || sub { ... }, ... )

=item $control = qclass( -implement => $package, ... )

Implement the given package to specifications, altering %INC so that the real
class will not load. Destroying the control object will once again allow the
original to load.

=item qclear()

Returns a special reference that when used as an argument, will cause
Mock::Quick::Object methods to be cleared.

=item qmeth { my $self = shift; ... }

Define a method for an L<Mock::Quick::Object> instance.

default_export qcontrol   => sub { Mock::Quick::Object::Control->new( @_ ) };


=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

Ben Hengst L<notbenh@cpan.org>

=head1 CONTRIBUTORS

Contributors are listed as authors in modules they have touched.

=over 4

=item Ben Hengst L<notbenh@cpan.org>

=item Glen Hinkle L<glen@empireenterprises.com>

=back

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
