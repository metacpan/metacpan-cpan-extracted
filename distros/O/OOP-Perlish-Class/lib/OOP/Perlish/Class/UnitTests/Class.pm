#!/usr/bin/perl
use warnings;
use strict;
{
    package OOP::Perlish::Class::UnitTests::Class;
    use warnings;
    use strict;
    use OOP::Perlish::Class::UnitTests::Base;
    use base qw(OOP::Perlish::Class::UnitTests::Base);
    use Test::More;

    sub setup : Test(setup)
    {
        my ($self) = @_;
        undef $@;
    }

    sub class_assignment : Test(1)
    {
        my ($self) = @_;

        my $f = OOP::Perlish::Class::UnitTests::Foo->new();
        $f->foo("Hello foo!");
        is($f->foo(), 'Hello foo!', 'Class assignment');
    }

    sub multiple_classes : Test(2)
    {
        my ($self) = @_;

        my $f = OOP::Perlish::Class::UnitTests::Foo->new();
        $f->foo("Hello foo!");

        my $b = OOP::Perlish::Class::UnitTests::Bar->new();
        $b->foo("Goodbye Ralph!");
        is($f->foo(), 'Hello foo!', 'Multiple classes');
        is($b->foo(), 'Goodbye Ralph!', 'Multiple classes');
    }

    sub multiple_instances : Test(2)
    {
        my ($self) = @_;

        my $f = OOP::Perlish::Class::UnitTests::Foo->new();
        $f->foo("Hello foo!");

        my $ff = OOP::Perlish::Class::UnitTests::Foo->new();
        $ff->foo("foo is the fooyist!");
        is($f->foo(), 'Hello foo!', 'Multiple instances');
        is($ff->foo(), 'foo is the fooyist!', 'Multiple instances');
    }

    sub inheritance : Test(2)
    {
        my ($self) = @_;

        my $fb = OOP::Perlish::Class::UnitTests::Bar::Bar->new( bar => { dodad => 'bars are great' }, foo => 'Ralph is pretty good too' );

        is($fb->foo(), 'Ralph is pretty good too', 'inheritance, we have foo');
        is($fb->bar()->{dodad}, 'bars are great', 'inheritance, we have bar');
    }

    sub overload_uniqueness : Test(4)
    {
        my ($self) = @_;

        my $bfb = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar->new( bar => 'bar', foo => 'foo');
        my $bfbo = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar::Overload->new( bar => 'Bar overloaded!' );

        is($bfb->foo(), 'foo', 'Multiple inheritance with overloading, non-overloaded foo');
        is($bfb->bar(), 'bar', 'Multiple inheritance with overloading, non-overloaded bar');
        is($bfb->baz(), 'baz', 'Multiple inheritance with overloading, non-overloaded baz');

        is($bfbo->bar(), 'Bar overloaded!', 'Multiple inheritance with overloading, overloaded bar');
    }

    sub overload_uniqueness_reverse : Test(4)
    {
        my ($self) = @_;

        my $bfbo = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar::Overload->new( bar => 'Bar overloaded!' );
        my $bfb = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar->new( bar => 'bar', foo => 'foo');

        is($bfb->foo(), 'foo', 'Multiple inheritance with overloading, non-overloaded foo');
        is($bfb->bar(), 'bar', 'Multiple inheritance with overloading, non-overloaded bar');
        is($bfb->baz(), 'baz', 'Multiple inheritance with overloading, non-overloaded baz');

        is($bfbo->bar(), 'Bar overloaded!', 'Multiple inheritance with overloading, overloaded bar');
    }

    sub multiple_inheritance : Test(3)
    {
        my ($self) = @_;

        my $bfb = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar->new( bar => 'bar', foo => 'foo');
        is($bfb->foo(), 'foo', 'Multiple inheritance, foo');
        is($bfb->bar(), 'bar', 'Multiple inheritance, bar');
        is($bfb->baz(), 'baz', 'Multiple inheritance, baz');
    }


    sub value_set_derived : Test(2)
    {
        my ($self) = @_;

        my $fred = OOP::Perlish::Class::UnitTests::Fred->new( bar => 'set this' );
        ok( $fred->can('find'), 'Inherited from non-derived class' );
        is($fred->bar(), 'set this', 'Value set on accessor still valid on derivded-class' );
    }

    sub valid_defaults : Test(6)
    {
        my ($self) = @_;

        my $obj;

        eval { 
            $obj = OOP::Perlish::Class::UnitTests::TestValidDefaults->new();
        };
        ok( ! "$@", 'did not croak on instantiation' );

        is( $obj->scalar(), 'test', 'scalar default' );
        is( ($obj->array())[0], 'test', 'array default' );
        is( { ($obj->hash()) }->{key}, 'test', 'hash default' );
        is( $obj->code()->(), 'test', 'code default' );
        ok( UNIVERSAL::isa($obj->object(), 'IO::File'), 'object default' );
    }

    sub invalid_defaults 
    {
        my ($self, $type) = @_;
        my $classname = 'OOP::Perlish::Class::UnitTests::TestInvalidDefault' . ucfirst(lc($type)); 

        my $obj;

        eval { 
            $obj = $classname->new();
        };
        ok( "$@", 'did croak on instantiation' );
        ok( "$@" =~ m/\Q$type\E/i, 'we saw the error we wanted' );
        ok( "$@" =~ m#\QOOP::Perlish::Class::Accessor#gsim, 'we died from OOP::Perlish::Class::Accessor' ) || diag("$@");
        ok( ! $obj, 'did not initialize' )
    }

    sub invalid_defaults_scalar : Test(4)
    {
        my ($self) = @_;
        $self->invalid_defaults('scalar');
    }

    sub invalid_defaults_array : Test(4)
    {
        my ($self) = @_;
        $self->invalid_defaults('array');
    }

    sub invalid_defaults_hash : Test(4)
    {
        my ($self) = @_;
        $self->invalid_defaults('hash');
    }

    sub invalid_defaults_code : Test(4)
    {
        my ($self) = @_;
        $self->invalid_defaults('code');
    }

    sub invalid_defaults_object : Test(4)
    {
        my ($self) = @_;
        $self->invalid_defaults('object');
    }

    sub method_overload_of_accessor : Test(1)
    {
        my ($self) = @_;

        my $obj = OOP::Perlish::Class::UnitTests::TestAccessorOverloadingWithMethod->new( fud => 'bar' );
        is( $obj->fud(), 'method, not accessor', 'we can successfully overload an accessor with a method' );
    }

    sub method_overload_of_accessor_is_still_required : Test(2)
    {
        my ($self) = @_;
        eval { 
            my $obj = OOP::Perlish::Class::UnitTests::TestAccessorOverloadingWithMethod->new();
        };

        ok( "$@", 'We died, presumably because of the missing required' );
        ok( "$@" =~ m/Missing required/, 'Yep, missing required' );
    }

    sub accessor_required : Test(2)
    {
        my ($self) = @_;
        eval { 
            my $obj = OOP::Perlish::Class::UnitTests::TestRequired->new();
        };

        ok( "$@", 'We died, presumably because of the missing required' );
        ok( "$@" =~ m/Missing required/, 'Yep, missing required' );
    }

}
1;

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS

=head1 METHODS

=head1 AUTHOR

Jamie Beverly, C<< <jbeverly at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-foo-bar at rt.cpan.org>,
or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OOP-Perlish-Class>.  I will be
notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OOP::Perlish::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OOP-Perlish-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OOP-Perlish-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OOP-Perlish-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/OOP-Perlish-Class/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jamie Beverly

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
