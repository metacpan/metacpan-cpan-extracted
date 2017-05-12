{
    package OOP::Perlish::Class::Abstract::UnitTests::MyAbstractClass;
    use warnings;
    use strict;
    use OOP::Perlish::Class::Abstract;
    use base qw(OOP::Perlish::Class::Abstract);

    BEGIN {
       __PACKAGE__->_interfaces(
           my_interface => 'required',
           my_optional_interface => 'optional',
           my_optional_but_true => 'optional_true',
       );
    };
}

{
    package OOP::Perlish::Class::Abstract::UnitTests::MyImplementationClass;
    use warnings;
    use strict;
    use base qw(OOP::Perlish::Class::Abstract::UnitTests::MyAbstractClass);

    sub my_interface
    {
       my ($self) = @_;

       return 'foo';
    }
}

{
    package OOP::Perlish::Class::Abstract::UnitTests::MyBogusImplementationClass;
    use warnings;
    use strict;
    use base qw(OOP::Perlish::Class::Abstract::UnitTests::MyAbstractClass);

    sub my_optional_interface
    {
        return 'foo';
    }
}

{
    package OOP::Perlish::Class::Abstract::UnitTests::MyConsumerClass;
    use warnings;
    use strict;
    use base qw(OOP::Perlish::Class);

    BEGIN {
       __PACKAGE__->_accessors(
           foo => {
               type => 'OBJECT',
               implements => [ 'OOP::Perlish::Class::Abstract::UnitTests::MyAbstractClass' ],
               required => 1,
           },
       );
    };

    sub quux
    {
       my ($self) = @_;

       return $self->foo()->my_interface();
    }
}

{
    package OOP::Perlish::Class::Abstract::UnitTests::Interfaces;
    use warnings;
    use strict;
    use base qw(Test::Class);
    use Test::More;

    sub implementation : Test
    {
        my ($self) = @_;

        my $foo = OOP::Perlish::Class::Abstract::UnitTests::MyImplementationClass->new();
        my $bar = OOP::Perlish::Class::Abstract::UnitTests::MyConsumerClass->new( foo => $foo );

        is( $bar->quux(), 'foo', 'we get see foo through all this' ) ;
    }

    sub negative_implementation : Test(2)
    {
        my ($self) = @_;

        my $foo = OOP::Perlish::Class->new();
        my $bar;
        eval { 
            $bar = OOP::Perlish::Class::Abstract::UnitTests::MyConsumerClass->new( foo => $foo );
        };

        ok( "$@", 'we died trying to set an invalid object' );
        ok( "$@" =~ m/Invalid required attribute for foo/, 'died for the right reasons' );
    }

    sub missing_required_interface : Test(2)
    {
        my ($self) = @_;

        eval {
            my $foo = OOP::Perlish::Class::Abstract::UnitTests::MyBogusImplementationClass->new();
        };

        ok( "$@", 'we die when a class is missing required interfaces' );
        ok( "$@" =~ m/Failed to define required interfaces: my_interface/, 'we died for the right reasons' );
    }

    sub required_method_die : Test(2)
    {
        my ($self) = @_;

        eval {
            OOP::Perlish::Class::Abstract::UnitTests::MyBogusImplementationClass->my_interface();
        };
        ok( "$@", 'we die when a class is missing required interfaces' );
        ok( "$@" =~ m/Interface my_interface is required, but was not defined/, 'we died for the right reasons' );
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
